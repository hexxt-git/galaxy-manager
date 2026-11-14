# Renders scripts/map/station_map.gd's layout to a PNG (1 art px = 1 px) without running the game.
# usage: .venv/bin/python -I map_preview.py OUT.png [zoom]
import sys, re, json, pathlib
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
src = (ROOT / 'scripts/map/station_map.gd').read_text()
ART = ROOT / 'assets/art'

def table(name):
    body = re.search(r'const %s := \[(.*?)\n\]' % name, src, re.S).group(1)
    body = re.sub(r'Vector2\(([^)]*)\)', r'[\1]', body).replace('true', 'true').replace('false', 'false')
    body = re.sub(r'"(\w+)":', r'"\1":', body)
    return json.loads('[' + re.sub(r',\s*$', '', body.strip()) + ']')

def const(name):
    return float(re.search(r'const %s := (\d+)' % name, src).group(1))

ROOMS, LAYOUT, STATIONS = table('ROOMS'), table('LAYOUT'), table('STATIONS')
SEG, WO, ROWS, FACE, CW, END_W, GAP, SIDE_DOOR = (const(n) for n in
    ('SEG', 'WALL_ORIGIN_Y', 'WALL_ROWS', 'WALL_FACE', 'CORNER_W', 'END_W', 'MERGE_GAP', 'SIDE_DOOR'))
KIND_FILL = ['', 'wall_fill_a', 'wall_fill_b', 'wall_v']
KIND_END = ['wall_corner', 'wall_corner_a', 'wall_corner_b', '']
ORIG = {m.group(1): (float(m.group(2)), float(m.group(3))) for m in
        re.finditer(r'"(\w+)": \{"origin": Vector2\(([\d.]+), ([\d.]+)\)', src)}
ORIG['workstation'] = (43, 74)

minx = min(r['x'] for r in ROOMS) - 60; maxx = max(r['x'] + r['segs'] * SEG for r in ROOMS) + 60
miny = min(r['back'] for r in ROOMS) - 160; maxy = max(r['front'] for r in ROOMS) + 40
img = Image.new('RGBA', (int(maxx - minx), int(maxy - miny)), (18, 20, 28, 255))
tex = {}
def T(n):
    if n not in tex: tex[n] = Image.open(ART / ('props/%s.png' % n if '/' not in n else n[1:] + '.png')).convert('RGBA')
    return tex[n]
def put(im, x, y):
    img.alpha_composite(im, (int(round(x - minx)), int(round(y - miny))))

layers = []  # (z, sort_y, image, x, y)
strips, walls = [], {}
def floor(name, x0, top, w, h):
    fl = T('/' + name); tile = Image.new('RGBA', (int(w), int(h)))
    for ty in range(-fl.height, tile.height + fl.height, fl.height):
        for tx in range(-fl.width, tile.width + fl.width, fl.width):
            tile.alpha_composite(fl, (int(tx - (x0 % fl.width)), int(ty - (top % fl.height))))
    layers.append((-10, 0, tile, x0, top))
for r in ROOMS:
    x0, x1 = r['x'], r['x'] + r['segs'] * SEG
    top = r['back'] - WO if r['back_wall'] else r['back']
    floor(r['floor'], x0, top, x1 - x0, r['front'] - top)
    side = {'left': [], 'right': []}
    for d in r.get('side_doors', []): side[d[0]].append(d[1])
    strips += [[x0 - CW, x0, r['back'], r['front'], side['left'], {'right': r['floor']}],
               [x1, x1 + CW, r['back'], r['front'], side['right'], {'left': r['floor']}]]
    if r['back_wall']: walls.setdefault(r['back'], []).append((x0, x1, []))
    walls.setdefault(r['front'], []).append((x0, x1, r['doors']))

def tiled(n, x, y, w, h):
    im = T(n); out = Image.new('RGBA', (int(w), int(h)))
    for yy in range(0, int(h), im.height):
        for xx in range(0, int(w), im.width): out.alpha_composite(im, (xx, yy))
    return out

merged = []
for s in sorted(strips, key=lambda s: s[0]):
    m = next((m for m in merged if m[2:4] == s[2:4] and s[0] - m[1] <= GAP), None)
    if m: m[1] = max(m[1], s[1]); m[4] = m[4] + s[4]; m[5] = {**m[5], **s[5]}
    else: merged.append(list(s))
