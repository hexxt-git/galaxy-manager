# Wall-mounted details drawn on a wall tile's 52 px front face (colony_tiles.py walls), no footprint.
# Usage: wall_decos.py <out_dir>  ->  <out_dir>/wall_deco_<name>.png
# Each image is (48|96) x (TY + 52): the face occupies rows TY..TY+51 (wall tile y44..95); anything above pokes onto the cap.
# Origin = (0, TY) aligns with the top-left of the wall cell's front face.
import sys, math, random, pathlib
from PIL import Image, ImageDraw
sys.path.insert(0, str(pathlib.Path(__file__).parent))  # -I leaves the script's folder off the path
from contrast import soften

# colony_tiles.py exports at import time, so only its helper definitions are executed.
_ns = {'__file__': __file__}
exec((pathlib.Path(__file__).with_name('colony_tiles.py')).read_text().split('\nout = pathlib')[0], _ns)
Wobble, stroke, INK, LINE_R, DETAIL_R = (_ns[k] for k in ('Wobble', 'stroke', 'INK', 'LINE_R', 'DETAIL_R'))


def c(h):
    """Hex colour pulled through the global contrast."""
    rgb = tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))
    return soften(Image.new('RGB', (1, 1), rgb)).getpixel((0, 0)) + (255,)


INKA = INK + (255,)
FACE_LIT = c('#93adae')
GUN, GUN_DK = c('#8a909c'), c('#555a68')
MACH, MACH_DK = c('#4b505e'), c('#2c2f3a')
BRASS, BRASS_DK = c('#c9a548'), c('#8a6733')
RED, RED_DK = c('#c8453f'), c('#8a2b33')
TEAL, TEAL2 = c('#6fd0d8'), c('#5fc9b8')
PAPER, PAPER_DK = c('#dfe7e4'), c('#c4d8d4')
BLUE, BLUE_DK = c('#4a92c9'), c('#2b5c91')
LEAF, LEAF_HI = c('#5fbf45'), c('#b5dc4f')
TERRA, TERRA_DK = c('#d0703f'), c('#9a4f2c')
LED = c('#7ed957')
SPACE = c('#14141f')
WARM, WARM_HI = c('#f2c96a'), c('#fff0bf')


FACE_H = 52


