extends Control
## Pill bar splitting recent income into what came from tapping (white) and from workers (color).

const OUTLINE := Color(0.05, 0.11, 0.27)

var color := Color.WHITE
## Share of income from taps, 0..1; negative hides the split (no income yet).
var tap_share := -1.0:
	set(v):
		if not is_equal_approx(v, tap_share):
			tap_share = v
			queue_redraw()


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 20)


func _draw() -> void:
	_pill(Rect2(Vector2.ZERO, size), OUTLINE)
	var inner := Rect2(Vector2(2, 2), size - Vector2(4, 4))
	if tap_share < 0.0:
		return
	_pill(inner, color.darkened(0.1))
	var tap_w := inner.size.x * tap_share
	if tap_w > 1.0:
		_pill(Rect2(inner.position, Vector2(maxf(tap_w, inner.size.y), inner.size.y)), Color(1, 1, 1, 0.95))
	var font := get_theme_default_font()
	var fs := int(size.y * 0.72)
	var base := size.y * 0.5 + fs * 0.36
	if tap_w > 70.0:
		draw_string(font, Vector2(inner.position.x + 8, base), "tap %d%%" % roundi(tap_share * 100.0),
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, OUTLINE)
	if inner.size.x - tap_w > 76.0:
		draw_string(font, Vector2(inner.end.x - 8 - 70, base), "auto %d%%" % roundi((1.0 - tap_share) * 100.0),
			HORIZONTAL_ALIGNMENT_RIGHT, 70, fs, OUTLINE)


func _pill(rect: Rect2, c: Color) -> void:
	var r := rect.size.y * 0.5
	if rect.size.x <= rect.size.y:
		draw_circle(rect.get_center(), r, c)
		return
	draw_rect(Rect2(rect.position + Vector2(r, 0), Vector2(rect.size.x - 2.0 * r, rect.size.y)), c)
	draw_circle(rect.position + Vector2(r, r), r, c)
	draw_circle(Vector2(rect.end.x - r, rect.position.y + r), r, c)
