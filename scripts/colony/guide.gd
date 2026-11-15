extends Node2D

## World-space hints. A ring under whatever the player would USE. While carrying something, every station it can go to
## gets corner brackets and a BRING HERE tag, and a small labelled pointer shows the way when none is near. Without a
## load, the current objective's station gets faint brackets only, no pointer.

const RING := Color(1, 0.86, 0.2)
const ARROW_DIST := 120.0
const NEAR := 700.0

var colony: Colony
var player: Node2D
var detector: InteractionDetector
var hands: Hands
var blocked := false  # the focused target can't be used right now: grey, no pulse
var _t := 0.0
var _ring := ColonyMap.texture(ColonyMap.PROPS + "mark_ring.png")
var _ring_blocked := ColonyMap.texture(ColonyMap.PROPS + "mark_ring_blocked.png")
var _corner := ColonyMap.texture(ColonyMap.PROPS + "mark_corner.png")
var _arrow := ColonyMap.texture(ColonyMap.PROPS + "mark_arrow.png")
var _tag := ColonyMap.texture(ColonyMap.PROPS + "mark_bring.png")


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
		var ring := _ring_blocked if blocked else _ring
		var pulse := 1.0 if blocked else 0.75 + 0.25 * sin(_t * 6.0)
		draw_set_transform(at, 0.0, Vector2(ColonyMap.PX, ColonyMap.PX))
		draw_texture(ring, -ring.get_size() * 0.5, Color(1, 1, 1, pulse))
		draw_set_transform(Vector2.ZERO)
	if hands and not hands.is_empty():
		var goals := colony.destinations(hands.type)
		for s in goals:
			_outline(s, 1.0, true)
		var near := _nearest(goals) as Station
		if near and player.global_position.distance_to(near.global_position) > NEAR:
			_pointer(near.global_position, near.title)
		return
	var kind: String = colony.current_objective()[1]
	if kind != "":
		var s := _nearest(colony.stations_of(kind)) as Station
		if s:
			_outline(s, 0.5, false)


func _outline(s: Station, alpha: float, tag: bool) -> void:
	var px := ColonyMap.PX
	var breathe := roundf(1.0 + sin(_t * 5.0)) * px * 2.0
	var r := Rect2(s.global_position - Vector2(s.size.x * 0.5, s.size.y), s.size)
	if s.art:
		r = Rect2(s.global_position - s.art_origin * px, s.art.get_size() * px)
	r = r.grow(8.0 + breathe)
	var tint := Color(1, 1, 1, alpha)
	for c in [[r.position, Vector2(1, 1)], [Vector2(r.end.x, r.position.y), Vector2(-1, 1)],
			[Vector2(r.position.x, r.end.y), Vector2(1, -1)], [r.end, Vector2(-1, -1)]]:
		draw_set_transform(c[0], 0.0, c[1] * px)
		draw_texture(_corner, -Vector2(3, 3), tint)
	if tag:
		draw_set_transform(Vector2(r.get_center().x, r.position.y - 4.0), 0.0, Vector2(px, px))
		draw_texture(_tag, -Vector2(_tag.get_width() * 0.5, _tag.get_height()), tint)
	draw_set_transform(Vector2.ZERO)


func _pointer(to: Vector2, label: String) -> void:
	var from := player.global_position + Vector2(0, -60)
	var angle := snappedf(from.direction_to(to).angle(), PI / 4.0)
	var dir := Vector2.from_angle(angle)
	var tip := from + dir * ARROW_DIST
	draw_set_transform(tip, angle, Vector2(ColonyMap.PX, ColonyMap.PX))
	draw_texture(_arrow, -_arrow.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO)
	var font := ColonyMap.FONT
	var at := tip + dir * 40.0 + Vector2(-100, 8)
	draw_string_outline(font, at, label, HORIZONTAL_ALIGNMENT_CENTER, 200, 24, 8, Color("0d0d12"))
	draw_string(font, at, label, HORIZONTAL_ALIGNMENT_CENTER, 200, 24, RING)
