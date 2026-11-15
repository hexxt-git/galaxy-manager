extends Node2D

## World-space hints. A ring under whatever the player would USE. While carrying something, every station it can go to
## is outlined with "BRING HERE", and a small labelled pointer shows the way when none is near. Without a load, the
## current objective's station gets a soft outline only, no pointer.

const RING := Color(1, 0.86, 0.2)
const RING_BLOCKED := Color(0.65, 0.68, 0.74, 0.7)
const SOFT := Color(1, 0.86, 0.2, 0.45)
const ARROW_DIST := 120.0
const NEAR := 700.0

var colony: Colony
var player: Node2D
var detector: InteractionDetector
var hands: Hands
var blocked := false  # the focused target can't be used right now: grey, no pulse
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _nearest(nodes: Array) -> Node2D:
	var best: Node2D = null
	for n in nodes:
		if best == null or player.global_position.distance_to(n.global_position) < player.global_position.distance_to(best.global_position):
			best = n
	return best


func _draw() -> void:
	if colony == null:
		return
	var focus := detector.focus
	if focus:
		var at: Vector2 = focus.get_parent().global_position
		draw_set_transform(at, 0.0, Vector2(1, 0.4))
		if blocked:
			draw_arc(Vector2.ZERO, 46.0, 0, TAU, 32, RING_BLOCKED, 4.0)
		else:
			draw_arc(Vector2.ZERO, 46.0 + sin(_t * 6.0) * 3.0, 0, TAU, 32, RING, 5.0)
		draw_set_transform(Vector2.ZERO)
	if hands and not hands.is_empty():
		var goals := colony.destinations(hands.type)
		for s in goals:
			_outline(s, RING, "BRING HERE")
		var near := _nearest(goals) as Station
		if near and player.global_position.distance_to(near.global_position) > NEAR:
			_pointer(near.global_position, near.title)
		return
	var kind: String = colony.current_objective()[1]
	if kind != "":
		var s := _nearest(colony.stations_of(kind)) as Station
		if s:
			_outline(s, SOFT, "")


func _outline(s: Station, colour: Color, text: String) -> void:
	var r := Rect2(s.global_position - Vector2(s.size.x * 0.5, s.size.y), s.size).grow(6.0 + sin(_t * 5.0) * 3.0)
	draw_rect(r, colour, false, 5.0)
	if text != "":
		var font := ThemeDB.fallback_font
		var at := Vector2(r.position.x - 60, r.position.y - 12)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 120, 22, 6, Color("0d0d12"))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 120, 22, colour)


func _pointer(to: Vector2, label: String) -> void:
	var from := player.global_position + Vector2(0, -60)
	var dir := from.direction_to(to)
	var tip := from + dir * ARROW_DIST
	var side := dir.orthogonal() * 12.0
	draw_colored_polygon(PackedVector2Array([tip + dir * 18.0, tip + side, tip - side]), RING)
	var font := ThemeDB.fallback_font
	var at := tip + dir * 40.0 + Vector2(-100, 8)
	draw_string_outline(font, at, label, HORIZONTAL_ALIGNMENT_CENTER, 200, 18, 5, Color("0d0d12"))
	draw_string(font, at, label, HORIZONTAL_ALIGNMENT_CENTER, 200, 18, RING)
