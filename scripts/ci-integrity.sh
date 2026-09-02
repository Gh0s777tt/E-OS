#!/usr/bin/env bash
# E-OS integrity gates — fast, dependency-free invariants that replace part of the
# (dead) GitHub Actions checks. Runs in GitLab CI and the local pre-push hook.
set -uo pipefail
# `|| exit 1`: this is a GATE. A failed cd used to leave it linting whatever directory it
# happened to be in and reporting PASS on the wrong tree.
cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")" || exit 1
fail=0
ok(){ printf '  ok: %s\n' "$1"; }
bad(){ printf 'FAIL: %s\n' "$1"; fail=1; }
# `cannot` is for the OTHER kind of red: the check could not be RUN, so the invariant is
# unjudged. Keeping it apart from `bad` is the whole point of U-177 — see the preflight
# below and checks 6 and 7. A reader must never have to guess which of the two a red line
# means, because the two demand opposite responses: fix the tree, or fix the runner.
cannot(){ printf 'FAIL (instrument): %s\n' "$1"; fail=1; }

# ── 0. Instruments before results — prove the gate can measure at all (CLAUDE.md §4.2) ──
# Every check below shells out, and a missing tool has already made this file lie twice
# over, in both directions:
#   * MISLEADING RED — check 7 read ANY non-zero exit from `python3` as "the repo types
#     disagree". In CI job 16155620600 (pipeline #200) the alpine:3 image simply had no
#     python3; the gate reported a type mismatch that did not exist. Package fixed in
#     U-175, diagnostic in U-177.
#   * FALSE GREEN, which is worse — checks 1, 4 and 5 pipe `git grep ... || true` into an
#     is-it-empty test. Without git, or outside a work tree, the output is empty for the
#     wrong reason and the gate prints `ok:` for an invariant nobody measured. That is
#     `U-140`'s `|| true` lesson wearing a different coat: a check that cannot go red
#     does not exist.
# Hence: the tools shared by several checks are probed ONCE, up front, and their absence
# ABORTS instead of degrading. Per-check instruments (python3, the two helper scripts)
# are probed inside their own check, so the remaining seven still get measured — that is
# also what U-175 measured: python3 is required by exactly one check.
missing=""
for t in git grep awk; do command -v "$t" >/dev/null 2>&1 || missing="$missing $t"; done
if [ -n "$missing" ]; then
  printf 'FAIL (instrument): integrity gate cannot run — not on PATH:%s\n' "$missing"
  printf '      Nothing was measured. This is NOT an invariant violation.\n'
  echo "integrity: FAIL"; exit 1
fi
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'FAIL (instrument): not inside a git work tree: %s\n' "$PWD"
  printf '      `git grep` finds nothing here, so checks 1, 4 and 5 would print ok: for\n'
  printf '      invariants nobody measured. Nothing was measured. NOT an invariant violation.\n'
  echo "integrity: FAIL"; exit 1
fi

# 1) No debug / plaintext-secret prints in our own Rust sources (R-F01 guard).
# `git grep` (tracked files only) rather than `grep -r .`: the recursive form also
# walked the gitignored prefix/ — 15 GB of vendored upstream Rust stdlib — and
# build/, so any working tree that had ever been built failed this gate on
# upstream doc-examples containing the word "password", while CI passed because a
# fresh clone has neither directory. The gate's own comment says "our own"
# sources, and tracked == ours (fork sources land in the gitignored
# recipes/*/source and are gated by their own repos' CI). This makes a local run
# mean exactly what the CI run means, and it is far faster over a 24 GB tree.
hits=$(git grep -InE 'println!\s*\(.*[Pp]assword|TODO:? *Remove this debug' -- '*.rs' 2>/dev/null || true)
if [ -n "$hits" ]; then bad "debug/plaintext-secret print:"; echo "$hits"; else ok "no debug/password prints"; fi

# 2) Docs must not point users at a concrete phantom release image (R-003 guard).
# Checks 2 and 3 read files instead of shelling out to git, so the preflight above does not
# cover them: `grep -r` over a docs/ that is not there errors to /dev/null and leaves $hits
# empty, which reads exactly like "no phantom refs". Same split as checks 6 and 7 (U-177) —
# the thing being searched has to exist before "found nothing" means anything.
if [ ! -d docs ] || [ ! -f README.md ]; then
  cannot "check 2 could not run: docs/ or README.md is missing — nothing was searched"
