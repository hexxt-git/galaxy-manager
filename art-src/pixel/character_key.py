# Turns the hand-cleaned sprite into the game's character.png: mirrored to face right,
# suit tones swapped for the recolour keys (pure red = lit, pure blue = shadow), 2x nearest.
# usage: character_key.py SRC.png OUT.png
import sys
from PIL import Image, ImageOps

KEYS = {(0xE4, 0x26, 0x24): (255, 0, 0), (0x9C, 0x17, 0x30): (0, 0, 255)}

im = ImageOps.mirror(Image.open(sys.argv[1]).convert('RGBA'))
px = im.load()
for y in range(im.height):
    for x in range(im.width):
        r, g, b, a = px[x, y]
        if a and (r, g, b) in KEYS:
            px[x, y] = (*KEYS[(r, g, b)], a)
im = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
im.save(sys.argv[2])
print('character', im.size, 'bbox', im.getbbox())
