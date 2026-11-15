# Moon colony ground art: seamless room floors, outdoor regolith/crater and 16 habitat wall autotiles.
# Usage: colony_tiles.py <out_dir>
import sys, math, random, pathlib
from PIL import Image, ImageDraw
sys.path.insert(0, str(pathlib.Path(__file__).parent))  # -I leaves the script's folder off the path
from contrast import soften

BRUSH = 1.6
AMP = 1.4


class Wobble:
    def __init__(self, W, H, seed):
        self.W, self.H = W, H
        self.rng = random.Random(seed)
        self.cache = {}

    def line(self, p, q, amp=AMP):
        # Keyed modulo the tile so wrapped copies of an edge get identical wobble.
        if q < p:
            return self.line(q, p, amp)[::-1]
        key = (p[0] % self.W, p[1] % self.H, q[0] - p[0], q[1] - p[1])
        if key not in self.cache:
            self.cache[key] = (self.rng.uniform(-1, 1), self.rng.uniform(-1, 1) * 0.5)
        a, b = self.cache[key]
        dx, dy = q[0] - p[0], q[1] - p[1]
        L = math.hypot(dx, dy)
        nx, ny = -dy / L, dx / L
        n = int(L * 2)
        pts = []
        for i in range(n + 1):
            t = i / n
            o = amp * (a * math.sin(math.pi * t) + b * math.sin(2 * math.pi * t))
            pts.append((p[0] + dx * t + nx * o, p[1] + dy * t + ny * o))
        return pts

    def poly(self, corners, amp=AMP):
        pts = []
        for k in range(len(corners)):
            pts += self.line(corners[k], corners[(k + 1) % len(corners)], amp)
        return pts


def stroke(d, pts, colour, r=BRUSH):
    for x, y in pts:
        d.ellipse((x - r, y - r, x + r, y + r), fill=colour)


INK = (13, 13, 18)
LINE_R = 1.75      # LINE ~3.5 px
DETAIL_R = 1.2     # DETAIL ~2.4 px
CELL = 48


def grid_floor(W, H, cw, ch, base, alt, seam, alts, seed, stagger=0, extra=None):
    """Rectangular panels of cw x ch; rows shift by `stagger` px each row; `alts` picks darker panels."""
    wb = Wobble(W, H, seed)
    img = Image.new('RGB', (W, H), base)
    d = ImageDraw.Draw(img)
    rows, cols = H // ch, W // cw
    for j in range(-1, rows + 1):
        off = (j * stagger) % cw
        for i in range(-2, cols + 2):
            x0, y0 = i * cw + off, j * ch
            if alts(i % cols, j % rows):
                d.polygon(wb.poly([(x0, y0), (x0 + cw, y0), (x0 + cw, y0 + ch), (x0, y0 + ch)]), fill=alt)
            if extra:
                extra(d, wb, x0, y0, i % cols, j % rows)
    for j in range(-1, rows + 2):
        off = (j * stagger) % cw
        y0 = j * ch
        stroke(d, wb.line((-cw * 2, y0), (W + cw * 2, y0), 0.8), seam)
        for i in range(-2, cols + 2):
            x0 = i * cw + off
            stroke(d, wb.line((x0, y0), (x0, y0 + ch)), seam)
    return img


