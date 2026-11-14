extends Control
## Space backdrop: a deep gradient, a slowly turning sunburst behind the colony and twinkling stars.

const COUNT := 150
const RAYS := 16
const TOP := Color(0.07, 0.09, 0.27)
const BOTTOM := Color(0.2, 0.11, 0.36)

var burst_center := Vector2(0.5, 0.55)
var stars: Array[Vector3] = []


func _ready() -> void:
	for i in COUNT:
		stars.append(Vector3(randf(), randf(), randf()))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([TOP, TOP, BOTTOM, BOTTOM]))

	var t := Time.get_ticks_msec() / 1000.0
	var c := size * burst_center
	var reach := size.length()
	for i in RAYS:
		var a0 := t * 0.04 + TAU * i / RAYS
		var a1 := a0 + TAU / RAYS * 0.5
		draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a0) * reach, c + Vector2.from_angle(a1) * reach]),
			Color(1, 1, 1, 0.035))

	for s in stars:
		var y := fposmod(s.y + t * 0.01 * (0.5 + s.z), 1.0)
		var a := 0.4 + 0.6 * absf(sin(t * (1.0 + s.z * 2.0) + s.x * 50.0))
		draw_circle(Vector2(s.x * w, y * h), 1.0 + s.z * 2.0, Color(1, 1, 1, a))
