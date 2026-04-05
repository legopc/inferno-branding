# Copilot Instructions — inferno-branding

## What this repo is

Custom branding for the **Inferno AoIP** appliance. Two surfaces:

1. **Cockpit web UI** — login screen, nav bar, favicon, logo
2. **Anaconda installer ISO** — pixmaps shown during OS installation

This is a **side project** of the main appliance build. Changes here do NOT
require rebuilding the Inferno Rust code. They integrate via:
- `COPY branding/cockpit/ /usr/share/cockpit/branding/fedora/` in the appliance Containerfile
- `scripts/inject-iso-branding.sh <iso>` after bootc-image-builder produces the ISO

## Key facts

| Item | Value |
|------|-------|
| Cockpit branding dir | `/usr/share/cockpit/branding/fedora/` (ID=fedora from /etc/os-release) |
| Accent colour | `#E05A00` (deep orange) — change in branding.css AND assets/logo.svg |
| Logo source | `assets/logo.svg` — render to PNG for deployment |
| Installer product.img | gitignored binary; rebuild with `scripts/build-product-img.sh` |
| Appliance repo | `legopc/inferno-aoip-releases` at `/home/legopc/copilot_projects/Inferno_Appliance/inferno-aoip-releases/` |
| Cockpit branding spec | https://github.com/cockpit-project/cockpit/blob/main/doc/branding.md |

## Repository structure

```
assets/           ← SVG master files (source of truth)
cockpit/          ← files baked into /usr/share/cockpit/branding/fedora/
installer/pixmaps/← Anaconda pixmap overrides (logo, sidebar, topbar)
installer/product.img ← GITIGNORED binary; run scripts/build-product-img.sh
scripts/          ← build-product-img.sh, inject-iso-branding.sh
```

## Common tasks

### Update the logo
1. Edit `assets/logo.svg`
2. Render PNGs (Inkscape preferred, rsvg-convert or Pillow as fallback)
3. Rebuild product.img: `bash scripts/build-product-img.sh`
4. Re-inject ISO: `bash scripts/inject-iso-branding.sh install.iso branded.iso`
5. Commit SVG + PNGs, push

### Change the accent colour
- `cockpit/branding.css` → `--ct-color-host-accent` and `--pf-t--global--color--brand--*`
- `assets/logo.svg` → `fill="#E05A00"` on flame elements and wordmark

### Test Cockpit branding without rebuilding the OCI image
Copy `cockpit/` to `/etc/cockpit/branding/` on a running node:
```bash
scp -r cockpit/ core@192.168.1.43:/tmp/cockpit-branding/
ssh core@192.168.1.43 "sudo mkdir -p /etc/cockpit/branding && sudo cp -r /tmp/cockpit-branding/* /etc/cockpit/branding/"
```
No restart needed — Cockpit reloads branding on next page load.

## Do NOT

- Commit `installer/product.img` (it is gitignored; it is a binary squashfs)
- Edit the PNGs in `cockpit/` or `installer/pixmaps/` directly with a text editor
- Touch `/home/legopc/copilot_projects/` unless asked — that is the deployment project
- Modify `inferno-aoip-releases/Containerfile` from this repo — propose the change and
  let the user apply it

## Related repos

| Repo | Purpose |
|------|---------|
| `legopc/inferno-aoip-releases` | Containerfile + appliance OCI image build |
| `legopc/cockpit-iot-updater` | Cockpit page for OTA updates |
| `legopc/Inferno_developement` | Rust source (inferno_aoip, alsa_pcm_inferno) |
