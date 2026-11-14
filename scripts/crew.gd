class_name Crew
extends Control
## A row of little colonists, one per person, wearing `shirt`. When there are more than fit, the
## last slot shows "+N".

const OUTLINE := Color(0.05, 0.11, 0.27)
const SKINS: Array[Color] = [
	Color(1.0, 0.86, 0.72), Color(0.93, 0.72, 0.55), Color(0.76, 0.53, 0.36), Color(0.52, 0.35, 0.23)]

var count := 0:
	set(v):
		count = v
		queue_redraw()
var shirt := Color.WHITE
var token := 40.0
var rows := 1
## Shown faintly when nobody is here.
var empty_text := ""


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _get_minimum_size() -> Vector2:
	return Vector2(token, token * rows)


func _columns() -> int:
	return maxi(int((size.x - token) / (token * 0.8)) + 1, 1)


## Centre of the slot that person `index` stands in, in local coordinates.
func slot_center(index: int) -> Vector2:
	var cols := _columns()
	var k := clampi(index, 0, cols * rows - 1)
	return Vector2(token * 0.5 + (k % cols) * token * 0.8, token * 0.5 + (k / cols) * token)


func _draw() -> void:
	if count == 0:
		if empty_text != "":
			var font := get_theme_default_font()
			var fs := int(token * 0.5)
			draw_string(font, Vector2(0, token * 0.5 + fs * 0.36), empty_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
				Color(1, 1, 1, 0.45))
		return
	var slots := _columns() * rows
	var shown := count if count <= slots else slots - 1
	for k in shown:
		draw_person(self, slot_center(k), token, shirt, SKINS[(k * 7 + 3) % SKINS.size()])
	if shown < count:
		var c := slot_center(shown)
		draw_circle(c, token * 0.46, OUTLINE)
		draw_circle(c, token * 0.4, Color(1, 0.84, 0.25))
		var font := get_theme_default_font()
		var t := "+%d" % (count - shown)
		var fs := int(token * (0.42 if t.length() <= 3 else 0.32))
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(c.x - w * 0.5, c.y + fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, OUTLINE)


static func draw_person(ci: CanvasItem, c: Vector2, s: float, shirt_color: Color, skin: Color) -> void:
	var o := maxf(s * 0.06, 2.0)
	var body := _body(c + Vector2(0, s * 0.5), s * 0.36, s * 0.42)
	var body_out := _body(c + Vector2(0, s * 0.5), s * 0.36 + o, s * 0.42 + o)
	var head := c + Vector2(0, -s * 0.14)
	ci.draw_colored_polygon(body_out, OUTLINE)
	ci.draw_circle(head, s * 0.24 + o, OUTLINE)
	ci.draw_colored_polygon(body, shirt_color)
	ci.draw_circle(head, s * 0.24, skin)
	ci.draw_circle(head + Vector2(-s * 0.08, -s * 0.07), s * 0.06, Color(1, 1, 1, 0.5))


static func _body(base: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(base + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