pieces, door_lines = [], []
for x0, x1, top, bot, doors, fls in merged:
    for y0 in sorted(doors):
        y1 = y0 + SIDE_DOOR + WO; mid = (x0 + x1) / 2
        left = fls.get('left', fls.get('right')); right = fls.get('right', left)
        pieces.append([x0, x1, top, y0])
        floor(left, x0, y0 - WO, mid - x0, y1 - y0 + WO); floor(right, mid, y0 - WO, x1 - mid, y1 - y0 + WO)
        door_lines += [y0, y1]; top = y1
    pieces.append([x0, x1, top, bot])
merged = pieces
for x0, x1, top, bot in merged:
    h = bot - FACE - top
    for n, x, w in (('wall_v', x0, x1 - x0), ('wall_ink', x0 - 2, 4), ('wall_ink', x1 - 2, 4)):
        layers.append((-5, 0, tiled(n, x, top, w, h), x, top))
for y, ws in walls.items():
    for x0, x1, doors in ws:
        i = 0; segs = int((x1 - x0) / SEG)
        while i < segs:
            n = 'wall_door' if i in doors else 'wall_h'
            layers.append((0, y, T(n), x0 + i * SEG, y - WO)); i += 2 if n == 'wall_door' else 1
for y in door_lines:
    if y not in walls: walls[y] = []
for y, ws in walls.items():
    spans = [(a, b, 0) for a, b, _ in ws]
    spans += [(s[0], s[1], 1) for s in merged if s[3] == y] + [(s[0], s[1], 2) for s in merged if s[2] == y]
    cuts = sorted({x for sp in spans for x in sp[:2]})
    runs = [[cuts[0], cuts[0], -1]]
    for a, b in zip(cuts, cuts[1:]):
        kind = -1
        for sp in spans:
            if sp[0] < (a + b) / 2 < sp[1]: kind = max(kind, 0) | sp[2]
        if kind == runs[-1][2]: runs[-1][1] = b
        else: runs.append([a, b, kind])
    runs.append([cuts[-1], cuts[-1], -1])
    top = y - WO
    for i in range(1, len(runs) - 1):
        a, b, k = runs[i]
        if k <= 0: continue
        if k != 3:
            a += END_W if runs[i - 1][2] == -1 else 0
            b -= END_W if runs[i + 1][2] == -1 else 0
        if b <= a: continue
        layers.append((0, y, tiled(KIND_FILL[k], a, top, b - a, ROWS), a, top))
    for (_, e, l), (_, _, r) in zip(runs, runs[1:]):
        if l == -1 or r == -1:
            k = r if l == -1 else l
            if k == 3: layers.append((0, y, tiled('wall_ink', 0, 0, 4, ROWS), e - 2, top))
            elif k != -1:
                c = T(KIND_END[k])
                if r == -1: layers.append((0, y, c.transpose(Image.FLIP_LEFT_RIGHT), e - (c.width - 2), top))
                else: layers.append((0, y, c, e - 2, top))
            continue
        if (l ^ r) & 1: layers.append((0, y, tiled('wall_ink', 0, 0, 4, 4), e - 2, top))
        if (l ^ r) & 2: layers.append((0, y, tiled('wall_ink', 0, 0, 4, FACE + ROWS - WO), e - 2, y - FACE))
for n, (x, y) in LAYOUT:
    ox, oy = ORIG[n]
    layers.append((-8 if n == 'vent' else 0, y, T(n), x - ox, y - oy))
for _, (x, y) in STATIONS:
    layers.append((0, y, T('workstation'), x - 43, y - 74))
ch = Image.open(ART / 'character/character.png').convert('RGBA')
px, py = [float(v) / 2 for v in re.search(r'position = Vector2\(([\d.]+), ([\d.]+)\)\nmotion_mode', (ROOT / 'scenes/main.tscn').read_text()).groups()]
layers.append((0, py, ch, px - 34, py - 69))
for z, sy, im, x, y in sorted(layers, key=lambda l: (l[0], l[1])):
    put(im, x, y)
zoom = int(sys.argv[2]) if len(sys.argv) > 2 else 1
img.resize((img.width * zoom, img.height * zoom), Image.NEAREST).save(sys.argv[1])
print(img.size)
