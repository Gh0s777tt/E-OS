#!/usr/bin/env bash
# eos-test-make-release — prove scripts/make-release.sh packages the install medium,
# and prove it can REFUSE. Every case below was seen failing before it was seen passing
# (CLAUDE.md §5.4, §5.9 level 2): a check that can only pass is not a check.
#
# The script under test derives ROOT from its own location, so each case gets a whole
# throwaway tree -- Makefile, mk/, .config and scripts/ copied in, build artefacts
# fabricated. Nothing here touches the real build tree or release/.
#
# Usage: bash scripts/eos-test-make-release.sh [-v]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERBOSE="${1:-}"
PASS=0; FAIL=0
TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/eos-mkrel-test.XXXXXX")"
trap 'rm -rf "$TMPROOT"' EXIT

note() { [ "$VERBOSE" = "-v" ] && printf '      %s\n' "$*" || true; }
ok()   { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; printf '        %s\n' "$2"; }

# Build a throwaway project tree. arch/version of the fabricated medium are arguments,
# so a case can create the mismatch it wants to catch.
mktree() { # <name> <arch> <medium-version> <make-harddrive:0|1> <make-medium:0|1>
  local name=$1 arch=$2 mver=$3 want_hd=$4 want_med=$5
  local t="$TMPROOT/$name"
  mkdir -p "$t/scripts" "$t/build/$arch/eos"
  cp "$ROOT/Makefile" "$t/"
  cp "$ROOT/.config" "$t/"
  cp -R "$ROOT/mk" "$t/"
  cp "$ROOT/scripts/make-release.sh" "$t/scripts/"
  [ "$want_hd" = 1 ]  && printf 'fake disk image\n' > "$t/build/$arch/eos/harddrive.img"
  [ "$want_med" = 1 ] && printf 'fake install medium\n' \
      > "$t/build/$arch/eos/eos-${mver}-${arch}-installer.img"
  printf '%s' "$t"
}

run() { # <tree> <env...> -- captures output and status without tripping set -e
  local t=$1; shift
  set +e
  OUT="$(cd "$t" && env "$@" bash scripts/make-release.sh 2>&1)"
  RC=$?
  set -e
  note "rc=$RC"
  note "$OUT"
}

printf '\n=== eos-test-make-release ===\n\n'

# ---------------------------------------------------------------- 1. positive
t="$(mktree positive x86_64 0.2.0 1 1)"
run "$t" ARCHES=x86_64 VERSION=0.2.0 EOS_ALLOW_UNSIGNED=1
if [ "$RC" -ne 0 ]; then
  bad "medium is packaged beside the disk image" "expected rc=0, got $RC: $OUT"
elif [ ! -f "$t/release/eos-0.2.0-x86_64-installer.img" ]; then
  bad "medium is packaged beside the disk image" "release/eos-0.2.0-x86_64-installer.img absent"
elif ! grep -q 'eos-0.2.0-x86_64-installer.img' "$t/release/SHA256SUMS"; then
  bad "medium is packaged beside the disk image" "medium missing from SHA256SUMS"
elif ! grep -q 'eos-0.2.0-x86_64.img' "$t/release/SHA256SUMS"; then
  bad "medium is packaged beside the disk image" "disk image missing from SHA256SUMS"
else
  ok "medium is packaged beside the disk image, both in SHA256SUMS"
fi

# The signature is applied to SHA256SUMS itself, so being in that file IS the coverage.
# Asserted structurally: no key is generated here -- that is a human action (CLAUDE.md §5.7).
if [ -f "$t/release/SHA256SUMS" ] && [ "$(grep -c . "$t/release/SHA256SUMS")" -eq 2 ]; then
  ok "SHA256SUMS holds exactly the two artefacts minisign would cover"
else
  bad "SHA256SUMS holds exactly the two artefacts minisign would cover" \
      "lines: $(grep -c . "$t/release/SHA256SUMS" 2>/dev/null || echo none)"
