# inferno-branding

Custom branding for the **Inferno AoIP** appliance. Covers two surfaces:

| Surface | What it affects | How it's applied |
|---------|----------------|-----------------|
| **Cockpit** | Login screen background, logo badge, brand text, nav accent colour | `COPY cockpit/ /usr/share/cockpit/branding/fedora/` in `Containerfile` |
| **Anaconda installer** | Logo, sidebar image, topbar colour during OS installation | `scripts/inject-iso-branding.sh` post-processes the ISO |

---

## Repository layout

```
inferno-branding/
├── assets/
│   ├── logo.svg            ← master vector logo (edit this first)
│   ├── logo-dark.svg       ← dark variant for light backgrounds
│   └── placeholder/        ← notes on placeholder assets
├── cockpit/
│   ├── branding.css        ← Cockpit login + nav overrides
│   ├── favicon.ico         ← browser tab icon (16/32/48 px)
│   ├── apple-touch-icon.png← iOS home screen icon (180×180)
│   └── logo.png            ← badge logo on login screen (225×80)
├── installer/
│   ├── pixmaps/            ← Anaconda pixmap overrides
│   │   ├── logo.png        ← main installer logo
│   │   ├── sidebar-logo.png← sidebar brand mark
│   │   ├── sidebar-bg.png  ← sidebar background
│   │   └── topbar-bg.png   ← top bar background
│   └── product.img         ← GITIGNORED — build with scripts/build-product-img.sh
└── scripts/
    ├── build-product-img.sh    ← creates installer/product.img
    └── inject-iso-branding.sh  ← injects product.img into a bootc-image-builder ISO
```

---

## Quick start

### Bake Cockpit branding into the appliance image

In `inferno-aoip-releases/Containerfile`, add after the cockpit install step:

```dockerfile
# ── Inferno branding ───────────────────────────────────────────────────────────
COPY branding/cockpit/ /usr/share/cockpit/branding/fedora/
```

Then sync this repo into the appliance source tree:

```bash
# From inferno-aoip-releases root:
git clone https://github.com/legopc/inferno-branding branding
# or if already present:
cd branding && git pull
```

Rebuild the OCI image — Cockpit will pick up the branding on next login.

**Live update (no rebuild):** Copy `cockpit/` to `/etc/cockpit/branding/` on a running node:

```bash
scp -r cockpit/ core@<node-ip>:/tmp/inferno-branding/
ssh core@<node-ip> "sudo mkdir -p /etc/cockpit/branding && sudo cp -r /tmp/inferno-branding/cockpit/* /etc/cockpit/branding/"
```

---

### Brand the installer ISO

**Step 1 — Build `product.img`** (requires `squashfs-tools`):

```bash
bash scripts/build-product-img.sh
# Output: installer/product.img
```

**Step 2 — Inject into ISO** (requires `xorriso`):

```bash
bash scripts/inject-iso-branding.sh /path/to/install.iso /path/to/inferno-branded.iso
```

The branded ISO is drop-in compatible with Proxmox ISO storage — copy or symlink it:

```bash
ln -sf /path/to/inferno-branded.iso /var/lib/vz/template/iso/inferno-appliance-vN-branded.iso
```

---

## Customising the branding

### Colours

The accent colour `#E05A00` (deep orange) is defined in two places:

| File | Variable / selector |
|------|-------------------|
| `cockpit/branding.css` | `--ct-color-host-accent` and `--pf-t--global--color--brand--*` |
| `assets/logo.svg` | `fill="#E05A00"` on flame elements and wordmark |

Change both to repaint everything consistently.

### Logo

1. Edit `assets/logo.svg` (the master source — all other PNGs derive from it)
2. Re-render PNGs:

