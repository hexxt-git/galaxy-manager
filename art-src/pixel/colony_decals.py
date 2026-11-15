# Flat, non-blocking floor decals for the colony rooms, scattered at random in game.
# Usage: colony_decals.py <out_dir>  ->  <out_dir>/<room>_<thing>.png
import sys, math, random, pathlib
from PIL import Image, ImageDraw
sys.path.insert(0, str(pathlib.Path(__file__).parent))  # -I leaves the script's folder off the path
from contrast import soften

# colony_tiles.py runs its export at import time, so only its helper definitions are executed.
_src = (pathlib.Path(__file__).with_name('colony_tiles.py')).read_text()
_ns = {'__file__': __file__}
exec(_src.split('\nout = pathlib')[0], _ns)
Wobble, stroke = _ns['Wobble'], _ns['stroke']

GH = dict(BASE=(170, 182, 138), SEAM=(150, 163, 121), SOIL=(128, 104, 78), SOIL2=(110, 88, 66),
          WATER=(150, 176, 158), WATER2=(176, 198, 176), LEAF=(118, 156, 84), LEAF2=(98, 134, 70), LEAFY=(176, 168, 92),
          HOSE=(86, 140, 96), HOSE2=(64, 112, 76), BRASS=(190, 160, 90))
HAB = dict(BASE=(198, 172, 140), SEAM=(164, 138, 110), RUG=(104, 132, 160), RUG2=(86, 112, 140), RUGB=(186, 150, 92),
           SCUFF=(178, 152, 122), CABLE=(70, 74, 86), CABLE2=(98, 102, 114), PLUG=(196, 196, 190),
           MAT=(156, 104, 76), MAT2=(136, 88, 64))
LAB = dict(BASE=(216, 224, 223), SEAM=(199, 209, 209), COVER=(196, 206, 206), COVER2=(182, 193, 194),
           SPILL=(160, 204, 196), SPILL2=(138, 190, 184), CRACK=(176, 188, 189), TAPE=(132, 188, 183))
LS = dict(BASE=(142, 150, 158), SEAM=(120, 127, 136), OIL=(118, 125, 134), OIL2=(102, 109, 118), SHEEN=(150, 146, 168),
          GRATE=(104, 111, 120), DEEP=(80, 86, 96), PLATE=(156, 163, 170), BOLT=(122, 129, 138),
          YELLOW=(190, 166, 96), DARK=(122, 118, 102))


def canvas(w, h):
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def rgba(c):
    return c + (255,)


def blob(cx, cy, r, rng, k=0.25, n=48, squash=1.0):
    h = [(rng.uniform(-k, k), rng.uniform(0, 6.3), m) for m in (2, 3, 5)]
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        rr = r * (1 + sum(a * math.sin(m * t + ph) for a, ph, m in h))
        pts.append((cx + rr * math.cos(t), cy + squash * rr * math.sin(t)))
    return pts


def polyline(wb, pts, amp):
    out = []
    for p, q in zip(pts, pts[1:]):
        out += wb.line(p, q, amp)
    return out


def trim(img):
    return img.crop(img.getbbox())


def wobbly_rect(wb, x0, y0, x1, y1, amp=1.0):
    return wb.poly([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], amp)


def curve(pts, steps=10):
    """Catmull-Rom through the points, so cables and hoses bend smoothly."""
    out = []
    P = [pts[0]] + pts + [pts[-1]]
    for k in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[k - 1], P[k], P[k + 1], P[k + 2]
        for s in range(steps):
            t = s / steps
            out.append(tuple(0.5 * (2 * p1[c] + (-p0[c] + p2[c]) * t + (2 * p0[c] - 5 * p1[c] + 4 * p2[c] - p3[c]) * t * t
                                    + (-p0[c] + 3 * p1[c] - 3 * p2[c] + p3[c]) * t ** 3) for c in (0, 1)))
    return out + [pts[-1]]


# --- greenhouse ---

def greenhouse_soil():
    img, d = canvas(44, 30)
    rng = random.Random(3)
    d.polygon(blob(18, 15, 11, rng, 0.22, squash=0.7), fill=rgba(GH['SOIL']))
    d.polygon(blob(17, 13, 5, rng, 0.25, squash=0.7), fill=rgba(GH['SOIL2']))
    for x, y, r in ((33, 10, 2), (37, 18, 1.5), (30, 22, 2.2), (6, 22, 1.4), (40, 13, 1.2)):
        d.ellipse((x - r, y - r * 0.8, x + r, y + r * 0.8), fill=rgba(GH['SOIL']))
    return trim(img)


