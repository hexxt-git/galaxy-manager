# Global contrast for the Python-drawn art (floors, decals); same value and formula as CONTRAST in pixelate.js.
from PIL import Image

CONTRAST = 0.9


def soften(img):
    """Moves every RGB value toward mid grey by CONTRAST, leaving alpha alone."""
    lut = [round(128 + (v - 128) * CONTRAST) for v in range(256)]
    bands = img.split()
    return Image.merge(img.mode, [b.point(lut) for b in bands[:3]] + list(bands[3:]))


# Per-room floor grading: colour exponent and brightness, applied in 0..1. Floors and their decals of a room share it.
ROOM_GRADE = {'control': (2.0, 0.765)}


def grade(img, room):
    if room not in ROOM_GRADE:
        return img
    exp, light = ROOM_GRADE[room]
    lut = [round(min(1.0, (v / 255) ** exp * light) * 255) for v in range(256)]
    bands = img.split()
    return Image.merge(img.mode, [b.point(lut) for b in bands[:3]] + list(bands[3:]))
