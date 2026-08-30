#!/usr/bin/env python3
"""Drive the E-OS installer over the serial console for scripts/ci-install-smoke.sh.

Two modes:

  install <monitor-sock> <serial-sock> <budget-s> <logfile>
      log in, complete the R-602 first-boot password enrolment, run
      `sudo redox_installer_tui`, pick the blank target disk, and wait for the
      install to finish.

  verify <monitor-sock> <serial-sock> <budget-s> <logfile>
      boot whatever disk is attached and assert it reaches a login prompt.

Why serial and not the QEMU monitor's sendkey: serial input IS delivered to the guest
(U-161). The long-standing note claiming otherwise predates the R-F16 GIC fix, which had
been masking the UART's interrupt line. sendkey is still used for exactly one thing --
dismissing the bootloader's video-mode menu, which reads the emulated keyboard rather
than the serial line.
"""
import os
import re
import socket
import sys
import time

ESC = re.compile(r"\x1b\[[0-9;?]*[a-zA-Z]")
PASSWORD = "eos"


class Console:
    def __init__(self, serial_path, budget, logfile):
        self.buf = ""
        self.dead = False
        self.marker = 0
        self.deadline = time.time() + budget
        self.log = open(logfile, "w", encoding="utf-8")
        self.sock = None
        for _ in range(60):
            try:
                s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                s.connect(serial_path)
                self.sock = s
                break
            except OSError:
                time.sleep(1)
        if self.sock is None:
            raise SystemExit("install-smoke: could not attach to the serial socket")
        self.sock.settimeout(2)

    def pump(self, seconds=2):
        """Drain the serial socket for up to `seconds`.

        Returning early on a dead socket used to burn a core: expect() calls pump() in a
        loop with no delay of its own, so once the VM was gone this spun at 100% CPU until
        the deadline. With a 16200s budget that is four and a half hours of one core --
        measured, after four orphaned drivers were found still spinning, the oldest for
        1h50m, dragging every other run on the box down with them. `dead` lets the caller
        stop instead of waiting out a window that can no longer produce anything.
        """
        end = time.time() + seconds
        while time.time() < end:
            try:
                data = self.sock.recv(65536)
            except socket.timeout:
                continue          # settimeout(2) already paced us; no data yet
            except OSError:
                self.dead = True
                return
            if not data:          # EOF: qemu exited
                self.dead = True
                return
            text = ESC.sub("", data.decode("utf-8", "replace"))
            self.buf += text
            self.log.write(text)
            self.log.flush()

    def mark(self):
        """Freeze a point in the stream; expect() only looks at output after it."""
        self.marker = len(self.buf)

    def expect(self, pattern, what, window=None, optional=False):
        """Wait for `pattern` in output produced AFTER the last mark().

        Searching the whole accumulated buffer is the bug that made the first version of
        this harness useless: "the shell prompt came back" matched the prompt printed
        *before* the install started, so it returned instantly, the VM was killed
        mid-write, and stage 2 then found an unbootable disk. A check that cannot fail is
        not a check (CLAUDE.md 4.1).
        """
        rx = re.compile(pattern, re.I)
        limit = time.time() + window if window else self.deadline
        while time.time() < min(limit, self.deadline):
            self.pump(2)
            if self.dead:
                print("install-smoke: FAIL — the VM went away while waiting for %s" % what)
                return False
            if rx.search(self.buf[self.marker:]):
                print("install-smoke:   saw %s" % what)
                self.mark()
                return True
        # A check that cannot fail the run must not print FAIL. Two progress observations
        # here -- the ESP write and the install starting -- have their results discarded by
        # the caller, and printing FAIL for them taught the reader to skim past the word in
        # a log that PASSED. That is how a real failure gets missed.
        print("install-smoke: %s %s" % ("(not seen)" if optional else "FAIL — timed out waiting for", what))
        return False

    def expect_either(self, choices, what, window=None):
        """Wait for whichever of `choices` appears first; return its key, or None.

        Racing the outcomes matters once the happy path is long. Expecting FAILURE and
        only then success cost a full 180s window on every SUCCESSFUL run -- time taken
        straight out of the budget that the success itself needs. It also reads the
        wrong way round: the harness should ask "what happened", not "did it fail yet".
        """
        rx = {k: re.compile(v, re.I) for k, v in choices.items()}
        limit = time.time() + window if window else self.deadline
        while time.time() < min(limit, self.deadline):
            self.pump(2)
            if self.dead:
                print("install-smoke: FAIL — the VM went away while waiting for %s" % what)
                return None
            tail = self.buf[self.marker:]
            for key, r in rx.items():
                if r.search(tail):
                    print("install-smoke:   saw %s" % key)
                    self.mark()
                    return key
        print("install-smoke: FAIL — timed out waiting for %s" % what)
        return None

    def send(self, line):
        self.sock.sendall((line + "\n").encode())
        time.sleep(0.7)

    def dismiss_boot_menu(self, monitor_path, toggle_live=False):
        """The bootloader's video-mode menu reads the emulated KEYBOARD, not the serial
        line, so the keys that dismiss it have to go through the QEMU monitor.

        `toggle_live` presses `l` first. It TOGGLES; it does not enable. Measured from the
        menu text itself, which states the action available rather than the current state:
        booting the installer medium shows "Press l to disable live mode" (live is already ON),
        while harddrive.img shows "Press l to enable live mode" (live is OFF). Pressing `l`
        on the ISO therefore turns live mode OFF, and that run could not even log in --
        which is exactly what happened the first time I assumed the key would enable it.

        Live mode matters because it is what makes the bootloader load the filesystem into
        RAM and export DISK_LIVE_ADDR / DISK_LIVE_SIZE, the only two things that let
        redox_installer's try_fast_install() do a block copy instead of walking 13679 files.
        Note though that a live-mode ISO run STILL took the slow path here, so those
        variables are evidently not reaching the installer process -- unexplained, and not
        to be assumed fixed by booting live.
        """
        time.sleep(12)
        try:
            m = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            m.connect(monitor_path)
            time.sleep(0.3)
            if toggle_live:
                m.sendall(b"sendkey l\n")
                time.sleep(1.0)
            m.sendall(b"sendkey ret\n")
            time.sleep(0.5)
            m.close()
        except OSError:
            pass


