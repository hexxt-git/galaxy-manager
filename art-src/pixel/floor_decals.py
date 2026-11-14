# Small floor-variation decals in each floor's palette, scattered at random in game.
# Usage: floor_decals.py <out_dir>  ->  <out_dir>/<floor>_<thing>.png
# storage_hatch and storage_hazard are 56x56 cells that snap to the storage tile grid (period 56, offset 0).
import sys, math, random, pathlib
from PIL import Image, ImageDraw
sys.path.insert(0, str(pathlib.Path(__file__).parent))  # -I leaves the script's folder off the path
from contrast import soften, grade

# room_floors.py runs its export at import time, so only its helper definitions are executed.
_src = (pathlib.Path(__file__).with_name('room_floors.py')).read_text()
_ns = {'__file__': __file__}
exec(_src.split('\nout = pathlib')[0], _ns)
Wobble, stroke = _ns['Wobble'], _ns['stroke']

CAF = dict(A=(220, 220, 210), B=(199, 199, 187), GROUT=(194, 194, 182),
           DARK=(178, 178, 166), DEEP=(168, 168, 157), STAIN=(206, 203, 183), STAIN2=(193, 190, 170))
STO = dict(TILE=(150, 160, 170), ALT=(143, 153, 164), SEAM=(116, 124, 136), STRIPE=(206, 176, 84), HAZY=(186, 162, 92),
           LIGHT=(160, 170, 179), DARK=(102, 110, 121), HAZ=(122, 130, 141), OIL=(118, 125, 135), OIL2=(105, 112, 122))
CTL = dict(BASE=(120, 116, 96), BAND=(106, 102, 84), SEAM=(84, 81, 66), INSET=(92, 89, 73),
           LIGHT=(130, 126, 105), DEEP=(74, 71, 58))


def canvas(w, h):
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def rgba(c):
    return c + (255,)


def blob(cx, cy, r, rng, k=0.25, n=48):
    # Closed wobbly outline from a few random harmonics.
    h = [(rng.uniform(-k, k), rng.uniform(0, 6.3), m) for m in (2, 3, 5)]
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        rr = r * (1 + sum(a * math.sin(m * t + ph) for a, ph, m in h))
        pts.append((cx + rr * math.cos(t), cy + rr * math.sin(t)))
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


# --- cafeteria ---

def cafeteria_crack():
    img, d = canvas(40, 30)
    wb = Wobble(999, 999, 31)
    main = [(3, 25), (12, 19), (17, 20), (25, 12), (36, 6)]
    stroke(d, polyline(wb, main, 0.8), rgba(CAF['DEEP']), 0.6)
    stroke(d, polyline(wb, [(17, 20), (22, 25), (27, 26)], 0.6), rgba(CAF['DEEP']), 0.6)
    stroke(d, polyline(wb, [(25, 12), (26, 6)], 0.5), rgba(CAF['DEEP']), 0.6)
    return trim(img)


def cafeteria_drain():
    img, d = canvas(20, 20)
    rng = random.Random(5)
    wb = Wobble(999, 999, 7)
    ring = blob(10, 10, 8, rng, 0.03)
    d.polygon(ring, fill=rgba(CAF['GROUT']))
    stroke(d, ring, rgba(CAF['DARK']), 1.0)
    for y in (6, 10, 14):
        half = 5 if y == 10 else 4
        stroke(d, wb.line((10 - half, y), (10 + half, y), 0.4), rgba(CAF['DEEP']), 0.8)
    return trim(img)


def cafeteria_scuff():
    img, d = canvas(36, 18)
    wb = Wobble(999, 999, 13)
    for p, q in (((3, 12), (20, 6)), ((9, 15), (30, 8)), ((22, 13), (33, 10))):
        stroke(d, wb.line(p, q, 1.6), rgba(CAF['DARK']), 0.6)
    return trim(img)


def cafeteria_stain():
    img, d = canvas(30, 24)
    rng = random.Random(9)
    d.polygon(blob(14, 12, 10, rng, 0.18), fill=rgba(CAF['STAIN2']))
    d.polygon(blob(13, 11, 5.5, rng, 0.2), fill=rgba(CAF['STAIN']))
    d.polygon(blob(26, 19, 2.2, rng, 0.1), fill=rgba(CAF['STAIN2']))
    return trim(img)


# --- storage (tile period 56) ---

S = 56


