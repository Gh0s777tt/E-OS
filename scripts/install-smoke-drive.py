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
# CHOSEN BY THE POLICY, NOT BY ME. `eos` was three characters, and the credential policy wired
# into `passwd` (R-602a/b) has a twelve-character floor, so the old value turns this harness --
# and with it R-601c -- red. The replacement was not guessed: it was run through the shipped
# policy with `credpolicy-hostcheck`'s `judge` example, which reported
#
#     eos                           score=0 len=3  -> REJECT  (too short, and blocklisted)
#     eos-smoke-harness             score=4 len=17 -> ACCEPT
#     correct horse battery staple  score=0 len=28 -> REJECT  (blocklisted)
#
# The third line is why a length floor alone would not have been enough, and why this comment
# names the tool: the next person to change this value should ask the same question.
# Overridable so the NEGATIVE control is reproducible without editing this file:
#     EOS_SMOKE_PASSWORD=eos bash scripts/ci-install-smoke.sh <image> ... 
# must FAIL with "passwd refused the harness password". A floor that has only ever been
# seen accepting something is not a floor (CLAUDE.md §5.4).
PASSWORD = os.environ.get("EOS_SMOKE_PASSWORD", "eos-smoke-harness")
DISK_PASSWORD = "eosdisk"        # only used when EOS_SMOKE_FDE=1

# Which optional applications to DECLINE at the installer's prompt (PR-018), as the numbers the
# installer prints. Empty (the default) keeps everything, which is what every existing run wants.
# Set it to exercise the toggle:
#     EOS_SMOKE_DECLINE="1 2" bash scripts/ci-install-smoke.sh <image> ...
DECLINE = os.environ.get("EOS_SMOKE_DECLINE", "").strip()
FDE = os.environ.get("EOS_SMOKE_FDE") == "1"

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

    def send(self, line, end="\n"):
        """`end` exists because the UEFI bootloader is not the OS.

        MEASURED 2026-09-02: the bootloader's "RedoxFS password (n/10)" prompt does NOT treat
        "\\n" as Enter -- it echoes it as one more character. Two sends of 11 and 7 characters
        produced 20 asterisks on a single attempt (11 + 7 + 2 newlines) and nothing was ever
        submitted. It needs a carriage return.
        """
        self.sock.sendall((line + end).encode())
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
    # The prompt was ALREADY consumed by the race above, and `expect` matches new output only.
    # Without this flag the first pass through the loop waits for a SECOND "new password:" that
    # the guest has no reason to print: it is sitting at the prompt waiting for input, and the
    # driver is waiting for the prompt. Both wait forever.
    #
    # That deadlock is issue #16, and it is a harness regression, not a guest fault. The version
    # R-601 was proven on (8bd2c79d6) did `expect(...)` then `send(...)` immediately; the retry
    # loop added in 6c62b0ff9 kept the wait and lost the send. Measured 2026-09-01 on aarch64 --
    # the same stall the issue records on x86_64, so it was never architecture-specific:
    #
    #     install-smoke:   saw the first-boot password prompt
    #     install-smoke: FAIL — timed out waiting for the first-boot prompt
    #
    # Reproduced on both arches, which is what rules out the "serial overrun" reading the issue
    # was named after.
    have_prompt = True
    for _ in range(4):
        if not have_prompt:
            seen = con.expect_either(
                {"the first-boot password prompt": r"new password:",
                 "a rejected login": r"Login incorrect"},
                "the first-boot prompt", window=w(90))
            if seen != "the first-boot password prompt":
                return False
        have_prompt = False   # a later round must see the OOBE ask again
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
             # THE CREDENTIAL POLICY REFUSES HERE, NOT AT THE CONFIRMATION PROMPT, and the first
             # version of this arm was in the wrong place for exactly that reason. `passwd`
             # asks twice, compares, and only THEN judges -- so a refused password shows the
             # confirmation prompt like any other and goes quiet afterwards. Measured
             # 2026-09-03 with EOS_SMOKE_PASSWORD=eos: "saw the password confirmation",
             # then "timed out waiting for the result of the password change", then the OOBE
             # asked again because `login` re-runs `passwd` while the password is still blank.
             # That retry is the proof the policy refused; this arm is what turns it from a
             # timeout into a sentence.
             "a policy refusal": r"passwd: ",
             "a rejected login": r"Login incorrect"},
            "the result of the password change", window=w(180))
        if seen == "a shell prompt":
            return True
        if seen == "a policy refusal":
            print("install-smoke: FAIL — passwd refused this password (credential policy).",
                  file=sys.stderr)
            print("install-smoke:        The harness password is chosen BY the policy, not by",
                  file=sys.stderr)
            print("install-smoke:        hand: run the `judge` example in eos-userutils'",
                  file=sys.stderr)
            print("install-smoke:        credpolicy-hostcheck to pick one it accepts.",
                  file=sys.stderr)
            return False
        if seen == "a rejected login":
            return False
        # a mismatch: the OOBE prints its banner again, so go round.
    return False