def canvas(w, ty):
    img = Image.new('RGBA', (w, ty + FACE_H), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def rect(wb, x0, y0, x1, y1, amp=0.6, r=3):
    """Wobbly rectangle with chamfered corners (the round brush finishes the rounding)."""
    pts = [(x0 + r, y0), (x1 - r, y0), (x1, y0 + r), (x1, y1 - r),
           (x1 - r, y1), (x0 + r, y1), (x0, y1 - r), (x0, y0 + r)]
    return wb.poly([p for k, p in enumerate(pts) if p != pts[k - 1]], amp)


def ring(cx, cy, r, n=40, seed=0, amp=0.25):
    rng = random.Random(seed)
    ph = rng.uniform(0, 6.3)
    return [(cx + (r + amp * math.sin(3 * t + ph)) * math.cos(t), cy + (r + amp * math.sin(3 * t + ph)) * math.sin(t))
            for t in (2 * math.pi * i / n for i in range(n))]


def shape(d, pts, fill, ink=DETAIL_R):
    d.polygon(pts, fill=fill)
    if ink:
        # The brush only stamps at points, so sparse corner lists are filled in first.
        dense = []
        for p, q in zip(pts, pts[1:] + pts[:1]):
            n = max(1, int(math.hypot(q[0] - p[0], q[1] - p[1]) * 2))
            dense += [(p[0] + (q[0] - p[0]) * t / n, p[1] + (q[1] - p[1]) * t / n) for t in range(n)]
        stroke(d, dense + dense[:1], INKA, ink)


def screen():
    ty = 0
    img, d = canvas(48, ty)
    wb = Wobble(999, 999, 11)
    shape(d, rect(wb, 8, 7, 40, 34), MACH)
    d.rectangle((10, 29, 38, 32), fill=MACH_DK)
    shape(d, rect(wb, 12, 10, 36, 25, 0.3, 2), TEAL, DETAIL_R)
    pts = [(15, 21), (19, 18), (22, 20), (26, 15), (29, 18), (33, 16)]
    for p, q in zip(pts, pts[1:]):
        d.line((p, q), fill=MACH_DK, width=1)
    d.line((15, 13, 21, 13), fill=TEAL2, width=1)
    d.rectangle((33, 30, 34, 31), fill=LED)
    d.rectangle((29, 30, 30, 31), fill=TEAL2)
    # Small keypad below the monitor.
    shape(d, rect(wb, 17, 37, 31, 44, 0.2, 1), GUN, DETAIL_R)
    for x in (20, 24, 28):
        d.rectangle((x - 1, 40, x, 41), fill=MACH)
    return img, ty


def vent():
    ty = 0
    img, d = canvas(48, ty)
    wb = Wobble(999, 999, 21)
    shape(d, rect(wb, 8, 22, 40, 44), GUN)
    d.rectangle((11, 25, 37, 41), fill=MACH_DK)
    for y in (26, 30, 34, 38):
        d.rectangle((12, y, 36, y + 1), fill=MACH)
        d.line((12, y, 36, y), fill=GUN_DK)
    for x in (10, 38):
        d.point([(x, 24), (x, 42)], fill=GUN_DK)
    return img, ty


def pipes():
    ty = 0
    img, d = canvas(96, ty)
    wb = Wobble(999, 999, 31)
    for y0, h in ((12, 7), (24, 8)):
        shape(d, rect(wb, 1, y0, 95, y0 + h, 0.3, 2), GUN)
        d.rectangle((3, y0 + h - 2, 93, y0 + h - 2), fill=GUN_DK)
        d.rectangle((3, y0 + 1, 93, y0 + 1), fill=c('#a3a9b4'))
    for x in (14, 82):
        shape(d, rect(wb, x - 2, 9, x + 2, 35, 0.2, 1), BRASS, DETAIL_R)
    # Valve on the lower pipe: brass body with a red handwheel above it.
    shape(d, rect(wb, 52, 21, 64, 35, 0.3, 2), BRASS)
    d.rectangle((54, 31, 62, 33), fill=BRASS_DK)
    stroke(d, wb.line((58, 21), (58, 12), 0.2), INKA, DETAIL_R)
    shape(d, ring(58, 9, 4.5, 24, seed=3, amp=0.1), RED, DETAIL_R)
    d.ellipse((56, 7, 60, 11), fill=RED_DK)
    d.ellipse((57, 8, 59, 10), fill=INKA)
    # Gauge on the upper pipe.
    shape(d, ring(32, 9, 4, 24, seed=5, amp=0.1), PAPER, DETAIL_R)
    d.line((32, 9, 34, 7), fill=RED_DK)
    return img, ty


def light():
    ty = 0
    img, d = canvas(48, ty)
    wb = Wobble(999, 999, 41)
    d.polygon([(10, 12), (38, 12), (46, 47), (2, 47)], fill=FACE_LIT)
    shape(d, rect(wb, 6, 4, 42, 14, 0.3, 2), GUN)
    d.rectangle((9, 8, 39, 12), fill=WARM)
    d.line((10, 9, 38, 9), fill=WARM_HI)
    return img, ty


def poster():
    ty = 0
    img, d = canvas(48, ty)
    wb = Wobble(999, 999, 51)
    shape(d, rect(wb, 12, 6, 36, 40, 0.4, 1), PAPER)
    d.rectangle((15, 9, 33, 28), fill=SPACE)
    cy = 19
    shape(d, ring(24, cy, 6.5, 30, seed=4, amp=0.1), BLUE, DETAIL_R)
    d.polygon([(21, cy - 3), (24, cy - 4), (25, cy - 1), (23, cy + 1), (21, cy)], fill=LEAF)
    d.polygon([(25, cy + 1), (27, cy), (27, cy + 3), (26, cy + 3)], fill=LEAF)
    d.arc((18, cy - 6, 30, cy + 6), 20, 110, fill=BLUE_DK, width=1)
    d.point((31, 11), fill=PAPER)
    d.point((17, 25), fill=PAPER)
    d.rectangle((16, 32, 32, 32), fill=PAPER_DK)
    d.rectangle((19, 35, 29, 35), fill=PAPER_DK)
    for x in (11, 35):
        d.rectangle((x, 5, x + 2, 7), fill=c('#e8d9a0'))
    return img, ty


def shelf_plants():
    ty = 0
    img, d = canvas(48, ty)
    wb = Wobble(999, 999, 61)
    sh = 34  # shelf top
    for x in (9, 39):
        shape(d, [(x - 2, sh + 4), (x + 2, sh + 4), (x + 2, sh + 11), (x - 2, sh + 7)], BRASS_DK, 0.8)
    shape(d, rect(wb, 3, sh, 45, sh + 5, 0.3, 1), BLUE)
    d.rectangle((5, sh + 4, 43, sh + 4), fill=BLUE_DK)
    for k, px in enumerate((14, 34)):
        top = sh - 13
        b = top - 3 + k * 2
        for side in (-1, 1):
            leaf = [(px, b + 2), (px + side * 3, b - 6), (px + side * 9, b - 9 + k), (px + side * 11, b - 4), (px + side * 5, b + 2)]
            shape(d, leaf, LEAF)
            d.line((px + side * 3, b - 1, px + side * 8, b - 6 + k), fill=LEAF_HI)
        stroke(d, wb.line((px, top + 1), (px, b - 2), 0.2), INKA, 0.9)
        shape(d, [(px - 7, top), (px + 7, top), (px + 5, sh), (px - 5, sh)], TERRA)
        d.rectangle((px - 5, top + 4, px + 5, top + 6), fill=TERRA_DK)
    return img, ty


out = pathlib.Path(sys.argv[1])
out.mkdir(parents=True, exist_ok=True)
for name, make in (('screen', screen), ('vent', vent), ('pipes', pipes),
                   ('light', light), ('poster', poster), ('shelf_plants', shelf_plants)):
    img, ty = make()
    img.save(out / f'wall_deco_{name}.png')
    print(f'wall_deco_{name}', img.size, 'ty', ty, 'content top from face top', img.getbbox()[1] - ty)
