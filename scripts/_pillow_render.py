#!/usr/bin/env python3
"""
scripts/_pillow_render.py — Pillow-based fallback renderer.

Called by render-assets.sh when no SVG renderer is available.
Generates placeholder-quality PNGs using geometry (no SVG parsing).

Usage:
  python3 scripts/_pillow_render.py <target> <output_path> [width] [height]

  target: logo | favicon | sidebar-bg | topbar-bg
"""
import sys
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

ORANGE       = (224, 90,  0,  255)
ORANGE_LIGHT = (255, 179, 71, 255)
ORANGE_DEEP  = (139, 37,  0,  255)
GREY         = (153, 153, 153, 255)
DARK_BG      = (26,  26,  26,  255)

def draw_flame(d, x0, y0, s):
    for cx, cy, rx, ry, col in [
        (x0+14*s, y0+46*s, 9*s,  18*s, ORANGE_DEEP),
        (x0+18*s, y0+38*s, 8*s,  20*s, ORANGE),
        (x0+22*s, y0+28*s, 6*s,  16*s, ORANGE),
        (x0+14*s, y0+24*s, 5*s,  12*s, ORANGE),
        (x0+10*s, y0+32*s, 5*s,  14*s, ORANGE_DEEP),
        (x0+18*s, y0+18*s, 4*s,  10*s, ORANGE_LIGHT),
    ]:
        d.ellipse([cx-rx, cy-ry, cx+rx, cy+ry], fill=col)

def load_font(size, bold=False):
    candidates = [
        '/usr/share/fonts/liberation/LiberationSans-Bold.ttf' if bold else
        '/usr/share/fonts/liberation/LiberationSans-Regular.ttf',
        '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf' if bold else
        '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            pass
    return ImageFont.load_default()

def render_logo(path, w, h, bg=DARK_BG, text_col=ORANGE, sub_col=GREY, subtext='AoIP'):
    img = Image.new('RGBA', (w, h), bg)
    d = ImageDraw.Draw(img)
    s = min(w * 0.22 / 28.0, h * 0.95 / 64.0)
    draw_flame(d, int(w * 0.01), int(h * 0.02), s)
    font_main = load_font(int(h * 0.42), bold=True)
    font_sub  = load_font(int(h * 0.18))
    d.text((int(w * 0.25), int(h * 0.10)), 'INFERNO', font=font_main, fill=text_col)
    if subtext:
        d.text((int(w * 0.25)+3, int(h * 0.62)), subtext, font=font_sub, fill=sub_col)
    img.save(path)

def render_favicon(path):
    def frame(size):
        img = Image.new('RGBA', (size, size), DARK_BG)
        d = ImageDraw.Draw(img)
        s = size / 64.0
        draw_flame(d, size * 0.05, size * 0.02, s)
        return img
    frames = [frame(s) for s in [16, 32, 48]]
    frames[0].save(path, format='ICO',
                   sizes=[(16,16),(32,32),(48,48)], append_images=frames[1:])

def render_sidebar_bg(path, w=400, h=600):
    img = Image.new('RGBA', (w, h), (20, 20, 20, 255))
    d = ImageDraw.Draw(img)
    draw_flame(d, w * 0.15, h * 0.42, h / 180.0)
    img.save(path)

def render_topbar_bg(path, w=800, h=60):
    img = Image.new('RGBA', (w, h), DARK_BG)
    img.save(path)

if __name__ == '__main__':
    target = sys.argv[1]
    out    = sys.argv[2]
    w = int(sys.argv[3]) if len(sys.argv) > 3 else 200
    h = int(sys.argv[4]) if len(sys.argv) > 4 else 60

    if target == 'favicon':
        render_favicon(out)
    elif target == 'sidebar-bg':
        render_sidebar_bg(out, w, h)
    elif target == 'topbar-bg':
        render_topbar_bg(out, w, h)
    else:
        render_logo(out, w, h)