def login(con):
    """Log in as root.

    Root and `sudo` behave IDENTICALLY here -- both reach "Installing to RedoxFS
    partition" and both fail with `Operation not permitted (os error 1)` (R-F19). An
    earlier note in this file claimed sudo was the problem; that was read off a run killed
    too early to see root fail the same way. Root is used anyway because it removes one
    variable from a flow that already has a blocker in it.
    """
    if not con.expect(r"login:", "the login prompt"):
        return False
    con.send("root")
    # Every password pattern below REQUIRES the colon. A bare "password" also matches the
    # login banner -- "Accounts: user * root - the first login makes you set a password" --
    # which is printed after the login: prompt, so it lands after the mark and looks like a
    # prompt to expect(). When that happened the driver typed "password" into the USERNAME
    # field and the run died with "Login incorrect", 25 lines before anything interesting.
    # Same class of defect as the whole-buffer expect() fixed in U-166: matching text that
    # is not a prompt. Being specific is the fix; a longer timeout would not have helped.
    if con.expect(r"password:", "the root password prompt", window=40):
        con.send("password")          # the shipped default the OOBE forces you off
    # R-602 forces a password change for any account still on the shipped default.
    if con.expect(r"new password:", "the first-boot password prompt", window=60):
        con.send(PASSWORD)
        time.sleep(1)
        if con.expect(r"password:", "the password confirmation", window=40):
            con.send(PASSWORD)
    return con.expect(r"root:.*#|:~#|\$", "a shell prompt", window=90)


def run_install(con):
    con.send("redox_installer_tui")

    if not con.expect(r"Select a drive from 1 to", "the installer's drive menu", window=120):
        return False

    # Report what the installer offered -- the point of the exercise. The boot disk is in
    # use and is not listed, so the blank target is the only entry.
    listing = con.buf[max(0, con.buf.rfind("Select a drive") - 800):con.buf.rfind("Select a drive")]
    for line in listing.split("\n"):
        if "/scheme/disk" in line:
            print("install-smoke:     offered: " + line.strip()[:90])

    con.send("1")

    # The redoxfs password prompt is INVISIBLE on the serial console: it is a password
    # prompt, so it echoes nothing, and waiting for it simply times out. An earlier
    # version of this driver appeared to work only because its expect() matched the
    # *stale* "[sudo] password" further up the buffer and sent the empty line by accident.
    # Send it deliberately instead. Empty means an unencrypted install.
    time.sleep(2)
    con.send("")

    # The installer's last observable step is writing the EFI loader; the shell prompt
    # comes back after that. Both are matched only in output produced after the drive was
    # chosen, so neither can be satisfied by something printed earlier in the session.
    if not con.expect(r"Opening disk", "the installer opening the target disk", window=90):
        return False

    # Order matters and mine was wrong at first: the ESP -- and therefore BOOTAA64.EFI --
    # is written BEFORE the RedoxFS partition, so expecting it afterwards produced a false
    # FAIL on a run that had got further than any before it.
    con.expect(r"BOOTAA64\.EFI|BOOTX64\.EFI", "the EFI bootloader being written", window=120, optional=True)
    # Two install paths print two different things, and expecting only the slow one made a
    # PASSING run print a FAIL line. The fast path (try_fast_install, block copy out of the
    # live disk in RAM) announces itself and then reports percentages; the slow path walks
    # files. Accept either, and say which was taken -- that is the interesting bit.
    con.expect(r"fast install: live disk at|Installing to RedoxFS partition",
               "the install starting (fast or file-by-file)", window=120, optional=True)

    # Race the two outcomes instead of waiting out a failure window first. Once the copy
    # phase genuinely runs it moves 13679 files, so the old "expect failure for 180s, then
    # expect success" spent three minutes of the budget on every healthy run.
    outcome = con.expect_either(
        {
            "the installer FAILING": r"failed to install",
            "the shell prompt returning after the install": r"root:.*#|:~#",
        },
        "the install to finish one way or the other",
        window=max(120, int(con.deadline - time.time())),
    )
    if outcome == "the installer FAILING":
        for line in [l for l in con.buf[-1500:].replace("\r", "\n").split("\n") if l.strip()][-6:]:
            print("install-smoke:     " + line[:100])
        print("install-smoke: FAIL — the installer reported an error")
        return False
    ok = outcome is not None
    if not ok:
        print("install-smoke: last serial output:")
        for line in [l for l in con.buf[-1200:].replace("\r", "\n").split("\n") if l.strip()][-15:]:
            print("install-smoke:     " + line[:100])
    return ok


def main():
    mode, monitor_path, serial_path, budget, logfile = sys.argv[1:6]
    con = Console(serial_path, int(budget), logfile)
    con.dismiss_boot_menu(monitor_path, toggle_live=os.environ.get("EOS_SMOKE_TOGGLE_LIVE") == "1")

    if mode == "verify":
        return 0 if con.expect(r"login:", "a login prompt on the installed disk") else 1

    if not login(con):
        return 1
    return 0 if run_install(con) else 1


if __name__ == "__main__":
    sys.exit(main())
