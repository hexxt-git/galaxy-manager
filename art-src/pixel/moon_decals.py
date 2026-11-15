# Flat ground decals for the outdoor moon tiles (regolith.png, crater.png), in each tile's own palette, no ink.
# Usage: moon_decals.py <out_dir>  ->  <out_dir>/regolith_<thing>.png, <out_dir>/crater_<thing>.png
import sys, math, random, pathlib
from PIL import Image, ImageDraw
sys.path.insert(0, str(pathlib.Path(__file__).parent))  # -I leaves the script's folder off the path
from contrast import soften

# colony_tiles.py runs its export at import time, so only its helper definitions are executed.
_src = (pathlib.Path(__file__).with_name('colony_tiles.py')).read_text()
_ns = {'__file__': __file__}
exec(_src.split('\nout = pathlib')[0], _ns)
stroke = _ns['stroke']

REG = dict(BASE=(152, 152, 149), PATCH=(145, 145, 142), PATCH2=(158, 157, 153), PEB=(172, 171, 166),
           PEB_DK=(124, 124, 122), DK=(130, 130, 128), HI=(166, 165, 160), TRACK=(139, 139, 136))
CRA = dict(BASE=(72, 80, 98), PATCH=(66, 74, 92), PATCH2=(77, 85, 103), PEB=(88, 96, 114), PEB_DK=(56, 62, 78),
           DK=(58, 65, 82), HI=(84, 92, 110), GLINT=(150, 186, 206), FROST=(104, 124, 146), FROST2=(126, 150, 172),
           ROCK=(48, 54, 68), ROCK_TOP=(82, 90, 108))


def canvas(w, h):
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def rgba(c):
    return c + (255,)


def blob(cx, cy, r, rng, k=0.2, n=48, sq=0.75):
    # Closed wobbly outline from a few random harmonics, squashed vertically for the top-down 3/4 view.
    h = [(rng.uniform(-k, k), rng.uniform(0, 6.3), m) for m in (2, 3, 5)]
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        rr = r * (1 + sum(a * math.sin(m * t + ph) for a, ph, m in h))
        pts.append((cx + rr * math.cos(t), cy + sq * rr * math.sin(t)))
    return pts


def trim(img):
    return img.crop(img.getbbox())


def bowl(d, cx, cy, r, P, rng, k=0.06):
    # Light from above: the upper inner wall is in shadow, the lower rim catches light.
    d.polygon(blob(cx, cy + 1, r + 2.5, rng, k), fill=rgba(P['HI']))
    d.polygon(blob(cx, cy, r, rng, k), fill=rgba(P['DK']))
    d.polygon(blob(cx, cy + r * 0.2, r * 0.82, rng, k), fill=rgba(P['BASE']))


def pebble(d, x, y, r, top, under):
    d.ellipse((x - r, y - r * 0.8 + 1, x + r, y + r * 0.8 + 1), fill=rgba(under))
    d.ellipse((x - r, y - r * 0.8, x + r, y + r * 0.8 - 0.5), fill=rgba(top))


# --- regolith ---

def regolith_crater_small():
    img, d = canvas(64, 50)
    rng = random.Random(3)
    d.polygon(blob(32, 25, 29, rng, 0.12), fill=rgba(REG['PATCH']))
    bowl(d, 32, 24, 22, REG, rng)
    d.polygon(blob(34, 29, 7, rng, 0.2), fill=rgba(REG['PATCH']))
    pebble(d, 9, 38, 1.8, REG['PEB'], REG['PEB_DK'])
    pebble(d, 56, 14, 1.5, REG['PEB'], REG['PEB_DK'])
    return trim(img)


def regolith_crater_big():
    img, d = canvas(112, 84)
    rng = random.Random(7)
    d.polygon(blob(56, 42, 52, rng, 0.08), fill=rgba(REG['PATCH']))
    d.polygon(blob(56, 42, 46, rng, 0.05), fill=rgba(REG['PATCH2']))
    bowl(d, 56, 40, 38, REG, rng, 0.04)
    d.polygon(blob(58, 49, 18, rng, 0.15), fill=rgba(REG['PATCH']))
    bowl(d, 40, 50, 6, REG, rng)
    for x, y, r in ((12, 58, 2.5), (18, 64, 1.6), (98, 22, 2), (92, 66, 1.6), (70, 10, 1.5), (60, 58, 1.8)):
        pebble(d, x, y, r, REG['PEB'], REG['PEB_DK'])
    return trim(img)


