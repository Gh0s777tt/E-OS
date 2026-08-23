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
import re
import socket
import sys
import time

ESC = re.compile(r"\x1b\[[0-9;?]*[a-zA-Z]")
PASSWORD = "eos"


class Console:
    def __init__(self, serial_path, budget, logfile):
        self.buf = ""
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
        end = time.time() + seconds
        while time.time() < end:
            try:
                data = self.sock.recv(65536)
            except (socket.timeout, OSError):
                return
            if not data:
                return
            text = ESC.sub("", data.decode("utf-8", "replace"))
            self.buf += text
            self.log.write(text)
            self.log.flush()

    def mark(self):
        """Freeze a point in the stream; expect() only looks at output after it."""
        self.marker = len(self.buf)

    def expect(self, pattern, what, window=None):
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
            if rx.search(self.buf[self.marker:]):
                print("install-smoke:   saw %s" % what)
                self.mark()
                return True
        print("install-smoke: FAIL — timed out waiting for %s" % what)
        return False

    def send(self, line):
        self.sock.sendall((line + "\n").encode())
        time.sleep(0.7)

    def dismiss_boot_menu(self, monitor_path):
        """The bootloader's video-mode menu reads the emulated KEYBOARD, not the serial
        line, so the Enter that dismisses it has to go through the QEMU monitor."""
        time.sleep(12)
        try:
            m = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            m.connect(monitor_path)
            time.sleep(0.3)
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
    if con.expect(r"password", "the root password prompt", window=40):
        con.send("password")          # the shipped default the OOBE forces you off
    # R-602 forces a password change for any account still on the shipped default.
    if con.expect(r"new password", "the first-boot password prompt", window=60):
        con.send(PASSWORD)
        time.sleep(1)
        if con.expect(r"password", "the password confirmation", window=40):
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

    # R-F19: the run dies here, so surface the reason rather than letting the caller see a
    # bare timeout on the next expectation.
    if con.expect(r"failed to install", "the installer FAILING", window=180):
        for line in [l for l in con.buf[-1500:].replace("\r", "\n").split("\n") if l.strip()][-6:]:
            print("install-smoke:     " + line[:100])
        print("install-smoke: FAIL — the installer reported an error (R-F19)")
        return False
    con.expect(r"BOOTAA64\.EFI|BOOTX64\.EFI", "the EFI bootloader being written",
               window=max(120, int(con.deadline - time.time()) // 2))
    ok = con.expect(r"root:.*#|:~#", "the shell prompt returning after the install",
                    window=max(60, int(con.deadline - time.time())))
    if not ok:
        print("install-smoke: last serial output:")
        for line in [l for l in con.buf[-1200:].replace("\r", "\n").split("\n") if l.strip()][-15:]:
            print("install-smoke:     " + line[:100])
    return ok


def main():
    mode, monitor_path, serial_path, budget, logfile = sys.argv[1:6]
    con = Console(serial_path, int(budget), logfile)
    con.dismiss_boot_menu(monitor_path)

    if mode == "verify":
        return 0 if con.expect(r"login:", "a login prompt on the installed disk") else 1

    if not login(con):
        return 1
    return 0 if run_install(con) else 1


if __name__ == "__main__":
    sys.exit(main())
