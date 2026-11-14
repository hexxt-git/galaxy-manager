# Seamless storage and control room floors, same wobbly round-brush style and density as floor.py.
# Usage: room_floors.py <out_dir>  ->  <out_dir>/storage.png, <out_dir>/control.png
import sys, math, random, pathlib
from PIL import Image, ImageDraw
sys.path.insert(0, str(pathlib.Path(__file__).parent))  # -I leaves the script's folder off the path
from contrast import soften, grade

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


def storage():
    S = 56
    NX, NY = 4, 4
    W, H = S * NX, S * NY
    TILE, ALT, SEAM, STRIPE = (150, 160, 170), (143, 153, 164), (116, 124, 136), (206, 176, 84)
    ALT_TILES = {(0, 2), (2, 0), (3, 3), (1, 1)}
    STRIPE_COL, STRIPE_ROW = 1, 2
    wb = Wobble(W, H, 11)
    img = Image.new('RGB', (W, H), TILE)
    d = ImageDraw.Draw(img)
    P = lambda i, j: (i * S, j * S)
    for j in range(-1, NY + 1):
        for i in range(-1, NX + 1):
            if (i % NX, j % NY) in ALT_TILES:
                d.polygon(wb.poly([P(i, j), P(i + 1, j), P(i + 1, j + 1), P(i, j + 1)]), fill=ALT)
    stripes = []
    for j in range(-1, NY + 2):
        for i in range(-1, NX + 2):
            for q, yellow in ((P(i + 1, j), j % NY == STRIPE_ROW), (P(i, j + 1), i % NX == STRIPE_COL)):
                pts = wb.line(P(i, j), q)
                if yellow:
                    stripes.append(pts)
                else:
                    stroke(d, pts, SEAM)
    for pts in stripes:
        stroke(d, pts, STRIPE, 2.2)
    return img


def control():
    PW, PH = 117, 99
    NX, NY = 2, 2
    W, H = PW * NX, PH * NY
    BASE, BAND, SEAM, INSET = (120, 116, 96), (106, 102, 84), (84, 81, 66), (92, 89, 73)
    WIDE = {(1, 0)}
    VENT = (0, 1)
    wb = Wobble(W, H, 23)
    img = Image.new('RGB', (W, H), BAND)
    d = ImageDraw.Draw(img)
    for j in range(-1, NY + 1):
        for i in range(-1, NX + 1):
            x0, y0 = i * PW, j * PH
            k = 11 if (i % NX, j % NY) in WIDE else 8
            inner = [(x0 + k, y0 + k), (x0 + PW - k, y0 + k), (x0 + PW - k, y0 + PH - k), (x0 + k, y0 + PH - k)]
            pts = wb.poly(inner, 1.0)
            d.polygon(pts, fill=BASE)
            stroke(d, pts, INSET, 1.0)
            for cx, cy in ((x0 + k + 4, y0 + k + 4), (x0 + PW - k - 4, y0 + k + 4), (x0 + PW - k - 4, y0 + PH - k - 4), (x0 + k + 4, y0 + PH - k - 4)):
                d.rectangle((cx - 1, cy - 1, cx, cy), fill=SEAM)
            if (i % NX, j % NY) == VENT:
                vx, vy = x0 + PW // 2 - 18, y0 + PH // 2 - 12
                for s in range(5):
                    stroke(d, wb.line((vx, vy + s * 6), (vx + 36, vy + s * 6), 0.6), SEAM, 1.2)
    for j in range(-1, NY + 2):
        for i in range(-1, NX + 2):
            p = (i * PW, j * PH)
            stroke(d, wb.line(p, ((i + 1) * PW, j * PH)), SEAM)
            stroke(d, wb.line(p, (i * PW, (j + 1) * PH)), SEAM)
    return img


out = pathlib.Path(sys.argv[1])
out.mkdir(parents=True, exist_ok=True)
for name, make in (('storage', storage), ('control', control)):
    img = make()
    grade(soften(img), name).save(out / f'{name}.png')
    print(name, img.size)
