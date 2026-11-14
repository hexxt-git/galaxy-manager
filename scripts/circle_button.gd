class_name CircleButton
extends Control
## Round glossy "candy" button in TAG's style: drop shadow, navy outline, a darker lip below the
## face, a gloss band and a drawn icon. Fires on touch-down so mashing feels instant, and handles
## each finger separately so several buttons can be mashed at once.

signal tapped
## Tapped while disabled.
signal denied

enum Icon { NONE, WHEAT, O2, PERSON, GEAR, HOUSE, PLUS, MINUS, CLOSE }

const OUTLINE := Color(0.05, 0.11, 0.27)
const SHADOW := Color(0.02, 0.04, 0.12, 0.35)

@export var face := Color(0.29, 0.54, 1.0):
	set(v):
		face = v
		queue_redraw()
@export var icon := Icon.NONE:
	set(v):
		icon = v
		queue_redraw()
@export var text := "":
	set(v):
		text = v
		queue_redraw()
## Small counter bubble on the top-right edge; hidden when empty.
@export var badge := "":
	set(v):
		badge = v
		queue_redraw()
@export var disabled := false:
	set(v):
		disabled = v
		queue_redraw()
## Purely decorative: ignores touches.
@export var passive := false:
	set(v):
		passive = v
		mouse_filter = MOUSE_FILTER_IGNORE if v else MOUSE_FILTER_STOP

var _press := 0.0
var _tween: Tween


func _ready() -> void:
	resized.connect(func(): pivot_offset = size * 0.5)
	pivot_offset = size * 0.5


func _has_point(point: Vector2) -> bool:
	return point.distance_to(size * 0.5) <= minf(size.x, size.y) * 0.5


func _gui_input(event: InputEvent) -> void:
	if passive or not (event is InputEventScreenTouch and event.pressed):
		return
	accept_event()
	if disabled:
		shake()
		denied.emit()
		return
	_punch()
	tapped.emit()


func shake() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	for x in [12.0, -10.0, 6.0, 0.0]:
		_tween.tween_property(self, "rotation", deg_to_rad(x * 0.4), 0.04)


func _punch() -> void:
	if _tween:
		_tween.kill()
	rotation = 0.0
	scale = Vector2(0.92, 0.92)
	_press = 1.0
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_method(func(v: float): _press = v; queue_redraw(), 1.0, 0.0, 0.12)


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	var c := size * 0.5
	var line := maxf(r * 0.05, 3.0)
	var depth := r * 0.1
	var col := face if not disabled else face.lerp(Color(0.45, 0.5, 0.62), 0.75)

	draw_circle(c + Vector2(0, depth * 0.5), r, SHADOW)
	draw_circle(c, r, OUTLINE)
	var inner := r - line
	draw_circle(c, inner, col.darkened(0.38))

	var fr := inner - depth * 0.5
	var fc := c + Vector2(0, -depth * 0.5 + depth * 0.8 * _press)
	draw_circle(fc, fr, col)
	draw_circle(fc + Vector2(0, fr * 0.12), fr * 0.92, col.darkened(0.06))
	draw_circle(fc, fr * 0.9, col)

	draw_set_transform(fc + Vector2(0, -fr * 0.48), 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, fr * 0.68, Color(1, 1, 1, 0.2))
	draw_set_transform(Vector2.ZERO)
	draw_arc(fc, fr - 1.5, PI * 1.15, PI * 1.85, 24, Color(1, 1, 1, 0.45), maxf(line * 0.6, 2.0), true)

	var font := get_theme_default_font()
	var s := fr * (0.42 if text != "" else 0.55)
	var ic := fc + Vector2(0, -fr * 0.2 if text != "" else 0.0)
	if icon != Icon.NONE:
		_icon(ic + Vector2(0, s * 0.1), s, Color(OUTLINE, 0.35), col)
		_icon(ic, s, Color.WHITE, col)

	if text != "":
		var fs := int(fr * (0.3 if icon != Icon.NONE else 0.42))
		var y := fc.y + (fr * 0.55 if icon != Icon.NONE else fs * 0.35)
		_text(font, Vector2(fc.x, y), text, fs, Color.WHITE)

	if badge != "":
		var bc := c + Vector2(r, -r) * 0.72
		var br := r * 0.27
		draw_circle(bc, br, OUTLINE)
		draw_circle(bc, br - line * 0.8, Color(1, 0.84, 0.25))
		_text(font, bc + Vector2(0, br * 0.38), badge, int(br * 1.05), OUTLINE, 0)