else
  hits=$(grep -rInE 'eos-[0-9]+\.[0-9]+\.[0-9]+-(x86_64|aarch64)\.img' docs/ README.md 2>/dev/null || true)
  if [ -n "$hits" ]; then bad "docs reference a concrete eos-<ver>-<arch>.img (use the build/ path or make-release):"; echo "$hits"; else ok "no phantom-artifact doc refs"; fi
fi

# 3) README carries the SYNC marker kept in step with CHANGELOG/ROADMAP.
if [ ! -f README.md ]; then
  cannot "check 3 could not run: README.md is missing — the marker is UNKNOWN, not proven absent"
elif grep -q 'SYNC:' README.md; then
  ok "README SYNC marker present"
else
  bad "README SYNC marker missing"
fi

# 4) Every `unsafe` in E-OS-owned Rust carries a `SAFETY:` note (R-F01 sibling).
# Scope excludes src/: that is the VENDORED redox_cookbook (package name
# `redox_cookbook`, upstream author), and all nine of its unsafe blocks live in
# src/cook/pty.rs. Annotating upstream code would create divergence to re-apply on
# every sync, for no safety gain — the same reasoning that keeps third-party ports
# on upstream flags (CLAUDE.md 3). E-OS-owned Rust here has ZERO unsafe today, so
# this gate is introduced while the count is nil and can never accrue a backlog.
# The forks (kernel/base/relibc) carry the real unsafe and are gated by their own CI.
hits=$(git grep -nI 'unsafe' -- '*.rs' ':!src/' 2>/dev/null | while IFS=: read -r f l _; do
  # A SAFETY: note must sit on one of the three lines above the unsafe.
  awk -v n="$l" 'NR>=n-3 && NR<n' "$f" 2>/dev/null | grep -q 'SAFETY' || echo "$f:$l"
done)
if [ -n "$hits" ]; then
  bad "unsafe without a SAFETY: note (state the invariant that makes it sound):"; echo "$hits"
else ok "every unsafe in E-OS-owned Rust is justified"; fi

# 5) No bash-4-only syntax in E-OS-owned scripts (R-F14).
# The dev host ships /bin/bash 3.2 (CLAUDE.md 9), so `declare -A`, `${x^^}`, `${x,,}`,
# `mapfile` and `readarray` parse in CI and fail on the machine the work is done on. This
# has cost time twice already: scripts/eos-check.sh used ${ARCH^^} (fixed in U-124) and
# scripts/check-ci-config.sh used `declare -A` (fixed in U-159). Comment lines are ignored
# so the notes explaining those very fixes do not trip their own gate. Scope is scripts/:
# build.sh and the *_bootstrap.sh at the repo root are inherited upstream, and upstream/
# targets machines with bash 4 -- the same reasoning that keeps check 4 out of src/.
# This file excludes itself: it necessarily contains the very patterns it looks for, so
# in scope it matched its own regex literal and failed on a clean tree. Its own syntax is
# covered by `bash -n` and by the shell-lint job.
hits=$(git grep -nE 'declare -A|mapfile|readarray|\$\{[A-Za-z_][A-Za-z0-9_]*\^\^|\$\{[A-Za-z_][A-Za-z0-9_]*,,|(sed|grep)[^|]*[\\][sSdwW]' -- 'scripts/*.sh' ':!scripts/ci-integrity.sh' 2>/dev/null \
  | awk -F: '{ line=$0; sub(/^[^:]*:[0-9]*:/, "", line); if (line !~ /^[[:space:]]*#/) print }')
if [ -n "$hits" ]; then
  bad "non-portable shell in scripts/ (dev host: bash 3.2 + BSD sed/grep):"; echo "$hits"
else ok "no bash-4-only syntax or GNU-only regex in E-OS scripts"; fi

