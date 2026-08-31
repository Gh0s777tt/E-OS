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

# One knob for "this guest is slower than the one these windows were measured on", instead
# of editing eleven constants by hand and having them drift apart. MEASURED on x86_64 under
# TCG on an Apple Silicon host: the same flow that passes first time on aarch64 needed THREE
# login attempts, because attempts 1 and 2 timed out at the shell prompt and the password
# confirmation before the guest had warmed up. Multiplying is honest -- the steps are the
# same, the machine is slower -- whereas raising each constant for everyone would slow the
# failure path down on the arch where these numbers were correct.
SLOW = float(os.environ.get("EOS_SMOKE_SLOW", "1"))


def w(seconds):
    """Scale a measured window for a slower guest (EOS_SMOKE_SLOW)."""
    return int(seconds * SLOW)


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

    def mark(self, pos=None):
        """Freeze a point in the stream; expect() only looks at output after it.

        `pos` defaults to the END of everything received so far, and that default is a trap
        on a match: one recv() can carry the matched text AND whatever the guest printed
        next, so marking at len(buf) silently discards output that has already arrived.
        MEASURED: after a rejected login the guest prints "Login incorrect" and its next
        `eos login:` in the same chunk, so the retry waited forever for a prompt that was
        sitting in the buffer, three lines above the marker. expect() therefore marks at the
        end of its MATCH, not at the end of the stream.
        """
        self.marker = len(self.buf) if pos is None else pos

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
            m = rx.search(self.buf[self.marker:])
            if m:
                print("install-smoke:   saw %s" % what)
                self.mark(self.marker + m.end())
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
                m = r.search(tail)
                if m:
                    print("install-smoke:   saw %s" % key)
                    self.mark(self.marker + m.end())
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


def login(con, attempts=3):
    """Log in as root, tolerating a first attempt eaten by console re-initialisation.

    Root and `sudo` behave IDENTICALLY here -- both reach "Installing to RedoxFS
    partition" and both fail with `Operation not permitted (os error 1)` (R-F19). Root is
    used anyway because it removes one variable from a flow that already has a blocker.

    WHY THE RETRY, measured twice on x86_64 under TCG: the getty prints its banner and
    prompt, then RE-PRINTS both, and a login started before the reprint is discarded. The
    password then lands at the USERNAME prompt -- visible in the serial log because it is
    echoed IN THE CLEAR, `eos login: p`, `eos login: pa`, ... -- and the run dies on
    "Login incorrect" with the real cause 25 lines earlier.

    Waiting for the console to go quiet before typing was tried, and made it WORSE: the
    login prompt has its own timeout, so settling past it produced the same clear-text
    echo one step SOONER, failing at the OOBE prompt the previous run had reached. That
    experiment is why this is a retry and not a delay -- predicting the guest is the wrong
    move, tolerating it is the right one.
    """
    for attempt in range(1, attempts + 1):
        if _login_once(con):
            return True
        if con.dead:
            return False
        if attempt < attempts:
            # Deliberately NO mark() here. expect_either() already marked immediately after
            # "Login incorrect", and the getty prints its next `eos login:` AFTER that -- so
            # marking again skips the very prompt the retry is waiting for. Measured: the
            # first version of this retry did exactly that and hung with the guest sitting
            # at a visible prompt the driver could no longer see. Same class as the
            # whole-buffer expect() this file already carries a scar for (U-166): the marker
            # decides what you are allowed to notice, so moving it is never cosmetic.
            print("install-smoke:   login attempt %d did not take, retrying" % attempt)
    return False


def _login_once(con):
    if not con.expect(r"login:", "the login prompt"):
        return False
    con.send("root")
    # Every password pattern below REQUIRES the colon. A bare "password" also matches the
    # login banner -- "Accounts: user * root - the first login makes you set a password" --
    # which is printed after the login: prompt, so it lands after the mark and looks like a
    # prompt to expect(). Being specific is the fix; a longer timeout would not have helped.
    if not con.expect(r"password:", "the root password prompt", window=w(40)):
        return False
    con.send("password")              # the shipped default the OOBE forces you off

    # Race the outcomes instead of waiting out the happy path's window on a login that has
    # ALREADY been refused. "Login incorrect" is a RESULT, not a timeout, and telling the
    # two apart is what lets this retry instead of reporting a timeout for a rejection
    # (CLAUDE.md 13, U-177: red must say WHAT is broken -- the tree or the instrument).
    seen = con.expect_either(
        {"the first-boot password prompt": r"new password:",
         "a rejected login": r"Login incorrect"},
        "the login outcome", window=w(90))
    if seen != "the first-boot password prompt":
        return False

    # R-602 forces a password change for any account still on the shipped default, and the
    # OOBE is driven in a LOOP rather than once, because it can legitimately have to ask
    # twice. MEASURED on x86_64 under TCG:
    #
    #     new password:
    #     confirm password:
    #     passwd: new password does not match confirm password
    #
    # -- the two prompts printed back to back with nothing typed between them, so the first
    # read returned an EMPTY line. There is a stray newline in the guest's input queue after
    # the login password, the OOBE eats it as the new password, then eats our real one as the
    # confirmation, and the pair does not match. The OOBE re-asks; the driver has to be able
    # to answer the second round instead of treating the first mismatch as fatal.
    #
    # Every step below races its outcomes instead of waiting out a window. Waiting cost 540 s
    # per failed attempt on a run that had already printed the reason in one line -- and a
    # timeout reported for a result the guest already told us is the "red that does not say
    # what is broken" this project bans (CLAUDE.md 13, U-177).
    for _ in range(4):
        seen = con.expect_either(
            {"the first-boot password prompt": r"new password:",
             "a rejected login": r"Login incorrect"},
            "the first-boot prompt", window=w(90))
        if seen != "the first-boot password prompt":
            return False
        con.send(PASSWORD)

        seen = con.expect_either(
            {"the password confirmation": r"confirm password:",
             "a password mismatch": r"does not match",
             "a rejected login": r"Login incorrect"},
            "the confirmation prompt", window=w(60))
        if seen == "a rejected login":
            return False
        if seen != "the password confirmation":
            continue                      # mismatch or nothing: let the OOBE ask again
        con.send(PASSWORD)

        seen = con.expect_either(
            {"a shell prompt": r"root:.*#|:~#|\$",
             "a password mismatch": r"does not match",
             "a rejected login": r"Login incorrect"},
            "the result of the password change", window=w(180))
        if seen == "a shell prompt":
            return True
        if seen == "a rejected login":
            return False
        # a mismatch: the OOBE prints its banner again, so go round.
    return False


