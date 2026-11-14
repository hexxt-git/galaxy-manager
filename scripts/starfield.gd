extends Control

const COUNT := 150

var stars: Array[Vector3] = []


func _ready() -> void:
	for i in COUNT:
		stars.append(Vector3(randf(), randf(), randf()))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for s in stars:
		var y := fposmod(s.y + t * 0.01 * (0.5 + s.z), 1.0)
		var a := 0.4 + 0.6 * absf(sin(t * (1.0 + s.z * 2.0) + s.x * 50.0))
		draw_circle(Vector2(s.x * size.x, y * size.y), 1.0 + s.z * 2.0, Color(1, 1, 1, a))