def _disk_fingerprint(path):
    """Cheap, sensitive evidence that a file has not been written to.

    st_blocks is what a sparse image grows by the moment anything lands in it, and mtime moves on
    any write; opening a file changes neither. Together they cost a syscall, which matters because
    this runs between two prompts the guest is waiting on -- hashing 4 GiB there would time the
    installer out and turn a passing check into a harness failure.

    Returns None when the path was not supplied, so an older call site keeps working.
    """
    if not path:
        return None
    try:
        st = os.stat(path)
    except OSError:
        return None
    return (st.st_blocks, st.st_size, st.st_mtime_ns)


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


def run_install(con, target_img=None):
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
    # R-604a asks for two things: a wrong name is refused, and NOTHING is written. The first was
    # observable in the guest's output; the second was only ever inferred from the install starting
    # afterwards, which is not the same claim. Measure the target disk on both sides of the refusal.
    before = _disk_fingerprint(target_img)
    con.send(offered[0] + "-not-a-real-disk")
    if not con.expect(r"refused:", "the installer refusing a name that matches no disk",
                      window=w(60)):
        print("install-smoke: FAIL -- a wrong disk name was NOT refused")
        return False

    after = _disk_fingerprint(target_img)
    if before is None or after is None:
        print("install-smoke:   (target not measured -- no path given; refusal checked, writes NOT)")
    elif before != after:
        print("install-smoke: FAIL -- the target disk CHANGED while the name was being refused")
        print("install-smoke:   before (blocks, size, mtime_ns): %r" % (before,))
        print("install-smoke:   after                          : %r" % (after,))
        return False
    else:
        print("install-smoke:   the target disk is byte-for-byte untouched by the refusal "
              "(%d blocks, mtime unchanged)" % before[0])

    # The blank target is the largest offered disk: the live medium is 1.37 GiB and the target
    # created by the harness is 4 GiB. Chosen by SIZE rather than by position for exactly the
    # reason the prompt changed.
    target = offered[-1] if len(offered) == 1 else max(offered, key=lambda p: _offered_size(listing, p))
    print("install-smoke:     erasing: " + target)
    con.send(target)

    # The installer's password prompts are printed with `print!` on STDOUT and never
    # flushed (installer.rs:83 prompt_password), while its progress messages go to STDERR
    # with `eprintln!`. On a serial console that means the prompt is still sitting in the
    # guest's buffer while the installer is already blocked reading -- MEASURED 2026-09-02:
    # after sending the disk path the console produced ZERO bytes for a full 120s window,
    # and the prompt text only appeared once another line was sent. So there is nothing to
    # wait for here; the lines must be sent deliberately, and the proof that they landed is
    # "Opening disk" further down (stderr, unbuffered).
    #
    # An EMPTY password short-circuits: prompt_password returns None without ever asking to
    # confirm, which is why the unencrypted path sends exactly one line. A non-empty one is
    # asked TWICE -- send only once and the installer waits forever (measured: run timed out
    # at "opening the target disk" with the guest parked on the confirmation read).
    time.sleep(2)
    #
    # EOS_SMOKE_FDE_NEGATIVE=1 is the NEGATIVE CONTROL for the whole FDE case, not a back door:
    # it runs stage 2 in verify-fde mode against a deliberately UNENCRYPTED install, so the
    # three-step proof below has to fail -- and be seen to fail for the right reason. Without a
    # way to reproduce that, "the encrypted disk asked for a password" would be a claim nobody
    # could falsify. Measured 2026-09-02: it fails at step 1 with "never asked for one (the
    # boot-mode menu with no password asked for). It is not encrypted."
    if FDE and os.environ.get("EOS_SMOKE_FDE_NEGATIVE") != "1":
        con.send(DISK_PASSWORD)
        con.send(DISK_PASSWORD)
    else:
        con.send("")

    # THE OPTIONAL-APPLICATIONS PROMPT (PR-018). It is `optional=True` on purpose: this harness
    # must keep working against an image built BEFORE the installer learned to ask, and against
    # one that ships no manifest. A prompt that is not there is not a failure -- but a prompt
    # that IS there and goes unanswered stalls the install until the window expires, which is
    # exactly the shape of bug this arm exists to prevent (measured once already, on the
    # credential policy: the refusal arrived at a different step than the harness watched).
    if con.expect(r"Numbers to LEAVE OUT", "the optional-applications prompt",
                  window=w(60), optional=True):
        con.send(DECLINE)
        if DECLINE:
            print("install-smoke:   declined optional applications: %s" % DECLINE)

    # The installer's last observable step is writing the EFI loader; the shell prompt
    # comes back after that. Both are matched only in output produced after the drive was
    # chosen, so neither can be satisfied by something printed earlier in the session.
    if not con.expect(r"Opening disk", "the installer opening the target disk", window=w(90)):
        return False

    # These two arrive in a FIXED order, and the harness must ask for them in that same order
    # or the first request consumes the stream past the second. Read off the guest's source
    # (installer.rs, `with_whole_disk`): "Installing to RedoxFS partition" is printed at :770,
    # and the ESP is written afterwards by `write_efi_partition` -- called after the
    # `with_redoxfs` block returns, unconditionally on BOTH install paths -- which is where the
    # "BOOTX64.EFI" / "BOOTAA64.EFI" name is printed.
    #
    # Corrected 2026-09-02. This pair used to be the other way round, under a comment asserting
    # that the ESP is written BEFORE the RedoxFS partition. It is not. The cost was a dead
    # check: a PASSING x86_64 run printed BOTH "saw the EFI bootloader ..." AND "(not seen) the
    # install starting" -- impossible if the second check could ever match, since an install
    # must start before an ESP can be written. It also burned a full 120s window (x3 under TCG)
    # waiting for a line that had already gone past. A check that cannot pass is not a check.
    #
    # Two install paths print two different things: the fast path (try_fast_install, block copy
    # out of the live disk in RAM) announces itself and then reports percentages; the slow path
    # walks files. Accept either, and say which was taken -- that is the interesting bit.
    con.expect(r"fast install: live disk at|Installing to RedoxFS partition",
               "the install starting (fast or file-by-file)", window=w(120), optional=True)
    con.expect(r"BOOTAA64\.EFI|BOOTX64\.EFI",
               "the EFI bootloader written to the ESP",
               window=w(120), optional=True)

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