def _offered_size(listing, path):
    """Bytes for `path` as the installer printed them, or 0 when it did not say.

    Parsed from the block the installer just wrote rather than from a `stat` on the host: the
    number the OPERATOR sees is the number the choice must be made on, and if those two ever
    disagree it is the printed one that misleads a person.
    """
    m = re.search(re.escape(path) + r"(.{0,200}?)size:\s*([0-9.]+)\s*([KMGT]?)i?B", listing, re.S)
    if not m:
        return 0
    mult = {"": 1, "K": 1 << 10, "M": 1 << 20, "G": 1 << 30, "T": 1 << 40}[m.group(3)]
    try:
        return float(m.group(2)) * mult
    except ValueError:
        return 0


def run_install(con):
    con.send("redox_installer_tui")

    # R-604a changed this prompt deliberately: the installer no longer takes a NUMBER, because
    # the number is a position in a list ordered by PCI enumeration, and that order was measured
    # changing between runs (the same 4 GB disk appeared at 00-05.0 and at 00-06.0). It now
    # requires the operator to retype the device path. This driver has to do the same thing a
    # person would -- read what is offered, then name it.
    if not con.expect(r"Disk to erase:", "the installer's disk prompt", window=w(120)):
        return False

    listing = con.buf[max(0, con.buf.rfind("Disks found:")):]
    offered = []
    for line in listing.split("\n"):
        line = line.strip()
        m = re.search(r"(/scheme/disk[^\s:]+)", line)
        if m and m.group(1) not in offered:
            offered.append(m.group(1))
    for path in offered:
        print("install-smoke:     offered: " + path[:90])
    if not offered:
        print("install-smoke: FAIL -- the disk prompt appeared but no device path was listed")
        return False

    # NEGATIVE CONTROL, and it is part of the test rather than decoration: type a path that
    # does NOT name any offered disk and require the installer to refuse. If this ever stops
    # printing "refused", the confirmation has become decorative and the next wrong answer
    # erases a disk. A wrong name must cost nothing, so this runs before the real one.
    con.send(offered[0] + "-not-a-real-disk")
    if not con.expect(r"refused:", "the installer refusing a name that matches no disk",
                      window=w(60)):
        print("install-smoke: FAIL -- a wrong disk name was NOT refused")
        return False

    # The blank target is the largest offered disk: the live medium is 1.37 GiB and the target
    # created by the harness is 4 GiB. Chosen by SIZE rather than by position for exactly the
    # reason the prompt changed.
    target = offered[-1] if len(offered) == 1 else max(offered, key=lambda p: _offered_size(listing, p))
    print("install-smoke:     erasing: " + target)
    con.send(target)

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
    if not con.expect(r"Opening disk", "the installer opening the target disk", window=w(90)):
        return False

    # Order matters and mine was wrong at first: the ESP -- and therefore BOOTAA64.EFI --
    # is written BEFORE the RedoxFS partition, so expecting it afterwards produced a false
    # FAIL on a run that had got further than any before it.
    con.expect(r"BOOTAA64\.EFI|BOOTX64\.EFI", "the EFI bootloader being written", window=w(120), optional=True)
    # Two install paths print two different things, and expecting only the slow one made a
    # PASSING run print a FAIL line. The fast path (try_fast_install, block copy out of the
    # live disk in RAM) announces itself and then reports percentages; the slow path walks
    # files. Accept either, and say which was taken -- that is the interesting bit.
    con.expect(r"fast install: live disk at|Installing to RedoxFS partition",
               "the install starting (fast or file-by-file)", window=w(120), optional=True)

    # Race the two outcomes instead of waiting out a failure window first. Once the copy
    # phase genuinely runs it moves 13679 files, so the old "expect failure for 180s, then
    # expect success" spent three minutes of the budget on every healthy run.
    outcome = con.expect_either(
        {
            "the installer FAILING": r"failed to install",
            "the shell prompt returning after the install": r"root:.*#|:~#",
        },
        "the install to finish one way or the other",
        window=max(w(120), int(con.deadline - time.time())),
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
