extends Control
## Red glow around the screen edges that pulses faster as `intensity` rises toward 1.

const RED := Color(1.0, 0.12, 0.1)
const DEPTH := 0.16

var intensity := 0.0
var _phase := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_phase += delta * lerpf(3.0, 9.0, intensity)
	if intensity > 0.0 or visible:
		queue_redraw()


func _draw() -> void:
	if intensity <= 0.0:
		return
	var a := intensity * (0.55 + 0.3 * sin(_phase))
	var edge := Color(RED, a)
	var clear := Color(RED, 0.0)
	var w := size.x
	var h := size.y
	var d := minf(w, h) * DEPTH * (0.7 + 0.6 * intensity)
	var outer := [Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]
	var inner := [Vector2(d, d), Vector2(w - d, d), Vector2(w - d, h - d), Vector2(d, h - d)]
	for i in 4:
		var j := (i + 1) % 4
		draw_polygon(PackedVector2Array([outer[i], outer[j], inner[j], inner[i]]),
			PackedColorArray([edge, edge, clear, clear]))
