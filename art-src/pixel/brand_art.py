# App icon, boot splash, HUD crew icon and the web og:image, built from the crewmate sprite and menu art.
# usage: brand_art.py  (run from anywhere; writes into the Godot project and docs/)
import math, pathlib, random
from PIL import Image, ImageDraw, ImageOps

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
ART = ROOT / 'assets' / 'art'
PROPS = ART / 'props'

SKY = (0x1D, 0x28, 0x46, 255)
RAY = (0x23, 0x31, 0x5A, 255)
INK = (0x0D, 0x0D, 0x12, 255)
STAR = (0xA6, 0xAB, 0xB9, 255)  # white at 0.55 over SKY, as the menu draws them
LIT, SHADE = (0xE4, 0x26, 0x24), (0x9C, 0x17, 0x30)
COLOURS = {  # same tones as crewmate.gd
    'red': ('c51111', '900b2c'), 'blue': ('132ed1', '0c1ca2'), 'orange': ('ef7d0d', 'c55113'),
    'yellow': ('f5f557', 'd2a933'), 'cyan': ('38fedc', '2ac2c7'), 'white': ('d6e0f0', '9cabce'),
    'pink': ('ed54ba', 'bf37b1'), 'green': ('117f2d', '0c5c2e'),
}


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def crew(colour, k, face_right=True):
    im = Image.open(HERE / 'character_sprite.png').convert('RGBA')
    if face_right:
        im = ImageOps.mirror(im)
    lit, shade = (rgb(c) for c in COLOURS[colour])
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and (r, g, b) == LIT:
                px[x, y] = (*lit, a)
            elif a and (r, g, b) == SHADE:
                px[x, y] = (*shade, a)
    return up(im, k)


def up(im, k):
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def prop(name, k):
    return up(Image.open(PROPS / f'{name}.png').convert('RGBA'), k)


def rays(w, h, c, n=18):
    img = Image.new('RGBA', (w, h), SKY)
    px = img.load()
    wedge = math.tau / n
    for y in range(h):
        for x in range(w):
            if math.atan2(y + 0.5 - c[1], x + 0.5 - c[0]) % wedge < wedge * 0.5:
                px[x, y] = RAY
    return img


def stars(img, k, count, bottom, seed=7, avoid=()):
    rng = random.Random(seed)
    d = ImageDraw.Draw(img)
    for _ in range(count):
        x, y = rng.randrange(img.width // k) * k, rng.randrange(int(bottom) // k) * k
        if any(a[0] <= x < a[2] and a[1] <= y < a[3] for a in avoid):
            continue
        s = k if rng.random() < 0.8 else 2 * k
        d.rectangle((x, y, x + s - 1, y + s - 1), STAR)


def ground(img, top, k, ridge=True):
    tile = up(Image.open(ART / 'colony' / 'regolith.png').convert('RGBA'), k)
    for x in range(0, img.width, tile.width):
        for y in range(top, img.height, tile.height):
            img.alpha_composite(tile, (x, y))
    if ridge:
        r = prop('menu_ridge', k)
        for x in range(0, img.width, r.width):
            img.alpha_composite(r, (x, top - r.height + 2 * k))


def shadow(img, cx, y, w, k):
    sh = Image.new('RGBA', img.size)
    ImageDraw.Draw(sh).ellipse((cx - w // 2, y - 3 * k, cx + w // 2, y + 3 * k), (24, 24, 40, 70))
    img.alpha_composite(sh)


def stand(img, sprite, cx, feet, k):
    shadow(img, cx, feet - k, int(sprite.width * 0.8), k)
    img.alpha_composite(sprite, (cx - sprite.width // 2, feet - sprite.height))


def icon():
    k = 4  # 64 art px across
    n = 64
    a = Image.new('RGBA', (n, n), SKY)
    stars(a, 1, 26, 40, seed=3, avoid=[(42, 3, 62, 23)])
    a.alpha_composite(Image.open(PROPS / 'menu_earth.png').convert('RGBA').resize((18, 18), Image.NEAREST), (43, 5))
    tile = Image.open(ART / 'colony' / 'regolith.png').convert('RGBA')
    g = Image.new('RGBA', (n, n))
    g.alpha_composite(tile.crop((0, 0, n, n)))
    m = Image.new('L', (n, n))
    ImageDraw.Draw(m).ellipse((-30, 44, n + 30, 120), 255)
    a.paste(g, (0, 0), m)
    ImageDraw.Draw(a).arc((-30, 44, n + 30, 120), 180, 360, INK)
    a = up(a, k)
    stand(a, crew('orange', 4), 108, 238, k)
    mask = Image.new('L', a.size)
    ImageDraw.Draw(mask).rounded_rectangle((4, 4, a.width - 5, a.height - 5), 44, 255)
    out = Image.new('RGBA', a.size)
    out.paste(a, (0, 0), mask)
    ImageDraw.Draw(out).rounded_rectangle((4, 4, a.width - 5, a.height - 5), 44, outline=INK, width=8)
    out.save(ROOT / 'icon.png')
    print('icon', out.size)


def splash():
    img = Image.new('RGBA', (480, 600), SKY)
    title = prop('menu_title', 3)
    img.alpha_composite(title, ((img.width - title.width) // 2, 24))
    stand(img, crew('orange', 5), img.width // 2, 588, 5)
    img.save(ART / 'splash.png')
    print('splash', img.size)


def crew_icon():
    head = crew('white', 1).crop((9, 0, 34, 22))
    head = head.crop(head.getbbox())
    s = min(24 / head.width, 24 / head.height)
    head = head.resize((max(1, round(head.width * s)), max(1, round(head.height * s))), Image.NEAREST)
    out = Image.new('RGBA', (24, 24))
    out.alpha_composite(head, ((24 - head.width) // 2, (24 - head.height) // 2))
    out.save(ART / 'ui' / 'icon_crew.png')
    print('icon_crew', out.size, head.size)


def og():
    k = 3
    w, h = 1200, 630
    horizon = 456
    title = prop('menu_title', k)
    tpos = (110, 70)
    tc = (tpos[0] + title.width // 2, tpos[1] + title.height // 2)
    img = rays(w // k, horizon // k + 1, (tc[0] / k, tc[1] / k)).resize((w // k * k, (horizon // k + 1) * k), Image.NEAREST)
    canvas = Image.new('RGBA', (w, h), SKY)
    canvas.alpha_composite(img)
    stars(canvas, k, 70, horizon - 60, seed=11)
    canvas.alpha_composite(prop('menu_earth', k), (760, 60))
    canvas.alpha_composite(prop('menu_planet', k), (600, 30))
    ground(canvas, horizon, k)
    canvas.alpha_composite(prop('menu_rocket', k), (930, horizon - prop('menu_rocket', k).height + 70))
    canvas.alpha_composite(title, tpos)
    for colour, cx, feet in [('red', 250, 610), ('cyan', 560, 575), ('orange', 760, 615), ('yellow', 1110, 600)]:
        stand(canvas, crew(colour, 4, face_right=cx < 1000), cx, feet, k)
    out = ROOT / 'docs' / 'og-image.png'
    canvas.convert('RGB').save(out)
    print('og', canvas.size)


icon()
splash()
crew_icon()
og()