# 6) Every E-OS-forked recipe is pinned to build from its fork (R-F20).
# .config sets REPO_BINARY=1, which makes cookbook DOWNLOAD <recipe>.pkgar from
# static.redox-os.org unless cookbook.lock carries an fsrule = "source" exception. Those
# exceptions were hand-maintained and rotted: 13 of 26 forked recipes had been missed, so
# pkg-lib's manifest-signature verification -- R-703's client half -- was absent from the
# image while every document called it implemented (U-164). cookbook.lock is tracked as of
# U-168 precisely so this is reviewable, and eos-source-rules.sh derives the expected set
# from the tree rather than restating it.
# The same instrument/invariant split as check 7 (U-177), and needed for the same reason:
# eos-source-rules.sh exits 1 both when recipes really are unpinned AND when it never got
# to look (no recipes/ here, no E-OS fork found at all, `repo change-rule` missing). The
# exit code cannot tell those apart — but the script already prints a verdict LINE for
# each of its two real answers, and only the comparison itself can print one.
if [ -f cookbook.lock ]; then
  if [ ! -f scripts/eos-source-rules.sh ]; then
    cannot "check 6 could not run: scripts/eos-source-rules.sh is missing"
  else
    out=$(bash scripts/eos-source-rules.sh 2>&1); rc=$?
    case "$rc:$out" in
      0:*"source-rules: OK"*)
        ok "every E-OS-forked recipe builds from its fork" ;;
      1:*"NOT pinned to source:"*)
        bad "recipes with an E-OS fork are not pinned to source (they would be downloaded):"
        echo "$out" ;;
      *)
        cannot "check 6 reached no verdict: scripts/eos-source-rules.sh exited $rc without an OK/NOT-pinned line — the fork pinning is UNKNOWN, not proven bad:"
        echo "$out" ;;
    esac
  fi
else
  bad "cookbook.lock is missing — the build would silently download upstream binaries"
fi

# ── 7. Repo types in CLAUDE.md §11 match the `type` field in repos.toml ──────
# The type decides the rules (mirror = read-only, fork = must stay rebaseable), so a
# document disagreeing with the manifest silently applies the wrong ones. Offline half;
# the network half is scripts/eos-mirror-drift.sh, which compares the type to the fork.
# Instrument first, verdict second (U-177). This check used to read EVERY non-zero exit
# from python3 as "the types disagree" — including 127, i.e. no python3 at all, which is
# exactly what CI job 16155620600 hit and reported as a mismatch that did not exist.
# Probing `command -v` alone would not be enough either: a python3 that exists but is not
# python 3 dies on the checker's f-strings with SyntaxError and exit **1**, the same code
# a real mismatch uses. So the checker states an explicit contract (see its docstring) and
# prints a verdict LINE that only the comparison itself can produce:
#   0 + `repo-types: OK`        compared, equal            -> green
#   1 + `repo-types: MISMATCH`  compared, different        -> the invariant is broken
#   anything else               never got to compare       -> the instrument is broken
py=scripts/eos-check-repo-types.py
if ! command -v python3 >/dev/null 2>&1; then
  cannot "check 7 could not run: python3 is not on PATH (it runs $py) — the repo types are UNKNOWN, not proven wrong"
elif [ ! -f "$py" ]; then
  cannot "check 7 could not run: $py is missing — the repo types are UNKNOWN, not proven wrong"
else
  out=$(python3 "$py" 2>&1); rc=$?
  case "$rc:$out" in
    0:*"repo-types: OK"*)
      ok "CLAUDE.md repo types match repos.toml" ;;
    1:*"repo-types: MISMATCH"*)
      bad "CLAUDE.md §11 and repos.toml disagree on repository types:"
      echo "$out" ;;
    *)
      cannot "check 7 reached no verdict: python3 $py exited $rc without an OK/MISMATCH line — the repo types are UNKNOWN, not proven wrong:"
      echo "$out" ;;
  esac
fi


# ── 8. Line endings stay as .gitattributes pins them (U-169 guard) ──────────
# Twelve tracked files are stored with CRLF: CHANGELOG.md, and eleven vendored
# cookbook files that no E-OS commit has ever touched. Nothing recorded that until
# U-173, so an editor that rewrote CHANGELOG.md on save turned a one-line append
# into a 2036-line whitespace diff (1018 insertions, 1018 deletions) and detached
# `git blame` from every measurement those entries cite. That is what happened in
# U-169, and it had to be spotted and reverted by hand.
# .gitattributes stops GIT from converting these files; this check stops an EDITOR
# from doing it, by failing the pre-push hook before the damage reaches a remote.
# The list is read out of .gitattributes rather than restated here, so the two
# cannot drift -- the same reasoning that makes check 6 derive its set from the
# tree (eos-source-rules.sh) instead of hard-coding it.
if [ ! -f .gitattributes ]; then
  bad ".gitattributes is missing — line endings are unpinned (U-173)"
