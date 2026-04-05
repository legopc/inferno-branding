#!/usr/bin/env bash
# scripts/build-product-img.sh
#
# Creates installer/product.img — a squashfs image that Anaconda overlays
# at runtime to apply custom branding to the installer UI.
#
# Prerequisites (on the build machine):
#   sudo dnf install squashfs-tools       # Fedora/RHEL
#   sudo apt install squashfs-tools       # Debian/Ubuntu
#
# Usage:
#   bash scripts/build-product-img.sh
#
# Output:
#   installer/product.img   (gitignored — regenerate any time)
#
# To update logos:
#   1. Edit SVGs in assets/ and re-render PNGs in installer/pixmaps/
#      (see assets/README-ASSETS.md for render instructions)
#   2. Re-run this script
#   3. Re-run scripts/inject-iso-branding.sh on your ISO
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIXMAPS_DIR="$REPO_ROOT/installer/pixmaps"
OUTPUT="$REPO_ROOT/installer/product.img"
STAGING="$(mktemp -d)"

cleanup() { rm -rf "$STAGING"; }
trap cleanup EXIT

echo "[build-product-img] Staging files from $PIXMAPS_DIR"

# Anaconda looks for branding pixmaps at /usr/share/anaconda/pixmaps/
DEST="$STAGING/usr/share/anaconda/pixmaps"
mkdir -p "$DEST"

for f in logo.png sidebar-logo.png sidebar-bg.png topbar-bg.png; do
    src="$PIXMAPS_DIR/$f"
    if [[ -f "$src" ]]; then
        cp "$src" "$DEST/$f"
        echo "  ✓ $f"
    else
        echo "  ⚠ $f not found — skipping (installer will use Fedora default)"
    fi
done

echo "[build-product-img] Creating squashfs → $OUTPUT"
mksquashfs "$STAGING" "$OUTPUT" -comp xz -noappend -quiet
echo "[build-product-img] Done. Size: $(du -sh "$OUTPUT" | cut -f1)"
echo ""
echo "Next step: inject into your ISO with:"
echo "  bash scripts/inject-iso-branding.sh <input.iso> <output.iso>"