def greenhouse_puddle():
    img, d = canvas(44, 28)
    rng = random.Random(8)
    d.polygon(blob(20, 14, 13, rng, 0.18, squash=0.6), fill=rgba(GH['WATER']))
    d.polygon(blob(36, 19, 4, rng, 0.15, squash=0.6), fill=rgba(GH['WATER']))
    stroke(d, [(12 + t, 10 - t * 0.15) for t in range(8)], rgba(GH['WATER2']), 1.0)
    d.rectangle((23, 9, 24, 9), fill=rgba(GH['WATER2']))
    return trim(img)


def leaf(d, cx, cy, ang, L, fill, vein):
    ca, sa = math.cos(ang), math.sin(ang)
    pts = []
    for k in range(17):
        t = k / 16
        w = math.sin(math.pi * t) * L * 0.32
        pts.append((t * L, w))
    pts += [(t, -w) for t, w in reversed(pts[1:-1])]
    rot = [(cx + x * ca - y * sa, cy + (x * sa + y * ca) * 0.75) for x, y in pts]
    d.polygon(rot, fill=rgba(fill))
    d.line([(cx, cy), (cx + L * 0.8 * ca, cy + L * 0.8 * sa * 0.75)], fill=rgba(vein), width=1)


def greenhouse_leaves():
    img, d = canvas(40, 30)
    leaf(d, 4, 14, -0.3, 13, GH['LEAF'], GH['LEAF2'])
    leaf(d, 20, 6, 0.9, 11, GH['LEAFY'], GH['SOIL'])
    leaf(d, 18, 24, -0.6, 12, GH['LEAF2'], GH['HOSE2'])
    leaf(d, 30, 16, 2.6, 9, GH['LEAF'], GH['LEAF2'])
    return trim(img)


def greenhouse_hose():
    img, d = canvas(64, 44)
    pts = []
    for k in range(120):
        t = k / 119
        a = t * 2.6 * 2 * math.pi
        r = 17 - t * 9
        pts.append((26 + r * math.cos(a), 21 + 0.72 * r * math.sin(a)))
    tail = curve([(43, 21), (50, 28), (56, 36), (62, 40)])
    path = tail[::-1] + pts
    shadow = [(x, y + 1.5) for x, y in path]
    stroke(d, shadow, rgba(GH['SEAM']), 2.6)
    stroke(d, path, rgba(GH['HOSE2']), 2.4)
    stroke(d, [(x, y - 0.6) for x, y in path], rgba(GH['HOSE']), 1.5)
    d.rectangle((59, 38, 63, 42), fill=rgba(GH['BRASS']))
    return trim(img)


# --- hab ---

def hab_scuff():
    img, d = canvas(40, 20)
    wb = Wobble(999, 999, 23)
    for p, q in (((3, 14), (22, 6)), ((10, 17), (34, 9)), ((24, 15), (37, 11))):
        stroke(d, wb.line(p, q, 1.6), rgba(HAB['SCUFF']), 0.6)
    return trim(img)


def hab_mat():
    img, d = canvas(44, 30)
    wb = Wobble(999, 999, 27)
    body = wobbly_rect(wb, 4, 4, 40, 26, 0.6)
    d.polygon(body, fill=rgba(HAB['MAT']))
    for y in (10, 15, 20):
        stroke(d, wb.line((9, y), (35, y), 0.4), rgba(HAB['MAT2']), 0.7)
    for x in range(6, 40, 4):
        d.rectangle((x, 1, x, 3), fill=rgba(HAB['MAT2']))
        d.rectangle((x, 27, x, 29), fill=rgba(HAB['MAT2']))
    return trim(img)


# --- lab ---

def lab_cable_cover():
    img, d = canvas(76, 16)
    wb = Wobble(999, 999, 53)
    body = wb.poly([(4, 3), (72, 3), (74, 8), (72, 13), (4, 13), (2, 8)], 0.6)
    d.polygon(body, fill=rgba(LAB['COVER']))
    stroke(d, body, rgba(LAB['COVER2']), 1.0)
    stroke(d, wb.line((8, 8), (68, 8), 0.4), rgba(LAB['SEAM']), 0.6)
    for x in (14, 38, 62):
        d.rectangle((x, 7, x + 1, 8), fill=rgba(LAB['TAPE']))
    return trim(img)


def lab_spill():
    img, d = canvas(38, 28)
    rng = random.Random(33)
    d.polygon(blob(16, 14, 11, rng, 0.24, squash=0.7), fill=rgba(LAB['SPILL']))
    d.polygon(blob(15, 13, 5, rng, 0.2, squash=0.7), fill=rgba(LAB['SPILL2']))
    for x, y, r in ((31, 8, 2.2), (34, 18, 1.5), (27, 23, 1.8)):
        d.ellipse((x - r, y - r * 0.8, x + r, y + r * 0.8), fill=rgba(LAB['SPILL']))
    return trim(img)