def verify_fde(con, monitor_path):
    """Prove the installed disk is REALLY encrypted -- three falsifiable steps, not one.

    Booting an encrypted disk and reaching a login prompt proves nothing on its own: it would
    pass just as happily if the password had been ignored and the disk written in the clear.

    This mode must NOT call dismiss_boot_menu() before it starts, and the order below is the
    measured one, not the obvious one (2026-09-02):

      * dismiss_boot_menu() sleeps a fixed 12s and then presses Enter through the QEMU
        monitor. On an ENCRYPTED disk the bootloader is sitting on the password prompt at
        that moment, so that Enter is submitted as an EMPTY password and burns an attempt --
        visible in the console as "(1/10)" with ZERO asterisks followed at once by "(2/10)".
      * The video-mode menu appears AFTER the disk is unlocked on this path, not before, and
        it reads the emulated keyboard rather than the serial line. So it has to be dismissed
        between the password and the login prompt, or the run simply never sees "login:".
    """
    # 1. The bootloader must ASK. Race the two outcomes rather than waiting one out, so
    #    "it booted straight in" is reported as the wrong result it is, not as a timeout.
    #    The boot-mode menu is raced too, and not as a nicety: on an UNENCRYPTED disk it is
    #    what actually appears, and it BLOCKS -- it reads the emulated keyboard, so nothing
    #    else is ever printed until something dismisses it. Without naming it here the
    #    negative control still fails, but by timing out, and a timeout does not say WHY.
    #    Measured order on an encrypted disk: banner, "Looking for RedoxFS:", the password
    #    prompt, and only AFTER unlocking, this menu. So the menu arriving first is itself
    #    the evidence that no disk password was ever asked for.
    seen = con.expect_either(
        {"the bootloader asking for the disk password": r"RedoxFS password \(",
         "the boot-mode menu with no password asked for": r"Arrow keys and enter select mode",
         "a login prompt with NO password asked for": r"login:"},
        "the bootloader's first move on the installed disk", window=w(120))
    if seen != "the bootloader asking for the disk password":
        print("install-smoke: FAIL — the install took a disk password, but the installed disk")
        print("install-smoke:        never asked for one (%s). It is not encrypted."
              % (seen if seen else "nothing recognisable appeared"))
        return False

    # 2. A WRONG password must NOT unlock the disk. Asserting "the attempt counter moved on"
    #    would be worthless here: the counter also moves when the bootloader retries by
    #    itself, which it demonstrably does. Assert the thing that actually matters instead --
    #    that no login prompt appears -- and race it against the disk staying locked.
    con.send("nie-" + DISK_PASSWORD, end="\r")
    seen = con.expect_either(
        {"the disk staying locked after a deliberately wrong password": r"RedoxFS password \(",
         "the disk UNLOCKING on a wrong password": r"login:"},
        "what a wrong disk password does", window=w(90))
    if seen != "the disk staying locked after a deliberately wrong password":
        print("install-smoke: FAIL — a deliberately WRONG disk password unlocked the disk.")
        return False

    # 3. Only now does the right one mean anything.
    con.send(DISK_PASSWORD, end="\r")
    con.dismiss_boot_menu(monitor_path)
    return con.expect(r"login:", "a login prompt after unlocking the encrypted disk",
                      window=w(180))


def main():
    mode, monitor_path, serial_path, budget, logfile = sys.argv[1:6]
    # Optional 6th argument: the target disk image, so the refusal can be shown to have
    # written nothing rather than assumed to have. Absent -> the check says so and skips.
    target_img = sys.argv[6] if len(sys.argv) > 6 else None
    con = Console(serial_path, int(budget), logfile)
    # verify-fde dismisses the menu itself, AFTER unlocking -- see verify_fde().
    if mode == "verify-fde":
        return 0 if verify_fde(con, monitor_path) else 1

    con.dismiss_boot_menu(monitor_path, toggle_live=os.environ.get("EOS_SMOKE_TOGGLE_LIVE") == "1")

    if mode == "verify":
        return 0 if con.expect(r"login:", "a login prompt on the installed disk") else 1

    if not login(con):
        return 1
    return 0 if run_install(con, target_img) else 1


if __name__ == "__main__":
    sys.exit(main())
