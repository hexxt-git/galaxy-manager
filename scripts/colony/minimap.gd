extends Control

## Whole-base overview, toggled with M or the MAP button: rooms, stations, the player and every crewmate.

const MARGIN := 24.0
const INK := Color("0d0d12")

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
	for y in map.rows():
		for x in map.cols():
			var f: String = map.floor_cells[y * map.cols() + x]
			draw_rect(Rect2(origin + Vector2(x, y) * k, Vector2(k, k) + Vector2(0.5, 0.5)), ColonyMap.FLOORS[f])
	for s in map.stations:
		if not is_instance_valid(s) or s.kind == "note":
			continue
		var tl: Vector2 = to_screen.call(s.global_position - Vector2(s.size.x * 0.5, s.size.y))
		draw_rect(Rect2(tl, s.size / ColonyMap.TILE * k), s.colour)
	var font := ThemeDB.fallback_font
	for c in colony.crew:
		if not is_instance_valid(c):
			continue
		var p: Vector2 = to_screen.call(c.global_position)
		var col: Color = c.COLOURS[c.colour][0]
		var r := 9.0 if c == player else 7.0
		draw_circle(p, r + 3, INK)
		draw_circle(p, r, col)
		if c == player:
			draw_string(font, p + Vector2(-40, -16), "YOU", HORIZONTAL_ALIGNMENT_CENTER, 80, 18, Color.WHITE)
	draw_string(font, Vector2(0, 50), "MAP  (M or tap to close)", HORIZONTAL_ALIGNMENT_CENTER, size.x, 26, Color.WHITE)
