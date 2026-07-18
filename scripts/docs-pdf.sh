#!/usr/bin/env bash
# docs-pdf.sh — render the mdBook docs to a single PDF.
#
# Robust path (no fragile mdbook-PDF plugin): mdBook builds the HTML site, which
# includes `print.html` (the whole book on one page, with mermaid rendered by JS),
# and headless Chromium prints THAT to PDF. Run it in the build container (or any
# Debian host); it bootstraps its own toolchain idempotently.
#
# Usage:  scripts/docs-pdf.sh [output.pdf]      (default: public/eos-docs.pdf)
#
# Toolchain pins match the `pages` CI job so the PDF matches the published site.
set -euo pipefail

OUT="${1:-public/eos-docs.pdf}"
MDBOOK_VER="0.4.40"
MERMAID_VER="0.14.0"
export PATH="${CARGO_HOME:-$HOME/.cargo}/bin:$PATH"

command -v mdbook >/dev/null        || cargo install mdbook --version "$MDBOOK_VER" --locked
command -v mdbook-mermaid >/dev/null || cargo install mdbook-mermaid --version "$MERMAID_VER" --locked
CHROME="$(command -v chromium || command -v chromium-browser || command -v google-chrome || true)"
if [ -z "$CHROME" ]; then
  echo "docs-pdf: installing chromium…"
  apt-get update -qq >/dev/null && apt-get install -y -qq chromium >/dev/null
  CHROME="$(command -v chromium || command -v chromium-browser)"
fi

echo "docs-pdf: building the HTML site (mdbook $MDBOOK_VER + mermaid $MERMAID_VER)"
mdbook-mermaid install . >/dev/null
rm -rf public
mdbook build -d public
[ -f public/print.html ] || { echo "docs-pdf: public/print.html missing — cannot render PDF" >&2; exit 1; }

echo "docs-pdf: printing print.html → $OUT (Chromium headless)"
mkdir -p "$(dirname "$OUT")"
# virtual-time-budget lets the mermaid JS finish before the print snapshot.
"$CHROME" --headless --no-sandbox --disable-gpu \
  --run-all-compositor-stages-before-draw --virtual-time-budget=15000 \
  --print-to-pdf="$OUT" "file://$(pwd)/public/print.html" 2>/dev/null

[ -s "$OUT" ] || { echo "docs-pdf: PDF was not produced" >&2; exit 1; }
echo "docs-pdf: OK — $OUT ($(du -h "$OUT" | cut -f1))"
