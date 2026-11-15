extends RefCounted

## Fredoka rasterised at a small fixed size with no antialiasing, then scaled up, so text reads as pixel art.
## Drawn at DRAW_SIZE the pixels are DRAW_SIZE / SIZE screen px wide; closer to 1 is subtler.

const SIZE := 24
const DRAW_SIZE := 32
const WEIGHT := 600

static var _font: Font


static func font() -> Font:
	if _font == null:
		var base: FontFile = (load("res://assets/fonts/Fredoka.ttf") as FontFile).duplicate()
		base.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		base.hinting = TextServer.HINTING_NONE
		base.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		base.fixed_size = SIZE
		base.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_ENABLED
		var v := FontVariation.new()
		v.base_font = base
		v.variation_opentype = {2003265652: WEIGHT}  # the "wght" axis tag
		_font = v
	return _font
