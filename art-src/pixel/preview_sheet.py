# Pixel preview from exported PNGs only: each prop on a floor beside the character, nearest-neighbour upscaled.
# Usage: preview_sheet.py <out.png> <floor.png> name[:ox,oy] ...   (origin defaults to bottom-centre)
import sys, pathlib
from PIL import Image
ROOT = pathlib.Path(__file__).resolve().parents[2] / 'assets' / 'art'
UP, GAP, PAD = 3, 14, 16
out, floor = sys.argv[1], Image.open(sys.argv[2]).convert('RGBA')
char = Image.open(ROOT / 'character' / 'character.png').convert('RGBA')
px = char.load()
for j in range(char.height):
    for i in range(char.width):
        r, g, b, a = px[i, j]
        if a and (r, g, b) == (255, 0, 0):
            px[i, j] = (236, 128, 52, a)
        elif a and (r, g, b) == (0, 0, 255):
            px[i, j] = (176, 76, 46, a)
sprites = []
for arg in sys.argv[3:]:
    name, _, o = arg.partition(':')
    im = Image.open(ROOT / 'props' / f'{name}.png').convert('RGBA')
    ox, oy = map(int, o.split(',')) if o else (im.width // 2, im.height)
    sprites.append((im, ox, oy))
items = [(char, 34, 69)] + sprites + [(char, 34, 69)]
H = max(oy for _, _, oy in items) + max(im.height - oy for im, _, oy in items) + PAD * 2
W = sum(im.width for im, _, _ in items) + GAP * (len(items) - 1) + PAD * 2
scene = Image.new('RGBA', (W, H))
for y in range(0, H, floor.height):
    for x in range(0, W, floor.width):
        scene.paste(floor, (x, y))
ground = PAD + max(oy for _, _, oy in items)
x = PAD
for im, ox, oy in items:
    scene.alpha_composite(im, (x, ground - oy))
    x += im.width + GAP
scene.resize((W * UP, H * UP), Image.NEAREST).save(out)
print(out, scene.size)