func _text(font: Font, at: Vector2, t: String, fs: int, color: Color, outline := -1) -> void:
	var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos := Vector2(at.x - w * 0.5, at.y)
	var o := outline if outline >= 0 else maxi(fs / 5, 3)
	if o > 0:
		draw_string_outline(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, o, OUTLINE)
	draw_string(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _ellipse(at: Vector2, radii: Vector2, rot: float, color: Color) -> void:
	draw_set_transform(at, rot, radii)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO)


## `bg` fills holes (door, gear centre) so they read as cut-outs.
func _icon(c: Vector2, s: float, col: Color, bg: Color) -> void:
	match icon:
		Icon.WHEAT:
			draw_line(c + Vector2(0, s), c + Vector2(0, -s * 0.7), col, s * 0.14)
			for i in 3:
				var y := -s * 0.55 + i * s * 0.42
				_ellipse(c + Vector2(-s * 0.2, y), Vector2(s * 0.15, s * 0.28), -0.5, col)
				_ellipse(c + Vector2(s * 0.2, y), Vector2(s * 0.15, s * 0.28), 0.5, col)
			_ellipse(c + Vector2(0, -s * 0.9), Vector2(s * 0.14, s * 0.27), 0.0, col)
		Icon.O2:
			var font := get_theme_default_font()
			var big := int(s * 1.9)
			var small := int(s * 0.9)
			var ow := font.get_string_size("O", HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
			var x := c.x - (ow + small * 0.5) * 0.5
			draw_string(font, Vector2(x, c.y + big * 0.36), "O", HORIZONTAL_ALIGNMENT_LEFT, -1, big, col)
			draw_string(font, Vector2(x + ow, c.y + big * 0.52), "2", HORIZONTAL_ALIGNMENT_LEFT, -1, small, col)
		Icon.PERSON:
			draw_circle(c + Vector2(0, -s * 0.48), s * 0.38, col)
			var body := PackedVector2Array()
			for i in 17:
				var a := PI + PI * i / 16.0
				body.append(c + Vector2(0, s * 0.95) + Vector2(cos(a) * s * 0.75, sin(a) * s * 0.85))
			draw_colored_polygon(body, col)
		Icon.GEAR:
			for i in 8:
				draw_set_transform(c, TAU * i / 8.0, Vector2.ONE)
				draw_rect(Rect2(-s * 0.18, -s * 0.98, s * 0.36, s * 0.5), col)
			draw_set_transform(Vector2.ZERO)
			draw_circle(c, s * 0.7, col)
			draw_circle(c, s * 0.28, bg)
		Icon.HOUSE:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-s * 1.05, -s * 0.05), c + Vector2(0, -s * 0.95), c + Vector2(s * 1.05, -s * 0.05)]), col)
			draw_rect(Rect2(c + Vector2(-s * 0.72, -s * 0.15), Vector2(s * 1.44, s * 1.05)), col)
			draw_rect(Rect2(c + Vector2(-s * 0.2, s * 0.35), Vector2(s * 0.4, s * 0.55)), bg)
			draw_circle(c + Vector2(s * 0.38, s * 0.12), s * 0.14, bg)
		Icon.PLUS:
			draw_line(c + Vector2(-s * 0.7, 0), c + Vector2(s * 0.7, 0), col, s * 0.32)
			draw_line(c + Vector2(0, -s * 0.7), c + Vector2(0, s * 0.7), col, s * 0.32)
		Icon.MINUS:
			draw_line(c + Vector2(-s * 0.7, 0), c + Vector2(s * 0.7, 0), col, s * 0.32)
		Icon.CLOSE:
			draw_line(c + Vector2(-s, -s) * 0.55, c + Vector2(s, s) * 0.55, col, s * 0.3)
			draw_line(c + Vector2(s, -s) * 0.55, c + Vector2(-s, s) * 0.55, col, s * 0.3)