else
  cr=$(printf '\r')
  pinned=$(awk '/^# --- eos:crlf-pinned ---$/{on=1;next} /^# --- end eos:crlf-pinned ---$/{on=0} on && $0 !~ /^#/ && NF {print $1}' .gitattributes)
  eol_hits=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ ! -f "$f" ]; then
      eol_hits="$eol_hits
  $f — pinned in .gitattributes but not in the tree"
    elif ! grep -q "$cr" "$f"; then
      eol_hits="$eol_hits
  $f — CRLF normalised away; do not commit that diff (see U-173)"
    fi
  done <<EOF
$pinned
EOF
  # CHANGELOG.md is held to the stricter form: EVERY line ends CRLF. A partially
  # normalised file — one LF-only line appended by a tool that got it wrong — still
  # holds CRs elsewhere and would sail through the has-a-CR test above.
  if [ -f CHANGELOG.md ]; then
    lf_only=$(grep -cv "$cr\$" CHANGELOG.md 2>/dev/null || true)
    if [ "${lf_only:-0}" -ne 0 ]; then
      eol_hits="$eol_hits
  CHANGELOG.md — $lf_only line(s) end LF, not CRLF"
    fi
  fi
  if [ -n "$eol_hits" ]; then
    bad "line endings no longer match .gitattributes:"; echo "$eol_hits"
  else
    ok "CRLF-pinned files keep their line endings"
  fi
fi
# ── 9. no image ships an active unauthenticated package source ──────────────────────
# R-701a: config/base.toml (inherited from upstream) ships /etc/pkg.d/50_redox pointing at
# https://static.redox-os.org/pkg. On an E-OS image that is a hole in our own hardening: a
# fresh install would pull binaries built WITHOUT the E-OS flags, over a channel whose
# signing key pkg-lib still fetches TOFU from the very host serving the packages.
#
# The image configs neutralise it by OVERRIDING the same path with a comment-only file.
# That is deliberate rather than deleting it: pkg-lib's update_remotes() skips '#' lines, so
# a comment-only file parses cleanly and yields zero remotes, whereas removing the file can
# leave /etc/pkg.d absent and its read_dir is fallible.
#
# The invariant this gate encodes is what actually ships, not a proxy for it: EVERY image
# config must override the path, and its override must carry no active URL. A first version
# of this check simply grepped every config for an active remote and failed on base.toml --
# which is correctly overridden, and verified so in a running image (`grep -c "^[^#]"
# /etc/pkg.d/50_redox` returns 0, and /etc/pkg.d holds nothing else). A gate that fires on
# a correctly-handled case teaches people to ignore it.
src_hits=""
for f in config/*/eos*.toml; do
  [ -f "$f" ] || continue

  # ONE comment-stripped view of the file, used by EVERY test below. Reading the raw file was
  # not a small inconsistency. The key-pin test on the next-but-one branch did a bare
  # `grep -q 'etc/pkg/eos-repo-sign.pub.toml' "$f"`, and both configs mention that path twice
  # in their own PROSE (aarch64: lines 721 and 740; x86_64: 749 and 768) before pinning it for
  # real (819 / 848). So the assertion matched the file's comments and could not fail on any
  # config that activates the E-OS repo using this template -- the template itself supplies the
  # string being searched for. Reproduced 2026-09-02: replace the one real `path = ...` stanza
  # with a bogus path and the gate still printed "ok"; delete the two comments as well and it
  # immediately reported "active E-OS repo but no pinned key -- unauthenticated". The green
  # light was coming from the prose, not from the artefact.
  #
  # The two tests three lines apart already disagreed about this: the "active URL" test stripped
  # indentation and dropped `^#` lines, the key test did neither. A gate that cannot fail is not
  # a gate (CLAUDE.md 4.1), and this one guards whether a shipped image trusts an
  # unauthenticated package source (R-701a / U-210).
  body=$(sed 's/^[[:space:]]*//' "$f" | grep -vE '^#')

  if ! printf '%s\n' "$body" | grep -q 'path = "/etc/pkg.d/50_redox"'; then
    src_hits="$src_hits
    $f — does not override /etc/pkg.d/50_redox, so base.toml's upstream remote ships"
    continue
  fi
  # Active = a non-comment line naming a package host.
  hits=$(printf '%s\n' "$body" \
         | grep -nE 'https?://[^[:space:]"]*(static\.redox-os\.org|/pkg)' \
         | grep -vE 'gh0s777tt\.github\.io/eos-pkg-' || true)
  # Allowed only if it is our own signed repo (eos-pkg-<arch>, repo.toml.sig verified
  # against the pinned key). If that source is active the config must pin the key too,
  # else it is unauthenticated (U-210).
  if [ -z "$hits" ] && printf '%s\n' "$body" | grep -qE 'gh0s777tt\.github\.io/eos-pkg-'; then
    printf '%s\n' "$body" | grep -q 'etc/pkg/eos-repo-sign.pub.toml' \
      || hits="active E-OS repo but no pinned key -- unauthenticated"
  fi
  if [ -n "$hits" ]; then
    src_hits="$src_hits
    $f — active package remote:
