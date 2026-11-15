class_name ColonyMap
extends Node2D

## Placeholder grid map built from LAYOUT, one character per TILE.
##   o boulder   # wall   . floor   , moon surface   : crater floor
##   @ spawn   1-9 notes   k loose moon rock
##   s g n: empty slots that upgrades build a solar panel, grow bed or reactor into
##   other letters: stations and decor (see Station.KINDS); touching cells with the same letter form one.

const TILE := 96.0
const LAYOUT := [
	"oooooooooooooooooooooooooooooooooooooooo",
	"o,,,,,,,,,,,,,,,,,,k,,,,,,,,,,,,,,,,,,,o",
	"o,,,sss,,sss,,SSS,,,,,SSS,,sss,,sss,,,,o",
	"o,,,sss,,sss,,SSS,,,,,SSS,,sss,,sss,,,,o",
	"o,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,k,o",
	"o,k,,,,,,,,,,,,,,,,6,,,,,,,,,,,,,,,,,,,o",
	"o,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,PP,,o",
	"o,,,,,#####..############..#######,,,,,o",
	"o,,,,,#..........3.#.ccc.....bb..#,,,,,o",
	"o,RR,,#.GG..gg.gg..#.ccc.........#,,,,,o",
	"o,k,,,....................@..bb...,,,,,o",
	"o,,,,,...................tt...ZZ8.,,,,,o",
	"o,,,,,#.GG..gg.gg..#.1.QQ....2...#,,,k,o",
	"o,,,,,#............#..........nn.#,,,,,o",
	"o,,,,,#####..############..#######,,,,,o",
	"o,,,,,#............#.............#,,,,,o",
	"o,,,,,#.5..........#..EE.......4.#,RR,,o",
	"o,,,,,.....LL............WWW......,,,,,o",
	"o,,,,,.....LL............WWW......,,,,,o",
	"o,,k,,#............#.............#,,,,,o",
	"o,,,,,#............#.......9.OO..#,,k,,o",
	"o,,,,,#............#.............#,,,,,o",
	"o,,,,,#####..############..#######,,,,,o",
	"o,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,o",
	"o::::o::k:o::::o::::o::::o::::o::::o:::o",
	"o:::::::::::::::::::7::::::::::k:::::::o",
	"o::::::::::::::::::::::::::::::::::::::o",
	"o:k::::::::::::::DD::::::::::::::::::::o",
	"o::::::::::::::::::::::::::::::::::::::o",
	"o:::::::::::::k:::::::::::::k::::::::::o",
	"oooooooooooooooooooooooooooooooooooooooo",
]
const FLOORS := {
	"o": Color("3a3a44"), "#": Color("4c5a70"), ".": Color("c9ccc8"),
	",": Color("8f8c86"), ":": Color("3b4256"),
}
const SOLID := "o#"
const SLOTS := {"s": "S", "g": "G", "n": "N"}

var spawn := Vector2.ZERO
var rock_spots: Array[Vector2] = []
var slots := {}  # station letter -> Array of free Rect2i
var stations: Array[Station] = []
var floor_rects: Array[Rect2] = []
var floor_cells: Array[String] = []  # floor character per cell, stations and items resolved to their ground


func cols() -> int:
	return LAYOUT[0].length()


func rows() -> int:
	return LAYOUT.size()


func char_at(world: Vector2) -> String:
	var c := Vector2i((world / TILE).floor())
	if c.x < 0 or c.y < 0 or c.x >= cols() or c.y >= rows():
		return "o"
	return floor_cells[c.y * cols() + c.x]


func build(item_layer: Node) -> void:
	z_index = -10
	floor_rects = [Rect2(Vector2.ZERO, Vector2(cols(), rows()) * TILE)]
	_resolve_floor()
	_build_walls()
	var seen := {}
	for y in rows():
		for x in cols():
			var ch: String = LAYOUT[y][x]
			var at := Vector2(x + 0.5, y + 1.0) * TILE
			if ch == "@":
				spawn = at - Vector2(0, TILE * 0.3)
			elif ch == "k":
				rock_spots.append(at - Vector2(0, TILE * 0.3))
				ItemDrop.spawn(item_layer, rock_spots.back(), "sample", 1)
			elif ch.is_valid_int():
				_add_station("note", Rect2i(x, y, 1, 1)).state.note = int(ch)
			elif SLOTS.has(ch) and not seen.has(Vector2i(x, y)):
				var letter: String = SLOTS[ch]
				if not slots.has(letter):
					slots[letter] = []
				slots[letter].append(_component(x, y, seen))
			elif Station.KINDS.has(ch) and not seen.has(Vector2i(x, y)):
				_add_station(ch, _component(x, y, seen))
	queue_redraw()