def storage_hatch():
    img, d = canvas(S, S)
    wb = Wobble(999, 999, 41)
    plate = wobbly_rect(wb, 7, 7, S - 7, S - 7)
    d.polygon(plate, fill=rgba(STO['LIGHT']))
    stroke(d, plate, rgba(STO['SEAM']), 1.2)
    inner = wobbly_rect(wb, 13, 13, S - 13, S - 13, 0.7)
    stroke(d, inner, rgba(STO['ALT']), 0.6)
    for cx, cy in ((11, 11), (S - 12, 11), (S - 12, S - 12), (11, S - 12)):
        d.rectangle((cx - 1, cy - 1, cx, cy), fill=rgba(STO['DARK']))
    d.rectangle((S // 2 - 6, S // 2 - 2, S // 2 + 5, S // 2 + 1), fill=rgba(STO['SEAM']))
    return img


def storage_hazard():
    img, d = canvas(S, S)
    wb = Wobble(999, 999, 43)
    outline = wobbly_rect(wb, 5, 5, S - 5, S - 5)
    stripes, sd = canvas(S, S)
    sd.rectangle((0, 0, S, S), fill=rgba(STO['HAZ']))
    for k in range(-S, 2 * S, 16):
        sd.polygon(wb.poly([(k, 0), (k + 8, 0), (k + 8 - S, S), (k - S, S)], 0.8), fill=rgba(STO['HAZY']))
    mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(mask).polygon(outline, fill=255)
    img.paste(stripes, (0, 0), mask)
    stroke(d, outline, rgba(STO['SEAM']), 1.2)
    return img


def storage_oil():
    img, d = canvas(34, 26)
    rng = random.Random(17)
    d.polygon(blob(15, 13, 10, rng, 0.2), fill=rgba(STO['OIL']))
    d.polygon(blob(16, 12, 5, rng, 0.2), fill=rgba(STO['OIL2']))
    d.polygon(blob(29, 20, 2.5, rng, 0.1), fill=rgba(STO['OIL']))
    d.rectangle((12, 9, 13, 9), fill=rgba(STO['ALT']))
    return trim(img)


def storage_scuff():
    img, d = canvas(36, 20)
    wb = Wobble(999, 999, 19)
    for p, q in (((3, 14), (24, 5)), ((8, 17), (32, 9)), ((5, 9), (14, 6))):
        stroke(d, wb.line(p, q, 1.8), rgba(STO['ALT'] if p[0] == 5 else STO['SEAM']), 0.6)
    return trim(img)


# --- control ---

def control_cable_cover():
    img, d = canvas(64, 14)
    wb = Wobble(999, 999, 53)
    body = wb.poly([(4, 3), (60, 3), (62, 7), (60, 11), (4, 11), (2, 7)], 0.6)
    d.polygon(body, fill=rgba(CTL['LIGHT']))
    stroke(d, body, rgba(CTL['SEAM']), 1.0)
    stroke(d, wb.line((8, 7), (56, 7), 0.4), rgba(CTL['BASE']), 0.6)
    for x in (12, 32, 52):
        d.rectangle((x, 6, x + 1, 7), fill=rgba(CTL['INSET']))
    return trim(img)


def control_scorch():
    img, d = canvas(34, 30)
    rng = random.Random(61)
    d.polygon(blob(17, 15, 12, rng, 0.22), fill=rgba(CTL['INSET']))
    d.polygon(blob(16, 15, 6.5, rng, 0.28), fill=rgba(CTL['SEAM']))
    d.polygon(blob(18, 14, 2.5, rng, 0.2), fill=rgba(CTL['DEEP']))
    return trim(img)


def control_grate():
    img, d = canvas(34, 24)
    wb = Wobble(999, 999, 67)
    frame = wobbly_rect(wb, 2, 2, 31, 21, 0.7)
    d.polygon(frame, fill=rgba(CTL['INSET']))
    stroke(d, frame, rgba(CTL['SEAM']), 1.0)
    for x in range(8, 28, 5):
        stroke(d, wb.line((x, 6), (x, 17), 0.4), rgba(CTL['DEEP']), 0.8)
    return trim(img)


DECALS = [cafeteria_crack, cafeteria_drain, cafeteria_scuff, cafeteria_stain,
          storage_hatch, storage_hazard, storage_oil, storage_scuff,
          control_cable_cover, control_scorch, control_grate]

if __name__ == '__main__':
    out = pathlib.Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for make in DECALS:
        img = make()
        grade(soften(img), make.__name__.split('_')[0]).save(out / f'{make.__name__}.png')
        print(make.__name__, img.size)