$(printf '%s' "$hits" | sed 's/^/      /')"
  fi
done
if [ -n "$src_hits" ]; then
  bad "an image would ship an unauthenticated package source (R-701a):"; echo "$src_hits"
else
  ok "no image ships an active unauthenticated package source"
fi

# ── 10. no repo-signing SECRET material in anything tracked ─────────────────────────
# The release-signing key is the root of trust for every package E-OS ships, and the only
# thing protecting it is that exactly one party holds it. .gitignore had NO entry for it
# until U-184, so keys/eos-repo-sign.secret.toml would have been untracked but not ignored
# -- a plain `git add -A` would have staged it.
#
# Ignoring it removes the accident, not the possibility (`git add -f` still works), so this
# checks the MATERIAL, not the filename: filenames can be changed, the shape of the secret
# cannot. Two conditions must hold together, and that pairing is the whole point:
#
#   a `[secret_keys]` table header at the START of a line, AND
#   an assignment of a long hex literal
#
# Either alone is a false positive. tools/eos-repo-sign/src/main.rs contains the literal
# text "[secret_keys]" and "ml_dsa_65_seed" -- it is the code that WRITES them -- and a first
# version of this check failed on exactly that file. keys/eos-repo-sign.pub.toml assigns long
# hex too, under [public_keys], and is meant to be committed. A gate that fires on the tool
# that implements the thing, or on the public half it is designed to ship, would be ignored
# within a week.
sec_hits=""
for f in $(git ls-files 2>/dev/null); do
  [ -f "$f" ] || continue
  grep -qE '^\[secret_keys\]' "$f" 2>/dev/null || continue
  grep -qE '=[[:space:]]*"[0-9a-fA-F]{32,}"' "$f" 2>/dev/null || continue
  sec_hits="$sec_hits
    $f"
done
if [ -n "$sec_hits" ]; then
  bad "repo-signing SECRET material in tracked files — treat the key as compromised and rotate:"
  echo "$sec_hits"
else
  ok "no repo-signing secret material in tracked files"
fi

# ── 11. no fork source vendored back into this repo ─────────────────────────────────
# R-F02: src/eos-installer used to be an exported copy of the installer, pinned to a dead
# v0.1 branch (68616dc) while the recipe built something else entirely -- three different
# hashes claiming to be the same thing, and the vendored copy was the one people read. It
# has since been removed, and this keeps it removed.
#
# A fork's code belongs in the fork, fetched at a pinned revision (CLAUDE.md 11, 20.2). A
# copy inside this repo cannot be pinned, drifts silently, and misrepresents what ships --
# the same failure mode as the snapshot directories archived in U-186, just committed.
vendored=""
for name in $(sed -n 's/^[[:space:]]*name[[:space:]]*=[[:space:]]*"\(eos-[a-z0-9-]*\)".*/\1/p' repos.toml 2>/dev/null); do
  case "$name" in
    eos-control|eos-sysmon|eos-ui|eos-guard|eos-notes) continue ;;  # type A, may live here
  esac
  for d in "src/$name" "vendor/$name" "$name"; do
    if [ -d "$d" ] && git ls-files --error-unmatch "$d" >/dev/null 2>&1; then
      vendored="$vendored
    $d — fork source committed into this repo"
    fi
  done