fi

# --------------------------------------------------- 2. negative: no medium
# This is the failure the issue asks for: today a missing medium is silence.
t="$(mktree no-medium x86_64 0.2.0 1 0)"
run "$t" ARCHES=x86_64 VERSION=0.2.0 EOS_ALLOW_UNSIGNED=1
if [ "$RC" -eq 0 ]; then
  bad "missing medium fails the release" "rc=0 -- a missing medium passed silently"
elif ! printf '%s' "$OUT" | grep -q 'eos-0.2.0-x86_64-installer.img'; then
  bad "missing medium fails the release" "non-zero but does not name the file: $OUT"
elif ! printf '%s' "$OUT" | grep -q 'build it first'; then
  # Not cosmetic. Without this line the case passes even when the existence check is
  # DELETED, because `cp` of a missing file also exits non-zero and also prints the
  # name -- measured: removing the check left all seven cases green. Asserting the
  # script's own remediation text is what pins the assertion to the intended mechanism.
  bad "missing medium fails the release" \
      "failed, but not via the script's own check -- no remediation line: $OUT"
elif [ -f "$t/release/SHA256SUMS.minisig" ]; then
  bad "missing medium fails the release" "it still produced a signature over a partial release"
else
  ok "missing medium fails the release, naming the file (rc=$RC)"
fi

# ------------------------------------------ 3. negative: version disagreement
t="$(mktree version-skew x86_64 0.2.0 1 1)"
run "$t" ARCHES=x86_64 VERSION=0.3.0 EOS_VERSION=0.2.0 EOS_ALLOW_UNSIGNED=1
if [ "$RC" -eq 0 ]; then
  bad "a medium built as another version is refused" "rc=0 -- relabelled silently"
elif printf '%s' "$OUT" | grep -q '0.3.0' && printf '%s' "$OUT" | grep -q '0.2.0'; then
  ok "a medium built as another version is refused, naming both (rc=$RC)"
else
  bad "a medium built as another version is refused" "does not name both versions: $OUT"
fi

# --------------------------------- 4. negative: the naming rule changed shape
t="$(mktree name-drift x86_64 0.2.0 1 1)"
# shellcheck disable=SC2016  # $(EOS_VERSION)/$(ARCH) are make expansions, not shell ones
sed -i.bak 's|^INSTALLER_MEDIUM_NAME=.*|INSTALLER_MEDIUM_NAME=install-$(EOS_VERSION)-$(ARCH).raw|' \
  "$t/mk/config.mk"
run "$t" ARCHES=x86_64 VERSION=0.2.0 EOS_ALLOW_UNSIGNED=1
if [ "$RC" -eq 2 ]; then
  ok "a renamed INSTALLER_MEDIUM_NAME is reported as a broken instrument (rc=2)"
else
  bad "a renamed INSTALLER_MEDIUM_NAME is reported as a broken instrument" \
      "expected rc=2, got $RC: $OUT"
fi

# ----------------------------- 5. control: the pre-existing check still works
t="$(mktree no-disk x86_64 0.2.0 0 1)"
run "$t" ARCHES=x86_64 VERSION=0.2.0 EOS_ALLOW_UNSIGNED=1
if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q 'harddrive.img'; then
  ok "control: a missing disk image still fails, as before this change (rc=$RC)"
else
  bad "control: a missing disk image still fails" "rc=$RC: $OUT"
fi

# ------------------------- 6. control: unsigned is still refused by default
t="$(mktree unsigned x86_64 0.2.0 1 1)"
run "$t" ARCHES=x86_64 VERSION=0.2.0
if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q 'UNSIGNED'; then
  ok "control: no key and no opt-in still refuses to assemble a release (rc=$RC)"
else
  bad "control: no key and no opt-in still refuses" "rc=$RC: $OUT"
fi

printf '\n  %d passed, %d failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