func free_slots(letter: String) -> int:
	return slots.get(letter, []).size()


## Turns the next free slot for `letter` into a station; null when none are left.
func build_slot(letter: String) -> Station:
	if free_slots(letter) == 0:
		return null
	var s := _add_station(letter, slots[letter].pop_front())
	queue_redraw()
	return s


func _add_station(letter: String, cells: Rect2i) -> Station:
	var s := Station.new().setup(letter, Vector2(cells.size) * TILE)
	s.position = Vector2(cells.position.x + cells.size.x * 0.5, cells.end.y) * TILE
	get_parent().add_child.call_deferred(s)
	stations.append(s)
	return s


func _component(x: int, y: int, seen: Dictionary) -> Rect2i:
	var ch: String = LAYOUT[y][x]
	var r := Rect2i(x, y, 1, 1)
	var todo: Array[Vector2i] = [Vector2i(x, y)]
	seen[todo[0]] = true
	while todo:
		var c: Vector2i = todo.pop_back()
		r = r.expand(c).expand(c + Vector2i.ONE)
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = c + d
			if n.x >= 0 and n.y >= 0 and n.x < cols() and n.y < rows() and not seen.has(n) and LAYOUT[n.y][n.x] == ch:
				seen[n] = true
				todo.append(n)
	return r


# Stations, items, notes and the spawn sit on whatever floor surrounds them.
func _resolve_floor() -> void:
	floor_cells.clear()
	for y in rows():
		for x in cols():
			floor_cells.append(LAYOUT[y][x])
	var changed := true
	while changed:
		changed = false
		for y in rows():
			for x in cols():
				var i := y * cols() + x
				if FLOORS.has(floor_cells[i]):
					continue
				for d in [Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP]:
					var n: Vector2i = Vector2i(x, y) + d
					if n.x < 0 or n.y < 0 or n.x >= cols() or n.y >= rows():
						continue
					var f: String = floor_cells[n.y * cols() + n.x]
					if FLOORS.has(f) and not SOLID.contains(f):
						floor_cells[i] = f
						changed = true
						break


# One box per horizontal run of solid cells.
func _build_walls() -> void:
	var body := StaticBody2D.new()
	for y in rows():
		var x := 0
		while x < cols():
			if not SOLID.contains(LAYOUT[y][x]):
				x += 1
				continue
			var start := x
			while x < cols() and SOLID.contains(LAYOUT[y][x]):
				x += 1
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(x - start, 1) * TILE
			shape.shape = rect
			shape.position = Vector2((start + x) * 0.5, y + 0.5) * TILE
			body.add_child(shape)
	add_child(body)


func _draw() -> void:
	var grid := Color(0, 0, 0, 0.12)
	for y in rows():
		for x in cols():
			var f := floor_cells[y * cols() + x]
			var r := Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE))
			draw_rect(r, FLOORS[f])
			if f == "o":
				draw_circle(r.get_center(), TILE * 0.42, Color("55555f"))
			elif f == "#":
				draw_rect(r.grow(-6), Color("5d6d86"))
			else:
				draw_rect(r, grid, false, 2.0)
	for letter in slots:
		for cells in slots[letter]:
			var r := Rect2(Vector2(cells.position) * TILE, Vector2(cells.size) * TILE).grow(-8)
			_dashed_rect(r, Color(1, 1, 1, 0.45))
			draw_string(ThemeDB.fallback_font, Vector2(r.position.x, r.get_center().y + 8), "+", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 28, Color(1, 1, 1, 0.55))
	var font := ThemeDB.fallback_font
	for label in [["SOLAR FIELD", Vector2(19.5, 1.5)], ["GREENHOUSE", Vector2(12.5, 7.75)], ["HAB", Vector2(26, 7.75)],
			["LAB", Vector2(12.5, 22.75)], ["LIFE SUPPORT", Vector2(26, 22.75)], ["SHACKLETON CRATER", Vector2(19.5, 29.8)]]:
		var at: Vector2 = label[1] * TILE
		draw_string(font, at - Vector2(200, 0), label[0], HORIZONTAL_ALIGNMENT_CENTER, 400, 22, Color(0, 0, 0, 0.55))


func _dashed_rect(r: Rect2, c: Color) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		draw_dashed_line(pts[i], pts[(i + 1) % 4], c, 3.0, 10.0)