def lab_crack():
    img, d = canvas(42, 30)
    wb = Wobble(999, 999, 37)
    stroke(d, polyline(wb, [(3, 26), (12, 20), (18, 21), (27, 12), (39, 5)], 0.8), rgba(LAB['CRACK']), 0.6)
    stroke(d, polyline(wb, [(18, 21), (24, 26), (30, 27)], 0.6), rgba(LAB['CRACK']), 0.6)
    stroke(d, polyline(wb, [(27, 12), (28, 5)], 0.5), rgba(LAB['CRACK']), 0.6)
    return trim(img)


def lab_tape():
    img, d = canvas(64, 44)
    wb = Wobble(999, 999, 39)
    x0, y0, x1, y1, L = 4, 4, 60, 40, 9
    for (cx, cy, sx, sy) in ((x0, y0, 1, 1), (x1, y0, -1, 1), (x1, y1, -1, -1), (x0, y1, 1, -1)):
        stroke(d, wb.line((cx, cy), (cx + sx * L, cy), 0.3), rgba(LAB['TAPE']), 1.5)
        stroke(d, wb.line((cx, cy), (cx, cy + sy * L * 0.8), 0.3), rgba(LAB['TAPE']), 1.5)
    return trim(img)


# --- life support ---

def lifesupport_oil():
    img, d = canvas(40, 30)
    rng = random.Random(41)
    d.polygon(blob(18, 15, 12, rng, 0.2, squash=0.7), fill=rgba(LS['OIL']))
    d.polygon(blob(19, 14, 6, rng, 0.2, squash=0.7), fill=rgba(LS['OIL2']))
    d.polygon(blob(34, 22, 3, rng, 0.1, squash=0.7), fill=rgba(LS['OIL']))
    d.rectangle((15, 11, 17, 11), fill=rgba(LS['SHEEN']))
    return trim(img)


def lifesupport_grate():
    img, d = canvas(44, 32)
    wb = Wobble(999, 999, 43)
    frame = wobbly_rect(wb, 2, 2, 41, 29, 0.7)
    d.polygon(frame, fill=rgba(LS['GRATE']))
    stroke(d, frame, rgba(LS['SEAM']), 1.0)
    for x in range(9, 38, 5):
        stroke(d, wb.line((x, 7), (x, 24), 0.3), rgba(LS['DEEP']), 0.8)
    return trim(img)


def lifesupport_trench():
    img, d = canvas(88, 24)
    wb = Wobble(999, 999, 47)
    body = wobbly_rect(wb, 2, 3, 86, 21, 0.7)
    d.polygon([(x, y + 1.5) for x, y in body], fill=rgba(LS['SEAM']))
    d.polygon(body, fill=rgba(LS['PLATE']))
    stroke(d, body, rgba(LS['SEAM']), 0.9)
    for x in (30, 58):
        stroke(d, wb.line((x, 4), (x, 20), 0.3), rgba(LS['SEAM']), 0.7)
    for x in (7, 24, 36, 52, 64, 81):
        for y in (8, 16):
            d.ellipse((x - 1.5, y - 1.5, x + 1.5, y + 1.5), fill=rgba(LS['BOLT']))
    return trim(img)


def lifesupport_hazard():
    S, T = 48, 30
    img, d = canvas(S, T)
    wb = Wobble(999, 999, 49)
    outline = wobbly_rect(wb, 3, 3, S - 3, T - 3, 0.8)
    stripes, sd = canvas(S, T)
    sd.rectangle((0, 0, S, T), fill=rgba(LS['DARK']))
    for k in range(-T, S + T, 12):
        sd.polygon(wb.poly([(k, 0), (k + 6, 0), (k + 6 - T, T), (k - T, T)], 0.6), fill=rgba(LS['YELLOW']))
    mask = Image.new('L', (S, T), 0)
    ImageDraw.Draw(mask).polygon(outline, fill=255)
    img.paste(stripes, (0, 0), mask)
    stroke(d, outline, rgba(LS['SEAM']), 1.0)
    return trim(img)


DECALS = [greenhouse_soil, greenhouse_puddle, greenhouse_leaves, greenhouse_hose,
          hab_scuff, hab_mat,
          lab_cable_cover, lab_spill, lab_crack, lab_tape,
          lifesupport_oil, lifesupport_grate, lifesupport_trench, lifesupport_hazard]

if __name__ == '__main__':
    out = pathlib.Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for make in DECALS:
        img = soften(make())
        img.save(out / f'{make.__name__}.png')
        print(make.__name__, img.size)
