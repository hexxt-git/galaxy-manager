# Seamless floor tile: diamond checker with wobbly round-brush grout, drawn straight at art-pixel size.
import sys, math, random, pathlib
from PIL import Image, ImageDraw

out = pathlib.Path(sys.argv[1])
DENSITY = 0.75                       # character ~70 art px tall
HS, VS = round(52 * DENSITY), round(46 * DENSITY)
NX, NY = 3, 3                        # periods per tile, so the wobble doesn't visibly repeat
W, H = 2 * HS * NX, 2 * VS * NY
A, B, GROUT = (220, 220, 210), (199, 199, 187), (194, 194, 182)
BRUSH = 1.6                          # brush radius in art px -> ~3 px lines
AMP = 1.4

rng = random.Random(4)
edge_cache = {}

def edge(p, q):
    # Lattice edges are keyed modulo the tile so wrapped copies get identical wobble.
    key = tuple(sorted([(p[0] % W, p[1] % H, q[0] - p[0], q[1] - p[1])]))
    if key not in edge_cache:
        edge_cache[key] = (rng.uniform(-AMP, AMP), rng.uniform(-AMP, AMP) * 0.5, rng.uniform(0, 1))
    a, b, _ = edge_cache[key]
    dx, dy = q[0] - p[0], q[1] - p[1]
    L = math.hypot(dx, dy)
    nx, ny = -dy / L, dx / L
    pts = []
    n = int(L * 2)
    for i in range(n + 1):
        t = i / n
        o = a * math.sin(math.pi * t) + b * math.sin(2 * math.pi * t)
        pts.append((p[0] + dx * t + nx * o, p[1] + dy * t + ny * o))
    return pts

def vertices():
    # Diamond vertices sit on a grid of (HS, VS) where i + j is odd.
    for j in range(-2, 2 * NY + 3):
        for i in range(-2, 2 * NX + 3):
            if (i + j) % 2:
                yield i, j

img = Image.new('RGB', (W, H), A)
d = ImageDraw.Draw(img)
P = lambda i, j: (i * HS, j * VS)

# B diamonds are centred on (i, j) with i, j both even.
for j in range(-2, 2 * NY + 3, 2):
    for i in range(-2, 2 * NX + 3, 2):
        corners = [P(i, j - 1), P(i + 1, j), P(i, j + 1), P(i - 1, j)]
        poly = []
        for k in range(4):
            a, b = corners[k], corners[(k + 1) % 4]
            poly += edge(a, b) if a <= b else edge(b, a)[::-1]
        d.polygon(poly, fill=B)

for i, j in vertices():
    for di, dj in ((1, 1), (1, -1)):
        a, b = P(i, j), P(i + di, j + dj)
        for x, y in edge(a, b) if a <= b else edge(b, a):
            d.ellipse((x - BRUSH, y - BRUSH, x + BRUSH, y + BRUSH), fill=GROUT)

img.save(out)
print(img.size)