def row_floor(W, rows, base, alt, seam, alts, seed, extra=None):
    """Rows of (height, panel width, x offset) stacked into a W-wide tile; `alts(i, j)` picks darker panels."""
    H = sum(r[0] for r in rows)
    wb = Wobble(W, H, seed)
    img = Image.new('RGB', (W, H), base)
    d = ImageDraw.Draw(img)
    ys = [sum(r[0] for r in rows[:j]) for j in range(len(rows))]
    spans = [(ys[j % len(rows)] + (j // len(rows)) * H, rows[j % len(rows)], j % len(rows))
             for j in range(-1, len(rows) + 1)]
    for y0, (ch, cw, off), j in spans:
        for i in range(-2, W // cw + 2):
            x0 = i * cw + off
            if alts(i % (W // cw), j):
                d.polygon(wb.poly([(x0, y0), (x0 + cw, y0), (x0 + cw, y0 + ch), (x0, y0 + ch)]), fill=alt)
            if extra:
                extra(d, wb, x0, y0, cw, ch, i % (W // cw), j)
    for y0, (ch, cw, off), j in spans:
        stroke(d, wb.line((-W, y0), (W * 2, y0), 0.8), seam)
        for i in range(-2, W // cw + 2):
            x0 = i * cw + off
            stroke(d, wb.line((x0, y0), (x0, y0 + ch)), seam)
    return img


def greenhouse():
    base, alt, seam, slot = (170, 182, 138), (166, 178, 135), (158, 170, 128), (162, 175, 131)

    def slots(d, wb, x0, y0, cw, ch, i, j):
        if (i + j) % 3:
            return
        for s in range(2):
            y = y0 + 16 + s * 9
            stroke(d, wb.line((x0 + 18, y), (x0 + cw - 18, y), 0.5), slot, 1.0)

    rows = [(52, 84, 0), (52, 84, 42)]
    return row_floor(168, rows, base, alt, seam, lambda i, j: (i + j) % 2 == 1, 31, extra=slots)


def hab():
    base, alt, seam = (198, 172, 140), (194, 168, 136), (185, 159, 128)
    return grid_floor(240, 160, 120, 32, base, alt, seam, lambda i, j: (i * 3 + j * 2) % 5 == 0, 41, stagger=40)


def lab():
    base, alt, seam = (216, 224, 223), (212, 221, 220), (204, 213, 213)
    rows = [(56, 76, 0), (56, 76, 38)]
    return row_floor(152, rows, base, alt, seam, lambda i, j: (i, j) == (1, 0), 51)


def lifesupport():
    base, alt, seam, bolt, hi = (142, 150, 158), (139, 147, 155), (131, 138, 147), (132, 139, 148), (152, 160, 168)

    def bolts(d, wb, x0, y0, cw, ch, i, j):
        for cx, cy in ((x0 + 8, y0 + 8), (x0 + cw - 8, y0 + ch - 8)):
            d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=bolt)
            d.rectangle((cx - 1, cy - 2, cx, cy - 2), fill=hi)

    rows = [(76, 100, 0), (60, 100, 50)]
    return row_floor(200, rows, base, alt, seam, lambda i, j: (i + j) % 2 == 1, 61, extra=bolts)


def wrapped(W, H, x, y, r):
    """Yields copies of a feature at (x, y) shifted by the tile size wherever it crosses an edge."""
    for dx in (-W, 0, W):
        for dy in (-H, 0, H):
            if -r <= x + dx <= W + r and -r <= y + dy <= H + r:
                yield x + dx, y + dy


def blob(rng, cx, cy, r, n=10):
    phase = [rng.uniform(0, 6.28) for _ in range(2)]
    return [(cx + r * (1 + 0.18 * math.sin(2 * a + phase[0]) + 0.1 * math.sin(3 * a + phase[1])) * math.cos(a),
             cy + 0.8 * r * (1 + 0.18 * math.sin(2 * a + phase[0]) + 0.1 * math.sin(3 * a + phase[1])) * math.sin(a))
            for a in (k * 2 * math.pi / n for k in range(n))]


def ground(W, seed, base, patch_cols, pebble, pebble_dk, crater_dk, crater_hi, n_patch, n_peb, n_crater, glints=0, glint=None):
    rng = random.Random(seed)
    img = Image.new('RGB', (W, W), base)
    d = ImageDraw.Draw(img)
    for _ in range(n_patch):
        x, y, r, col = rng.uniform(0, W), rng.uniform(0, W), rng.uniform(10, 26), rng.choice(patch_cols)
        pts = blob(rng, 0, 0, r, 14)
        for px, py in wrapped(W, W, x, y, r * 1.4):
            d.polygon([(px + a, py + b) for a, b in pts], fill=col)
    for _ in range(n_crater):
        x, y, r = rng.uniform(0, W), rng.uniform(0, W), rng.uniform(4, 7)
        for px, py in wrapped(W, W, x, y, r + 3):
            # Light from above: the bowl's upper inner wall is in shadow, the lower rim catches light.
            d.ellipse((px - r - 1.5, py - r * 0.75 - 1, px + r + 1.5, py + r * 0.75 + 2), fill=crater_hi)
            d.ellipse((px - r, py - r * 0.75, px + r, py + r * 0.75), fill=crater_dk)
            d.ellipse((px - r + 1.5, py - r * 0.75 + 2.5, px + r - 1.5, py + r * 0.75), fill=base)
    for _ in range(n_peb):
        x, y, r = rng.uniform(0, W), rng.uniform(0, W), rng.choice((1.5, 2, 2, 2.5, 3))
        for px, py in wrapped(W, W, x, y, r + 2):
            d.ellipse((px - r, py - r * 0.8 + 1, px + r, py + r * 0.8 + 1), fill=pebble_dk)
            d.ellipse((px - r, py - r * 0.8, px + r, py + r * 0.8 - 0.5), fill=pebble)
    for _ in range(glints):
        x, y = rng.uniform(0, W), rng.uniform(0, W)
        for px, py in wrapped(W, W, x, y, 3):
            px, py = int(px), int(py)
            d.rectangle((px - 1, py, px + 1, py), fill=glint)
            d.rectangle((px, py - 1, px, py + 1), fill=glint)
    return img


def regolith():
    return ground(192, 71, (152, 152, 149), [(149, 149, 146), (155, 155, 151), (150, 150, 147)],
                  (166, 165, 161), (134, 134, 131), (138, 138, 135), (162, 161, 157), 14, 14, 2)


def crater():
    return ground(192, 81, (72, 80, 98), [(69, 77, 95), (75, 83, 101), (70, 78, 96)],
                  (84, 92, 110), (62, 69, 86), (63, 70, 87), (80, 88, 106), 12, 10, 2,
                  glints=3, glint=(132, 164, 184))


TOP, FACE = (0xbc, 0xd0, 0xcd), (0x86, 0xa1, 0xa2)


WALL_H = CELL * 2
CAP_Y0, CAP_Y1 = 28, 44        # cap band; a tile's y76 is the cap top of the tile below
CAP_X0, CAP_X1 = 16, 32


def wall(mask, seed):
    """Thin, tall wall: a 16 px cap (centre square plus arms toward each neighbour) over a 52 px front face."""
    import numpy as np
    up, right, down, left = (bool(mask & b) for b in (1, 2, 4, 8))
    P = 8
    W, H = CELL + 2 * P, WALL_H + 2 * P
    cap = np.zeros((H, W), bool)
    face = np.zeros((H, W), bool)

    def box(m, x0, y0, x1, y1):
        m[y0 + P:y1 + P, x0 + P:x1 + P] = True

    # Shapes are extended into the padding wherever they continue into a neighbour tile,
    # so the outline is only drawn on true outer edges and runs stay seamless.
    box(cap, CAP_X0, CAP_Y0, CAP_X1, CAP_Y1)
    if right:
        box(cap, CAP_X1, CAP_Y0, CELL + P, CAP_Y1)
        box(face, CAP_X1, CAP_Y1, CELL + P, WALL_H)
    if left:
        box(cap, -P, CAP_Y0, CAP_X0, CAP_Y1)
        box(face, -P, CAP_Y1, CAP_X0, WALL_H)
    if down:
        box(cap, CAP_X0, CAP_Y1, CAP_X1, WALL_H + P)
    else:
        box(face, CAP_X0, CAP_Y1, CAP_X1, WALL_H)
    if up:
        box(cap, CAP_X0, -P, CAP_X1, CAP_Y0)
    solid = cap | face

    yy, xx = np.mgrid[0:H, 0:W]
    R = 5

    def near(src, dst):
        """Per pixel of src: Euclidean, horizontal-only and vertical-only distance to the nearest dst pixel."""
        de = np.full((H, W), 99.0)
        dx = np.full((H, W), 99.0)
        dy = np.full((H, W), 99.0)
        dpad = np.pad(dst, R, constant_values=False)
        for oy in range(-R, R + 1):
            for ox in range(-R, R + 1):
                hit = dpad[R + oy:R + oy + H, R + ox:R + ox + W]
                dd = math.hypot(ox, oy)
                de = np.where(hit, np.minimum(de, dd), de)
                if oy == 0:
                    dx = np.where(hit, np.minimum(dx, abs(ox)), dx)
                if ox == 0:
                    dy = np.where(hit, np.minimum(dy, abs(oy)), dy)
        return de, dx, dy

    rng = random.Random(seed)
    a1, a2, b1, b2 = (rng.uniform(0, 0.9) for _ in range(4))
    tx, ty = xx - P, yy - P
    # Wobble on horizontal edges vanishes at tile borders; on vertical edges at the cap seams (y28 / y76).
    wh = a1 * np.sin(np.pi * tx / CELL) ** 2 + a2 * np.sin(2 * np.pi * tx / CELL) ** 2 * 0.5
    wv = b1 * np.sin(np.pi * (ty - CAP_Y0) / CELL) ** 2 + b2 * np.sin(2 * np.pi * (ty - CAP_Y0) / CELL) ** 2 * 0.5

    T = 3.5
    de, dx, dy = near(solid, ~solid)
    outer = solid & ((de < T) | (dy < T + wh) | (dx < T + wv))
    # Cap/face boundary: a 3 px line, mostly on the face side.
    fe, fx, fy = near(face, cap)
    ce, cx, cy = near(cap, face)
    inner = (face & ((fe < 2.5) | (fy < 2.5 + wh * 0.6) | (fx < 2.5 + wv * 0.6))) | (cap & (ce < 1.5))

    rgba = np.zeros((H, W, 4), np.uint8)
    top = soften(Image.new('RGB', (1, 1), TOP)).getpixel((0, 0))
    fc = soften(Image.new('RGB', (1, 1), FACE)).getpixel((0, 0))
    rgba[cap] = top + (255,)
    rgba[face] = fc + (255,)
    # Vertical panel seam down the middle of the face.
    seam = face & (left and right and not down) & (np.abs(tx - CELL / 2 + 0.5) < 1.2) & (ty > CAP_Y1 + 2) & (ty < WALL_H - 3)
    rgba[seam] = INK + (255,)
    rgba[outer | inner] = INK + (255,)
    return Image.fromarray(rgba[P:P + WALL_H, P:P + CELL], 'RGBA')


SILL_LIT, SILL_DK, SILL_BOLT, SILL_EDGE = (0xa8, 0xb2, 0xb8), (0x7c, 0x86, 0x8e), (0x6a, 0x73, 0x7b), (0xe8, 0xc2, 0x4a)


def sill(L=96, T=12):
    """Metal threshold strip running left-right, L long and T thick; rotate 90 for vertical doorways."""
    img = Image.new('RGBA', (L, T), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, L - 1, T - 1), 3, fill=SILL_LIT + (255,))
    d.rectangle((2, T - 5, L - 3, T - 2), fill=SILL_DK + (255,))
    d.rectangle((3, 3, L - 4, 3), fill=SILL_EDGE + (255,))
    for cx in (8, L / 2, L - 9):
        d.ellipse((cx - 1.5, T / 2 - 1, cx + 1.5, T / 2 + 2), fill=SILL_BOLT + (255,))
    img = soften(img)
    d = ImageDraw.Draw(img)
    e = DETAIL_R
    wb = Wobble(10 ** 6, 10 ** 6, 7)
    stroke(d, wb.poly([(e, e), (L - 1 - e, e), (L - 1 - e, T - 1 - e), (e, T - 1 - e)], 0.3), INK, DETAIL_R)
    return img


out = pathlib.Path(sys.argv[1])
out.mkdir(parents=True, exist_ok=True)
for name, make in (('floor_greenhouse', greenhouse), ('floor_hab', hab), ('floor_lab', lab),
                   ('floor_lifesupport', lifesupport), ('regolith', regolith), ('crater', crater)):
    img = soften(make())
    img.save(out / f'{name}.png')
    print(name, img.size)
for m in range(16):
    wall(m, 100 + m).save(out / f'wall_{m}.png')
print('wall_0..15', (CELL, WALL_H))
h = sill()
h.save(out / 'sill_h.png')
h.transpose(Image.Transpose.ROTATE_90).save(out / 'sill_v.png')
print('sill_h', h.size, 'sill_v', h.size[::-1])