done
if [ -n "$vendored" ]; then
  bad "fork source vendored into this repo (R-F02) — pin the fork instead:"; echo "$vendored"
else
  ok "no fork source vendored into this repo"

# 12) Every recipe reachable from an image config -- INCLUDING the toolchain path, which is not
# reachable from config/*/eos.toml -- must pin the blake3 of its tarball. fetch.rs warns and
# continues without one, and config.rs rewrites ftp.gnu.org to a third-party mirror, so an unpinned
# tarball is fetched from a host we have no relationship with and built unverified.
if command -v python3 >/dev/null 2>&1; then
  if out="$(python3 scripts/eos-check-tar-pins.py 2>&1)"; then
    printf '%s\n' "$out" | grep -E '^\s+(ok|advisory):' || true
  else
    printf '%s\n' "$out"
    bad "a recipe in the image closure fetches a tarball with no blake3"
  fi
else
  cannot "check 12 could not run: python3 is missing -- tar pins are UNKNOWN, not proven present"
fi

# 13) No empty array expanded under `set -u` -- fatal on the reference host's bash 3.2.
# Check 5 greps for bash-4-ONLY SYNTAX and cannot see this: the script PARSES in 3.2 and dies at
# run time, on one branch, only when the array happens to be empty. Measured 2026-08-31 on
# scripts/ci-install-smoke.sh -- `VIDEO_ARGS[@]: unbound variable`, the harness dead before qemu
# started -- while THIS gate printed `ok: no bash-4-only syntax` and exited 0 in the same tree.
# A gate that lets through the class of defect it exists for is what CLAUDE.md 4.1 forbids.
if command -v python3 >/dev/null 2>&1; then
  if out="$(python3 scripts/eos-check-unbound-arrays.py 2>&1)"; then
    printf '%s\n' "$out" | grep -E '^ok:' >/dev/null && ok "${out#ok: }"
  else
    printf '%s\n' "$out"
    bad "an empty array is expanded under \`set -u\` -- this dies on bash 3.2"
  fi
else
  cannot "check 13 could not run: python3 is missing -- array guards are UNKNOWN, not proven present"
fi

# 14) No reference to a docs page that does not exist.
# The tree was reorganised once (d73fd1590) and mentions of the old paths stayed in running
# text. #12 fixed one path; #17 counted 8 paths / ~141 hits; a full scan found 22 / 230. Each
# sweep left the next drift free to accumulate because NOTHING FAILED when a stale path
# appeared. `lychee --offline` reports 0 errors on the same tree -- these are mentions in
# backticks, not links, so the link checker is structurally blind to them.
if command -v python3 >/dev/null 2>&1; then
  if out="$(python3 scripts/eos-check-doc-paths.py 2>&1)"; then
    printf '%s\n' "$out" | grep -E '^doc-paths: ok' >/dev/null && ok "${out#doc-paths: ok -- }"
  else
    printf '%s\n' "$out"
    bad "a docs/ reference points at a file that does not exist"
  fi
else
  cannot "check 14 could not run: python3 is missing -- docs paths are UNKNOWN, not proven live"
fi

# 15) No tracked build artefact or cache.
# CLAUDE.md has always forbidden committing caches. Nothing enforced it, and on 2026-09-01 two
# .pyc files reached `main` in a single day -- both swept in by `git add -A` in commits about
# something else, and invisible to every existing gate: a compiled cache is neither a secret
# nor a defect, so nothing was looking for one.
if command -v python3 >/dev/null 2>&1; then
  if out="$(python3 scripts/eos-check-no-caches.py 2>&1)"; then
    printf '%s\n' "$out" | grep -E '^no-caches: ok' >/dev/null && ok "${out#no-caches: ok -- }"
  else
    printf '%s\n' "$out"
    bad "a build artefact or cache is tracked in git"
  fi
else
  cannot "check 15 could not run: python3 is missing -- tracked artefacts are UNKNOWN"
fi
fi

[ "$fail" -eq 0 ] && echo "integrity: PASS" || echo "integrity: FAIL"
exit $fail