def regolith_boot_prints():
    img, d = canvas(100, 56)
    for i in range(9):
        t = i / 8
        x = 8 + 84 * t
        y = 40 - 22 * t + 6 * math.sin(t * 5)
        ang = math.atan2(-22 + 30 * math.cos(t * 5), 84)
        side = 3.2 if i % 2 else -3.2
        nx, ny = -math.sin(ang), math.cos(ang)
        cx, cy = x + nx * side, y + ny * side
        # A boot is a sole oval plus a smaller heel, toe pointing along the walk.
        ux, uy = math.cos(ang), math.sin(ang)
        for off, rx, ry in ((1.6, 3.2, 2.0), (-2.6, 2.0, 1.7)):
            px, py = cx + ux * off, cy + uy * off
            d.ellipse((px - rx, py - ry, px + rx, py + ry), fill=rgba(REG['DK']))
        d.rectangle((round(cx), round(cy) - 1, round(cx), round(cy)), fill=rgba(REG['PEB_DK']))
    return trim(img)


def regolith_tyre_tracks():
    img, d = canvas(128, 40)
    pts = [(4 + i * 4, 24 - 9 * math.sin(i / 30 * math.pi * 0.9)) for i in range(31)]
    for side in (-7, 7):
        line = [(x, y + side) for x, y in pts]
        stroke(d, line, rgba(REG['TRACK']), 2.6)
        for k, (x, y) in enumerate(line[1:-1]):
            if k % 2 == 0:
                d.rectangle((round(x), round(y) - 2, round(x), round(y) + 2), fill=rgba(REG['DK']))
    return trim(img)


def regolith_pebbles():
    img, d = canvas(48, 32)
    rng = random.Random(23)
    d.polygon(blob(24, 17, 17, rng, 0.2), fill=rgba(REG['PATCH']))
    for x, y, r in ((16, 14, 3.5), (25, 18, 4.5), (33, 12, 2.5), (11, 21, 2), (36, 22, 2.8), (22, 9, 1.8), (30, 25, 1.6)):
        pebble(d, x, y, r, REG['PEB'], REG['PEB_DK'])
    return trim(img)


# --- crater floor ---

def crater_crater_small():
    img, d = canvas(56, 44)
    rng = random.Random(37)
    d.polygon(blob(28, 22, 25, rng, 0.12), fill=rgba(CRA['PATCH']))
    bowl(d, 28, 21, 18, CRA, rng)
    d.polygon(blob(30, 25, 6, rng, 0.2), fill=rgba(CRA['PATCH']))
    pebble(d, 50, 34, 1.6, CRA['PEB'], CRA['PEB_DK'])
    return trim(img)


def crater_rocks():
    img, d = canvas(60, 36)
    for x, y, r in ((14, 16, 5), (27, 21, 6.5), (40, 13, 3.5), (47, 24, 4), (9, 26, 2.5), (34, 29, 2.2), (22, 9, 2)):
        d.ellipse((x - r, y - r * 0.7 + 1.5, x + r, y + r * 0.7 + 1.5), fill=rgba(CRA['PEB_DK']))
        d.ellipse((x - r, y - r * 0.7, x + r, y + r * 0.7), fill=rgba(CRA['ROCK']))
        d.ellipse((x - r * 0.7, y - r * 0.7, x + r * 0.6, y + r * 0.15), fill=rgba(CRA['ROCK_TOP']))
    return trim(img)


DECALS = [regolith_crater_small, regolith_crater_big, regolith_boot_prints, regolith_tyre_tracks, regolith_pebbles,
          crater_crater_small, crater_rocks]

if __name__ == '__main__':
    out = pathlib.Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for make in DECALS:
        img = soften(make())
        img.save(out / f'{make.__name__}.png')
        print(make.__name__, img.size)
