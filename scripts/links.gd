extends Control
## Tubes from the home dome to each resource node, with dots flowing home while colonists work there.

const OUTLINE := Color(0.05, 0.11, 0.27)

var hub := Vector2.ZERO
var ends: Array[Vector2] = []
var colors: Array[Color] = []
var flows := []


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in ends.size():
		draw_line(hub, ends[i], OUTLINE, 26.0, true)
		draw_line(hub, ends[i], Color(0.55, 0.65, 0.85), 16.0, true)
		draw_line(hub, ends[i], Color(1, 1, 1, 0.25), 5.0, true)
		var n := mini(flows[i], 6)
		for k in n:
			var p := fposmod(t * 0.5 + float(k) / n, 1.0)
			draw_circle(ends[i].lerp(hub, p), 7.0, colors[i])
