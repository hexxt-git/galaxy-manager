class_name Items

## Carryable item types and their placeholder icon.

const DEFS := {
	"ice": {"name": "Ice", "color": Color("bfe8ff"), "letter": "I"},
	"sample": {"name": "Moon rock", "color": Color("8d8d99"), "letter": "R"},
	"potato": {"name": "Potatoes", "color": Color("c9945a"), "letter": "P"},
}
const INK := Color("0d0d12")
const ART := {"ice": "item_ice", "sample": "item_rock", "potato": "item_potato"}
static var _art := {}


static func art(type: String) -> Texture2D:
	if not _art.has(type):
		_art[type] = ColonyMap.texture(ColonyMap.PROPS + ART[type] + ".png")
	return _art[type]


static func label(type: String, count: int) -> String:
	var n: String = DEFS[type].name
	return n if count == 1 else "%s x%d" % [n, count]


## Square token centred on `pos`; `squash` < 1 narrows it horizontally for a fake spin.
static func draw_icon(ci: CanvasItem, pos: Vector2, type: String, count: int, size := 34.0, squash := 1.0) -> void:
	var d: Dictionary = DEFS[type]
	var half := Vector2(size * 0.5 * maxf(absf(squash), 0.15), size * 0.5)
	var r := Rect2(pos - half, half * 2.0)
	var tex := art(type)
	if tex:
		var sz := tex.get_size() * ColonyMap.PX
		sz.x *= maxf(absf(squash), 0.15)
		ci.draw_texture_rect(tex, Rect2(pos - sz * 0.5, sz), false)
	else:
		ci.draw_rect(r, d.color)
		ci.draw_rect(r, INK, false, 3.0)
	var font := ColonyMap.FONT
	if tex == null and absf(squash) > 0.5:
		ci.draw_string(font, pos + Vector2(-size * 0.5, size * 0.2), d.letter, HORIZONTAL_ALIGNMENT_CENTER, size, int(size * 0.6), INK)
	if count > 1:
		var at := pos + Vector2(half.x - 4, size * 0.5 + 4)
		ci.draw_string_outline(font, at, "%d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 6, INK)
		ci.draw_string(font, at, "%d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
