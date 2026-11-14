# Ground shadow under characters, matching the props' baked ones (GROUND_RGBA in props/prop.js).
# usage: character_shadow.py OUT.png
import sys, math
from PIL import Image

RADII = (19, 5)
WOBBLE = 0.12  # outline wander, as a fraction of the radius
COLOUR = (24, 24, 40, 56)

hx, hy = (math.ceil(r * (1 + WOBBLE)) for r in RADII)
img = Image.new('RGBA', (hx * 2, hy * 2))
for y in range(hy * 2):
    for x in range(hx * 2):
        px, py = (x + 0.5 - hx) / RADII[0], (y + 0.5 - hy) / RADII[1]
        a = math.atan2(py, px)
        r = 1 + WOBBLE * (0.6 * math.sin(3 * a + 1.3) + 0.4 * math.sin(5 * a + 4.1))
        if math.hypot(px, py) <= r:
            img.putpixel((x, y), COLOUR)
img.save(sys.argv[1])
print('shadow', img.size)
