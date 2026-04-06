#!/usr/bin/env bash
# scripts/inject-iso-branding.sh
#
# Injects installer/product.img into a bootc-image-builder Anaconda ISO,
# replacing the Fedora default installer branding with Inferno branding.
#
# Prerequisites:
#   sudo dnf install xorriso isomd5sum   # Fedora/RHEL
#   sudo apt install xorriso             # Debian/Ubuntu
#   bash scripts/build-product-img.sh   # build product.img first
#
# Usage:
#   bash scripts/inject-iso-branding.sh <input.iso> [output.iso]
#
#   input.iso   — ISO produced by bootc-image-builder (install.iso)
#   output.iso  — branded ISO to write (default: input basename + -branded.iso)
#
# Example:
#   bash scripts/inject-iso-branding.sh /tmp/install.iso \
#       /tmp/inferno-appliance-v10-branded.iso
#
# What this does:
#   1. Extracts the ISO filesystem
#   2. Replaces /images/product.img with the one from installer/product.img
#   3. Repacks the ISO with the same boot parameters (El Torito + GPT hybrid)
#   4. Updates the ISO checksum (implantisomd5)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

INPUT_ISO="${1:-}"
OUTPUT_ISO="${2:-}"

if [[ -z "$INPUT_ISO" ]]; then
    echo "Usage: $0 <input.iso> [output.iso]" >&2
    exit 1
fi

if [[ ! -f "$INPUT_ISO" ]]; then
    echo "Error: $INPUT_ISO not found" >&2
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT_IMG="$REPO_ROOT/installer/product.img"

if [[ ! -f "$PRODUCT_IMG" ]]; then
    echo "Error: installer/product.img not found. Run scripts/build-product-img.sh first." >&2
    exit 1
fi

# Default output filename
if [[ -z "$OUTPUT_ISO" ]]; then
    BASE="$(basename "$INPUT_ISO" .iso)"
    OUTPUT_ISO="$(dirname "$INPUT_ISO")/${BASE}-branded.iso"
fi

WORKDIR="$(mktemp -d)"
EXTRACT_DIR="$WORKDIR/iso"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

echo "[inject-iso] Input:   $INPUT_ISO"
echo "[inject-iso] Output:  $OUTPUT_ISO"
echo "[inject-iso] product.img: $PRODUCT_IMG ($(du -sh "$PRODUCT_IMG" | cut -f1))"
echo ""

# ── Step 1: extract ISO ───────────────────────────────────────────────────────
echo "[inject-iso] Extracting ISO filesystem…"
mkdir -p "$EXTRACT_DIR"
xorriso -osirrox on -indev "$INPUT_ISO" -extract / "$EXTRACT_DIR" 2>/dev/null
echo "  Done."

# ── Step 2: inject product.img ───────────────────────────────────────────────
echo "[inject-iso] Injecting product.img → images/product.img"
mkdir -p "$EXTRACT_DIR/images"
cp "$PRODUCT_IMG" "$EXTRACT_DIR/images/product.img"

# ── Step 3: detect original boot parameters and repack ───────────────────────
echo "[inject-iso] Repacking ISO…"

# Pull the volume ID from the original ISO
VOLID="$(xorriso -indev "$INPUT_ISO" 2>&1 | awk '/Volume Id/{print $NF; exit}')" || true
[[ -z "$VOLID" ]] && VOLID="Fedora-S-dvd-x86_64-43"

# Build xorriso repack command
# We preserve El Torito (BIOS) and GPT hybrid (UEFI) boot entries
xorriso -as mkisofs \
    -r -J \
    --volid "${VOLID}" \
    -c isolinux/boot.cat \
    -b isolinux/isolinux.bin \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot \
    -e images/efiboot.img \
        -no-emul-boot \
    -isohybrid-gpt-basdat \
    -o "$OUTPUT_ISO" \
    "$EXTRACT_DIR" 2>/dev/null || {
        # Fallback: simpler repack without BIOS boot (UEFI only)
        echo "  BIOS boot entry not found — repacking UEFI-only"
        xorriso -as mkisofs \
            -r -J \
            --volid "${VOLID}" \
            -eltorito-alt-boot \
            -e images/efiboot.img \
                -no-emul-boot \
            -isohybrid-gpt-basdat \
            -o "$OUTPUT_ISO" \
            "$EXTRACT_DIR" 2>/dev/null
    }

# ── Step 4: update checksum ──────────────────────────────────────────────────
if command -v implantisomd5 &>/dev/null; then
    echo "[inject-iso] Updating ISO checksum…"
    implantisomd5 "$OUTPUT_ISO"
fi

SIZE="$(du -sh "$OUTPUT_ISO" | cut -f1)"
echo ""
echo "[inject-iso] ✓ Branded ISO written: $OUTPUT_ISO ($SIZE)"
