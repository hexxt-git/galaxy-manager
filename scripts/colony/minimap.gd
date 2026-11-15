extends Control

## Whole-base overview, toggled with M or the MAP button: rooms, stations, the player and every crewmate.

const MARGIN := 24.0
const INK := Color("0d0d12")
const HUD := preload("res://scripts/colony/hud.gd")

var map: ColonyMap
var colony: Colony
var player: Node2D


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	add_to_group("blocks_joystick")
	hide()


func toggle() -> void:
	visible = not visible


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide()
		accept_event()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.04, 0.08, 0.88))
	if map == null:
		return
	var grid := Vector2(map.cols(), map.rows())
	var k := minf((size.x - MARGIN * 2) / grid.x, (size.y - MARGIN * 2 - 120) / grid.y)
	var origin := (size - grid * k) * 0.5 + Vector2(0, 30)
	var to_screen := func(world: Vector2) -> Vector2: return origin + world / ColonyMap.TILE * k
	if map.ground_texture:
		draw_texture_rect(map.ground_texture, Rect2(origin, grid * k), false)
	else:
		for y in map.rows():
			for x in map.cols():
				draw_rect(Rect2(origin + Vector2(x, y) * k, Vector2(k, k) + Vector2(0.5, 0.5)), ColonyMap.FLOORS[map.floor_cells[y * map.cols() + x]])
	var wall := Color("bcd0cd")
	var t := maxf(2.0, k * 0.34)
	for y in map.rows():
		for x in map.cols():
			if not map._is_wall(x, y):
				continue
			var c: Vector2 = origin + (Vector2(x, y) + Vector2(0.5, 0.5)) * k
			draw_rect(Rect2(c - Vector2(t, t) * 0.5, Vector2(t, t)), wall)
			for d in [Vector2i.RIGHT, Vector2i.DOWN]:
				if map._is_wall(x + d.x, y + d.y):
					draw_rect(Rect2(c - Vector2(t, t) * 0.5, Vector2(t, t) + Vector2(d) * k), wall)
	for s in map.stations:
		if not is_instance_valid(s) or s.kind == "note" or s.art == null:
			continue
		var sz: Vector2 = s.art.get_size() * ColonyMap.PX / ColonyMap.TILE * k
		var at: Vector2 = to_screen.call(s.global_position) - s.art_origin * ColonyMap.PX / ColonyMap.TILE * k
		draw_texture_rect(s.art, Rect2(at, sz), false)
	var font := ColonyMap.FONT
	for c in colony.crew:
		if not is_instance_valid(c):
			continue
		var p: Vector2 = to_screen.call(c.global_position)
		var head := HUD.portrait(c.colour, true, 1)
		var hs := head.get_size() * (0.6 if c == player else 0.45)
		draw_texture_rect(head, Rect2(p - Vector2(hs.x * 0.5, hs.y), hs), false)
		if c == player:
			draw_string(font, p + Vector2(-40, -16), "YOU", HORIZONTAL_ALIGNMENT_CENTER, 80, 18, Color.WHITE)
	draw_string(font, Vector2(0, 50), "MAP  (M or tap to close)", HORIZONTAL_ALIGNMENT_CENTER, size.x, 26, Color.WHITE)