```bash
# With Inkscape (best quality):
inkscape --export-type=png --export-width=225 --export-height=80 \
    -o cockpit/logo.png assets/logo.svg

inkscape --export-type=png --export-width=180 --export-height=180 \
    -o cockpit/apple-touch-icon.png assets/logo.svg

inkscape --export-type=png --export-width=200 --export-height=60 \
    -o installer/pixmaps/logo.png assets/logo.svg

# With rsvg-convert (librsvg):
rsvg-convert -w 225 -h 80 assets/logo.svg -o cockpit/logo.png

# With Python/Pillow (no external tools, lower quality text rendering):
python3 -c "
from PIL import Image; import cairosvg
cairosvg.svg2png(url='assets/logo.svg', write_to='cockpit/logo.png', output_width=225, output_height=80)
"
```

3. Regenerate `favicon.ico`:

```bash
# With ImageMagick:
convert -resize 16x16 cockpit/logo.png /tmp/16.png
convert -resize 32x32 cockpit/logo.png /tmp/32.png
convert -resize 48x48 cockpit/logo.png /tmp/48.png
convert /tmp/16.png /tmp/32.png /tmp/48.png cockpit/favicon.ico
```

### Cockpit CSS

Edit `cockpit/branding.css` directly. Key selectors:

| Selector | What it styles |
|----------|---------------|
| `html body.login-pf` | Login page background |
| `#badge` | Logo in the upper-right corner of the login screen |
| `#brand::before` | Text above the login fields |
| `:root { --ct-color-host-accent }` | Navigation bar accent |
| `.login-pf-page .card-pf` | Login form card |

Variables `${NAME}` and `${VARIANT}` in CSS `content:` expand from `/etc/os-release` at runtime.
Set these in the `Containerfile`:

```dockerfile
RUN sed -i 's/^NAME=.*/NAME="Inferno"/' /etc/os-release && \
    echo 'VARIANT="AoIP"' >> /etc/os-release
```

### Anaconda pixmaps

| File | Size | Description |
|------|------|-------------|
| `installer/pixmaps/logo.png` | 200×60 | Main logo shown during install |
| `installer/pixmaps/sidebar-logo.png` | 200×60 | Sidebar brand mark |
| `installer/pixmaps/sidebar-bg.png` | 400×400+ | Sidebar background fill |
| `installer/pixmaps/topbar-bg.png` | any × 60 | Top bar background |

After editing, rebuild `product.img` and re-inject into the ISO.

---

## Integration checklist for a new release

- [ ] Update `assets/logo.svg` if the logo changed
- [ ] Re-render all PNGs (see **Customising → Logo** above)
- [ ] Update accent colour in `cockpit/branding.css` if colour changed
- [ ] `git commit` and `git push`
- [ ] In `inferno-aoip-releases`: `cd branding && git pull`
- [ ] Rebuild OCI image → Cockpit branding is baked in
- [ ] `bash scripts/build-product-img.sh` → rebuild `installer/product.img`
- [ ] `bash scripts/inject-iso-branding.sh install.iso branded.iso` → branded installer

---

## How Cockpit selects branding

Cockpit loads branding from the first directory that contains the requested file:

```
/etc/cockpit/branding/              ← admin override (highest priority)
/usr/share/cockpit/branding/fedora/ ← our baked-in branding (ID=fedora in /etc/os-release)
/usr/share/cockpit/branding/default ← Cockpit upstream fallback
```

Since `fedora-bootc:43` has `ID=fedora` in `/etc/os-release`, our files in
`/usr/share/cockpit/branding/fedora/` are picked up automatically without any
Cockpit configuration changes.

All branding files are served **without authentication** (required for the login screen).

---

## How installer branding works

When Anaconda boots the installer ISO, it looks for `/images/product.img` — a squashfs
archive. If present, it is overlaid onto the installer's filesystem. Files inside
`product.img` at `/usr/share/anaconda/pixmaps/` replace the defaults.

`scripts/build-product-img.sh` creates `product.img` from `installer/pixmaps/`.  
`scripts/inject-iso-branding.sh` uses `xorriso` to repack the ISO with the new file.

`product.img` is gitignored because it is a binary artifact — regenerate it from source.
