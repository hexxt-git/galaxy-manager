class_name ColonyMap
extends Node2D

## Placeholder grid map built from LAYOUT, one character per TILE.
##   o boulder   # wall   , moon surface   : crater floor
##   room floors: _ greenhouse   . hab   = lab   - life support
##   @ spawn   1-9 notes   k loose moon rock
##   s g n: empty slots that upgrades build a solar panel, grow bed or reactor into
##   other letters: stations and decor (see Station.KINDS); touching cells with the same letter form one.

const TILE := 96.0
const LAYOUT := [
	"oooooooooooooooooooooooooooooooooooooooooooooooo",
	"o,,,,,,,,,,,,,,,,,,k,,,,,,,,,,,,,,,,,,,,,,,,,,,o",
	"o,,,,sss,,,sss,,,SSS,,,,,,,SSS,,,sss,,,sss,,,,,o",
	"o,,,,sss,,,sss,,,SSS,,,,,,,SSS,,,sss,,,sss,,,,,o",
	"o,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,k,,o",
	"o,k,,,,,,,,,,,,,,,,,,,,6,,,,,,,,,,,,,,,,,,,,,,,o",
	"o,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,d,,,,,o",
	"o,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,d,o",
	"o,,,,,,,#######__#############..########,,,,,,,o",
	"o,,,,,,,#p__3_________p#.cccm.....m.bb.#,,,,,,,o",
	"o,,RR,,,#_gg_GG__GG_gg_#.ccc...........#,,,,,,,o",
	"o,,,,,,,#______________#....8.......bb.#,,ww,,,o",
	"o,,,,,,,_______________........@..1.....,,,,,,,o",
	"o,,,,,,,_______________.................,,,,,,,o",
	"o,,,,,,,#_hh_gg__gg_hh_#.nn2.....QQ....#,,,,,,,o",
	"o,,,,,,,#______________#...............#,,,,,,,o",
	"o,,,,,,,#######__#############..########,,,,,,,o",
	"o,,,,,,,#=f==f====y=y=y#-WWWjj--EE-OO9-#,,,,,,,o",
	"o,,,,,,,#==LL=5========#-WWW-----------#,,RR,,,o",
	"o,,,,,,,#==LL==========#-----4---------#,,,,,,,o",
	"o,,k,,,,===============-----------------,,,,,,,o",
	"o,,,,,,,===============-----------------,,,,,,,o",
	"o,,,,,,,#v============x#v-------------v#,,,,,,,o",
	"o,,,,,,,#==============#---------------#,,,,,,,o",
	"o,,,d,,,#######==#############--########,,,,,,,o",
	"o,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,k,,o",
	"o,,,,,,,,,,,,,,,,,,,k,,,,,,,,,,,,,,,,,,,,,,,,,,o",
	"o::o:::oo::::::ooo::::o:::::oo::::::o:::ooo:o::o",
	"o::::::::::o:::::::::::::::::::::o:::::::::::::o",
	"o:::::::::::::::::::::::::::::::::::k::::::::::o",
	"o:::::::k::::::::::::::::::::::::::::::::::::::o",
	"o::::::::::::::::::::7:DD:aa::::::::::::::k::::o",
	"o::::::::::::::::::::::::::::::::::::::::::::::o",
	"o:::::::::::::k::::::::::::::::k:::::::::::::::o",
	"o::::::::::::::::::::::::::::::::::::::::::::::o",
	"oooooooooooooooooooooooooooooooooooooooooooooooo",
]
const FLOORS := {
	"o": Color("3a3a44"), "#": Color("4c5a70"), ".": Color("c9b9a4"), "_": Color("a9c49a"),
	"=": Color("d4dcdc"), "-": Color("9aa4ae"), ",": Color("8f8c86"), ":": Color("3b4256"),
}
const SOLID := "o#"
const ART := "res://assets/art/colony/"
const PROPS := "res://assets/art/props/"
const PX := 2.0  # screen px per art px
const CELL := 48  # art px per tile
const GROUND_ART := {"_": "floor_greenhouse", ".": "floor_hab", "=": "floor_lab", "-": "floor_lifesupport",
	",": "regolith", ":": "crater"}
const FONT := preload("res://assets/fonts/fredoka_bold.tres")
const FLOOR_AO := preload("res://assets/shaders/floor_ao.gdshader")
const ROOMS := [Rect2i(9, 9, 14, 7), Rect2i(24, 9, 15, 7), Rect2i(9, 17, 14, 7), Rect2i(24, 17, 15, 7)]  # interior cells
const AO_RADIUS := 70.0
const AO_REACH := 266.0
const AO_STRENGTH := 0.22
const DECAL_PREFIX := {"_": "greenhouse", ".": "hab", "=": "lab", "-": "lifesupport", ",": "regolith", ":": "crater"}
const DECAL_CELLS := {"_": 14.0, ".": 14.0, "=": 14.0, "-": 14.0, ",": 18.0, ":": 18.0}  # cells of floor per decal
# floor below the wall -> wall details to pick from; [file, cells wide]. Each covers the wall's front face.
const WALL_DECO := {
	"_": [["shelf_plants", 1], ["light", 1]],
	".": [["poster", 1], ["light", 1], ["screen", 1]],
	"=": [["screen", 1], ["vent", 1]],
	"-": [["pipes", 2], ["vent", 1], ["screen", 1]],
	",": [["vent", 1], ["light", 1]],
}
const WALL_DECO_CHANCE := 0.4
const WALL_FACE := 52  # art px of wall front face, up from the cell's bottom edge
const WALL_STRIP := 22  # art px a lone vertical wall cell blocks, centred
# Wall tiles: a 16 px cap at x16..32 of the cell for vertical runs; horizontal runs stand on the cell's bottom 16 px,
# with the cap WALL_CAP_UP px above the cell's top edge.
const WALL_LINE := 40  # art px down a horizontal wall's cell where its footprint is centred
const WALL_CAP_UP := 20  # art px of wall front below the top face
# rock sprite -> [origin, half its ground contact in art px]
const ROCKS := {
	"boulder_a": [Vector2(41, 108), 34], "boulder_b": [Vector2(64, 58), 57], "boulder_c": [Vector2(52, 84), 45],
	"boulder_d": [Vector2(54, 94), 42], "boulder_big": [Vector2(76, 94), 67], "boulder_e": [Vector2(23, 38), 18],
	"boulder_f": [Vector2(46, 56), 39], "boulder_g": [Vector2(32, 84), 25], "boulder_h": [Vector2(44, 52), 36],
}
# crater rim: a run of `o` cells -> rocks that fit it; one rock per run, blocking only its own footprint
const RIM_ROCKS := {1: ["boulder_g", "boulder_f", "boulder_a", "boulder_h"], 2: ["boulder_c", "boulder_d", "boulder_b"],
	3: ["boulder_big", "boulder_b"]}
const RIM_DEPTH := 16.0  # art px, front to back, of a rim rock's blocking footprint
# Map border: bands of rocks past the walkable edge, nearest first, fading into the outside darkness.
# [art px past the edge, gap between rock centres along the left / right edges, chance of a hole, rocks]
const EDGE_BANDS := [
	[Vector2(0, 24), Vector2(34, 60), 0.2, ["boulder_e", "boulder_f", "boulder_g", "boulder_h", "boulder_a", "boulder_c", "boulder_d"]],
	[Vector2(30, 56), Vector2(44, 76), 0.1, ["boulder_a", "boulder_b", "boulder_c", "boulder_d", "boulder_h", "boulder_big", "boulder_g"]],
	[Vector2(92, 140), Vector2(56, 96), 0.0, ["boulder_big", "boulder_b", "boulder_c", "boulder_d", "boulder_a"]],
]
# the bottom edge stands in front of the map, so it gets low rocks: [nearest band, next band]
const EDGE_LOW := [["boulder_b", "boulder_h", "boulder_f", "boulder_c", "boulder_big"], ["boulder_e", "boulder_f", "boulder_h", "boulder_b"]]
const EDGE_MARGIN := 6  # cells of ground drawn past the map, under the outside darkness
const SLOTS := {"s": "S", "g": "G", "n": "N"}

var spawn := Vector2.ZERO
var rock_spots: Array[Vector2] = []
var slots := {}  # station letter -> Array of free Rect2i
var stations: Array[Station] = []
var floor_rects: Array[Rect2] = []
var floor_cells: Array[String] = []  # floor character per cell, stations and items resolved to their ground
var ground_art := false
var _h_sight: Array = []  # [x0, x1, base y, cap top y] per horizontal wall run, world px
var _v_sight: Array = []  # [x0, x1, top y, bottom y] per vertical wall run, world px
var ground_texture: Texture2D  # the playable area's ground only, for the minimap
var _pads := {}  # large footprint? -> empty building pad


## Loads art whether or not the editor has imported it yet.
static func texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	if not FileAccess.file_exists(path):
		return null
	return ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(path)))


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
	_build_sight()
	get_parent().texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pads = {true: texture(PROPS + "pad_large.png"), false: texture(PROPS + "pad_small.png")}
	_build_ground()
	_place_wall_art()
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


func _ground_of(x: int, y: int) -> String:
	var f := floor_cells[y * cols() + x]
	if not SOLID.contains(f):
		return f
	for d in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
		var n: Vector2i = Vector2i(x, y) + d
		if n.x >= 0 and n.y >= 0 and n.x < cols() and n.y < rows() and floor_cells[n.y * cols() + n.x] == ":":
			return ":"
	return ","


func _build_ground() -> void:
	var tiles := {}
	for f in GROUND_ART:
		var t := texture(ART + GROUND_ART[f] + ".png")
		if t == null:
			return
		var img := t.get_image()
		img.convert(Image.FORMAT_RGBA8)
		tiles[f] = img
	var kinds := PackedStringArray()
	for y in rows():
		for x in cols():
			kinds.append(_ground_of(x, y))
	var ground := Image.create(cols() * CELL, rows() * CELL, false, Image.FORMAT_RGBA8)
	var sills := []
	for f in ["sill_h", "sill_v"]:
		var t := texture(ART + f + ".png")
		var img := t.get_image() if t else null
		if img:
			img.convert(Image.FORMAT_RGBA8)
		sills.append(img)
	var doorways := []  # [sill image, centre]
	for y in rows():
		for x in cols():
			var f := kinds[y * cols() + x]
			_blit(ground, tiles[f], Rect2i(Vector2i(x, y) * CELL, Vector2i(CELL, CELL)))
			if SOLID.contains(LAYOUT[y][x]):
				continue
			var half := CELL / 2
			# doorways: the floor changes on the wall's line, the middle of its footprint
			if _is_wall(x - 1, y) or _is_wall(x + 1, y):
				var up := _kind_at(kinds, x, y - 1)
				var down := _kind_at(kinds, x, y + 1)
				if up != "" and down != "" and up != down:
					_blit(ground, tiles[up], Rect2i(x * CELL, y * CELL, CELL, WALL_LINE))
					_blit(ground, tiles[down], Rect2i(x * CELL, y * CELL + WALL_LINE, CELL, CELL - WALL_LINE))
					if _is_wall(x - 1, y):
						doorways.append([sills[0], Vector2i((x + 1) * CELL, y * CELL + WALL_LINE)])
			if _is_wall(x, y - 1) or _is_wall(x, y + 1):
				var left := _kind_at(kinds, x - 1, y)
				var right := _kind_at(kinds, x + 1, y)
				if left != "" and right != "" and left != right:
					_blit(ground, tiles[left], Rect2i(x * CELL, y * CELL, half, CELL))
					_blit(ground, tiles[right], Rect2i(x * CELL + half, y * CELL, half, CELL))
					if _is_wall(x, y - 1):
						doorways.append([sills[1], Vector2i(x * CELL + half, (y + 1) * CELL)])
	_floor_beside_walls(ground, tiles, kinds)
	_roughen_edges(ground, tiles, kinds)
	_scatter_decals(ground, kinds)
	for d in doorways:
		var img: Image = d[0]
		if img:
			ground.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), d[1] - img.get_size() / 2)
	ground_texture = ImageTexture.create_from_image(ground)
	var m := EDGE_MARGIN * CELL
	var full := Image.create(ground.get_width() + 2 * m, ground.get_height() + 2 * m, false, Image.FORMAT_RGBA8)
	full.blit_rect(ground, Rect2i(Vector2i.ZERO, ground.get_size()), Vector2i(m, m))
	# the map's corner cells too: _ground_of can't tell they're crater
	for y in range(-EDGE_MARGIN, rows() + EDGE_MARGIN):
		for x in range(-EDGE_MARGIN, cols() + EDGE_MARGIN):
			var inside := x >= 0 and y >= 0 and x < cols() and y < rows()
			if inside and not ((x == 0 or x == cols() - 1) and (y == 0 or y == rows() - 1)):
				continue
			var k := kinds[clampi(y, 1, rows() - 2) * cols() + clampi(x, 1, cols() - 2)]
			_blit(full, tiles[k], Rect2i((x + EDGE_MARGIN) * CELL, (y + EDGE_MARGIN) * CELL, CELL, CELL))
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(full)
	sprite.centered = false
	sprite.scale = Vector2(PX, PX)
	sprite.position = -Vector2(m, m) * PX
	add_child(sprite)
	ground_art = true
	for room in ROOMS:
		_floor_ao(_visible_floor(room))


## The floor of a room you can actually see, in world px: between the vertical wall strips, from the face of the wall
## above down to the cap of the wall below.
func _visible_floor(room: Rect2i) -> Rect2:
	var left := ((room.position.x - 1) * CELL + 32) * PX
	var right := ((room.end.x) * CELL + 16) * PX
	var top := room.position.y * CELL * PX
	var bottom := (room.end.y * CELL - WALL_CAP_UP) * PX
	return Rect2(left, top, right - left, bottom - top)


func _floor_ao(rect: Rect2) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = FLOOR_AO
	mat.set_shader_parameter("rect_pos", rect.position)
	mat.set_shader_parameter("rect_size", rect.size)
	mat.set_shader_parameter("radius", AO_RADIUS)
	mat.set_shader_parameter("reach", AO_REACH)
	mat.set_shader_parameter("strength", AO_STRENGTH)
	mat.set_shader_parameter("pixel", PX * 2.0)
	var ao := ColorRect.new()
	ao.material = mat
	ao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ao.position = rect.position
	ao.size = rect.size
	ao.z_index = -7
	ao.z_as_relative = false
	add_child(ao)


# Walls are thin, so the ground under a wall cell shows around them. A horizontal wall cell takes the floor above its
# wall line from the cell above and below it from the cell below, like a doorway; a vertical one takes each side's floor.
func _floor_beside_walls(ground: Image, tiles: Dictionary, kinds: PackedStringArray) -> void:
	for y in rows():
		for x in cols():
			if LAYOUT[y][x] != "#":
				continue
			var up := _kind_at(kinds, x, y - 1)
			var down := _kind_at(kinds, x, y + 1)
			if (_is_wall(x - 1, y) or _is_wall(x + 1, y)) and (up != "" or down != ""):
				up = up if up != "" else down
				down = down if down != "" else up
				_blit(ground, tiles[up], Rect2i(x * CELL, y * CELL, CELL, WALL_LINE))
				_blit(ground, tiles[down], Rect2i(x * CELL, y * CELL + WALL_LINE, CELL, CELL - WALL_LINE))
				continue
			var half := CELL / 2
			for side in [[0, [Vector2i(-1, 0), Vector2i(1, 0)]], [half, [Vector2i(1, 0), Vector2i(-1, 0)]]]:
				var kind := ""
				for d in side[1] + [Vector2i(0, 1), Vector2i(0, -1)]:
					kind = _kind_at(kinds, x + d.x, y + d.y)
					if kind != "":
						break
				if kind != "":
					_blit(ground, tiles[kind], Rect2i(x * CELL + side[0], y * CELL, half, CELL))


## Fills `r` with `src` tiled from the map's origin.
func _blit(to: Image, src: Image, r: Rect2i) -> void:
	var y := r.position.y
	while y < r.end.y:
		var sy := y % src.get_height()
		var h := mini(src.get_height() - sy, r.end.y - y)
		var x := r.position.x
		while x < r.end.x:
			var sx := x % src.get_width()
			var w := mini(src.get_width() - sx, r.end.x - x)
			to.blit_rect(src, Rect2i(sx, sy, w, h), Vector2i(x, y))
			x += w
		y += h


## Ground kind of a walkable cell, or "" for walls, boulders and off-map.
func _kind_at(kinds: PackedStringArray, x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= cols() or y >= rows() or SOLID.contains(LAYOUT[y][x]):
		return ""
	return kinds[y * cols() + x]


const EDGE_WARP := 7.0  # art px the regolith / crater border wanders


# Outside, the regolith / crater border is pushed around by blobby noise, with a shadow under the crater lip,
# so it doesn't run along the grid.
func _roughen_edges(ground: Image, tiles: Dictionary, kinds: PackedStringArray) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.04
	noise.fractal_octaves = 1
	var kind_px := func(px: float, py: float) -> String:
		var cx := clampi(int(px) / CELL, 0, cols() - 1)
		var cy := clampi(int(py) / CELL, 0, rows() - 1)
		return kinds[cy * cols() + cx]
	var lip := Color(0, 0, 0, 0.16)
	for y in rows():
		for x in cols():
			var f := kinds[y * cols() + x]
			if not ",:".contains(f):
				continue
			var mixed := false
			for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var n: Vector2i = Vector2i(x, y) + d
				if n.x >= 0 and n.y >= 0 and n.x < cols() and n.y < rows() and ",:".contains(kinds[n.y * cols() + n.x]) and kinds[n.y * cols() + n.x] != f:
					mixed = true
			if not mixed:
				continue
			for py in range(y * CELL, (y + 1) * CELL):
				for px in range(x * CELL, (x + 1) * CELL):
					var wx := px + noise.get_noise_2d(px, py) * EDGE_WARP
					var wy := py + noise.get_noise_2d(px + 911, py) * EDGE_WARP
					var k: String = kind_px.call(wx, wy)
					if not ",:".contains(k):
						continue
					var src: Image = tiles[k]
					var c := src.get_pixel(px % src.get_width(), py % src.get_height())
					if k == ":" and kind_px.call(wx, wy - 2.0) == ",":
						c = c.blend(lip)
					ground.set_pixel(px, py, c)


func _scatter_decals(ground: Image, kinds: PackedStringArray) -> void:
	var dir := ART + "decals/"
	var files := {}
	for f in DirAccess.get_files_at(dir):
		var name := f.trim_suffix(".import")
		if name.ends_with(".png") and not files.has(name):
			files[name] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var taken: Array[Rect2i] = []
	for kind in DECAL_PREFIX:
		var decals: Array[Image] = []
		for name in files:
			if name.begins_with(DECAL_PREFIX[kind] + "_"):
				var img := texture(dir + name).get_image()
				img.convert(Image.FORMAT_RGBA8)
				decals.append(img)
		if decals.is_empty():
			continue
		var cells := kinds.count(kind)
		var want := int(cells / DECAL_CELLS[kind])
		var tries := want * 20
		while want > 0 and tries > 0:
			tries -= 1
			var img: Image = decals[rng.randi() % decals.size()]
			var at := Vector2i(rng.randi_range(0, cols() * CELL - img.get_width()), rng.randi_range(0, rows() * CELL - img.get_height()))
			var r := Rect2i(at, img.get_size())
			if taken.any(func(t: Rect2i) -> bool: return t.intersects(r.grow(12))):
				continue
			var ok := true
			for corner in [r.position, Vector2i(r.end.x - 1, r.position.y), Vector2i(r.position.x, r.end.y - 1), r.end - Vector2i.ONE]:
				var c: Vector2i = corner / CELL
				if SOLID.contains(LAYOUT[c.y][c.x]) or kinds[c.y * cols() + c.x] != kind:
					ok = false
			if not ok:
				continue
			ground.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), at)
			taken.append(r)
			want -= 1


func _is_wall(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < cols() and y < rows() and LAYOUT[y][x] == "#"


func _is_border(x: int, y: int) -> bool:
	return x == 0 or y == 0 or x == cols() - 1 or y == rows() - 1


# Walls and boulders stand in the y-sorted world, sorted by their cell's bottom edge. A wall tile's front face fills
# the lower part of its cell and its top face reaches up into the cell above, the usual 3/4 view trick.
func _place_wall_art() -> void:
	var walls := []
	for m in 16:
		walls.append(texture(ART + "wall_%d.png" % m))
	_rng.seed = 5
	for y in rows():
		for x in cols():
			var ch: String = LAYOUT[y][x]
			var sprite := Sprite2D.new()
			sprite.centered = false
			sprite.scale = Vector2(PX, PX)
			if ch == "#" and walls[0]:
				var mask := int(_is_wall(x, y - 1)) | int(_is_wall(x + 1, y)) << 1 | int(_is_wall(x, y + 1)) << 2 | int(_is_wall(x - 1, y)) << 3
				sprite.texture = walls[mask]
				sprite.position = Vector2(x, y + 1) * TILE
				sprite.offset = Vector2(0, -sprite.texture.get_height())
				sprite.set_meta("wall_line", sprite.position.y)
				if not _is_wall(x, y + 1):
					_decorate_wall(sprite, x, y)
			else:
				sprite.free()
				continue
			get_parent().add_child.call_deferred(sprite)
	for r in _edge_rocks() + _rim_rocks():
		var tex := texture(PROPS + r[0] + ".png")
		if tex == null:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.centered = false
		sprite.scale = Vector2(PX, PX)
		sprite.position = r[1] * PX
		sprite.offset = -ROCKS[r[0]][0]
		sprite.flip_h = r[2]
		get_parent().add_child.call_deferred(sprite)


## Rocks piled past the walkable edge: [sprite, ground contact in art px, flipped].
func _edge_rocks() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var w := float(cols() * CELL)
	var h := float(rows() * CELL)
	var out := []
	for side in 4:  # top, bottom, left, right
		var across := side < 2
		var length := w if across else h
		for b in EDGE_BANDS.size() - int(side == 1):
			var band: Array = EDGE_BANDS[b]
			var pool: Array = EDGE_LOW[b] if side == 1 else band[3]
			var t := rng.randf_range(-170.0, -60.0) if across else rng.randf_range(0.0, 20.0)
			while t < length + (170.0 if across else -20.0):
				var name: String = pool[rng.randi() % pool.size()]
				var half: float = ROCKS[name][1]
				var d := rng.randf_range(band[0].x, band[0].y)
				var at: Vector2
				if across:
					at = Vector2(t + half, CELL - d if side == 0 else h - CELL + 14 + d)
					t += 2.0 * half * rng.randf_range(0.7, 1.0) + (rng.randf_range(10, 40) if rng.randf() < 0.15 else 0.0)
				else:
					at = Vector2(CELL - half - d if side == 2 else w - CELL + half + d, t)
					t += rng.randf_range(band[1].x, band[1].y)
				if rng.randf() >= band[2]:
					out.append([name, at, rng.randf() < 0.5])
	return out


var _rim := []


## One rock per run of `o` cells inside the map: [sprite, ground contact in art px, flipped].
func _rim_rocks() -> Array:
	if not _rim.is_empty():
		return _rim
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for y in range(1, rows() - 1):
		var x := 1
		while x < cols() - 1:
			if LAYOUT[y][x] != "o":
				x += 1
				continue
			var n := 0
			while x + n < cols() - 1 and LAYOUT[y][x + n] == "o":
				n += 1
			var pool: Array = RIM_ROCKS[clampi(n, 1, 3)]
			var at := Vector2((x + n * 0.5) * CELL + rng.randf_range(-6, 6), (y + 1) * CELL - rng.randf_range(0, 6))
			_rim.append([pool[rng.randi() % pool.size()], at, rng.randf() < 0.5])
			x += n
	return _rim


var _deco_until := -1  # wall details don't touch: the next free column on this row
var _rng := RandomNumberGenerator.new()


func _decorate_wall(wall: Sprite2D, x: int, y: int) -> void:
	if x == 0 or y + 1 >= rows():
		return
	if x <= _deco_until:
		return
	var below := _ground_of(x, y + 1)
	if not WALL_DECO.has(below) or _rng.randf() > WALL_DECO_CHANCE:
		return
	var options: Array = WALL_DECO[below].filter(func(d: Array) -> bool:
		for i in range(-1, d[1] + 1):
			if not _is_wall(x + i, y) or (i >= 0 and i < d[1] and _is_wall(x + i, y + 1)):
				return false
		return true)
	if options.is_empty():
		return
	var d: Array = options[_rng.randi() % options.size()]
	var tex := texture(ART + "wall_deco_%s.png" % d[0])
	if tex == null:
		return
	var deco := Sprite2D.new()
	deco.texture = tex
	deco.centered = false
	deco.position = Vector2(0, -WALL_FACE)
	wall.add_child(deco)
	_deco_until = x + d[1]


func _build_sight() -> void:
	var cap := WALL_CAP_UP * PX
	for y in rows():
		var x := 0
		while x < cols():
			if not (_is_wall(x, y) and (_is_wall(x - 1, y) or _is_wall(x + 1, y))):
				x += 1
				continue
			var start := x
			while _is_wall(x, y) and (_is_wall(x - 1, y) or _is_wall(x + 1, y)):
				x += 1
			_h_sight.append([start * TILE, x * TILE, (y + 1) * TILE, y * TILE - cap])
	for x in cols():
		var y := 0
		while y < rows():
			if not (_is_wall(x, y) and (_is_wall(x, y - 1) or _is_wall(x, y + 1))):
				y += 1
				continue
			var start := y
			while _is_wall(x, y) and (_is_wall(x, y - 1) or _is_wall(x, y + 1)):
				y += 1
			_v_sight.append([x * TILE + 16 * PX, x * TILE + 32 * PX, start * TILE - cap, y * TILE])


## Wall edges that block sight from `chooser`. A horizontal wall blocks along its base when seen from the north and
## along its cap when seen from the south, so its face stays visible; a vertical wall along its far side.
func sight_segments(chooser: Vector2) -> Array:
	var out: Array = []
	for h in _h_sight:
		var y: float = h[2] if chooser.y < (h[2] + h[3]) * 0.5 else h[3]
		out.append([Vector2(h[0], y), Vector2(h[1], y)])
	for v in _v_sight:
		var x: float = v[1] if chooser.x < (v[0] + v[1]) * 0.5 else v[0]
		out.append([Vector2(x, v[2]), Vector2(x, v[3])])
	return out


## Which edge of every wall blocks sight from `eye`; changes exactly when sight_segments would switch edges.
func sight_key(eye: Vector2) -> Array:
	var key: Array[bool] = []
	for h in _h_sight:
		key.append(eye.y < (h[2] + h[3]) * 0.5)
	for v in _v_sight:
		key.append(eye.x < (v[0] + v[1]) * 0.5)
	return key


# One box per horizontal run of wall / border cells; each crater rock blocks a capsule under its own base.
func _build_walls() -> void:
	var body := StaticBody2D.new()
	var solid := func(x: int, y: int) -> bool: return LAYOUT[y][x] == "#" or (LAYOUT[y][x] == "o" and _is_border(x, y))
	for y in rows():
		var x := 0
		while x < cols():
			if not solid.call(x, y):
				x += 1
				continue
			var start := x
			while x < cols() and solid.call(x, y):
				x += 1
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(x - start, 1) * TILE
			if x - start == 1 and LAYOUT[y][start] == "#":
				rect.size.x = WALL_STRIP * PX
			shape.shape = rect
			shape.position = Vector2((start + x) * 0.5, y + 0.5) * TILE
			body.add_child(shape)
	for r in _rim_rocks():
		var cap := CapsuleShape2D.new()
		cap.radius = RIM_DEPTH * 0.5 * PX
		cap.height = maxf(ROCKS[r[0]][1] * 2.0, RIM_DEPTH) * PX
		var shape := CollisionShape2D.new()
		shape.shape = cap
		shape.rotation = PI / 2
		shape.position = (r[1] - Vector2(0, RIM_DEPTH * 0.5)) * PX
		body.add_child(shape)
	add_child(body)


func _draw() -> void:
	var grid := Color(0, 0, 0, 0.12)
	for y in rows():
		for x in cols():
			var f := floor_cells[y * cols() + x]
			var r := Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE))
			if ground_art:
				continue
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
			var pad: Texture2D = _pads.get(cells.size.x * cells.size.y > 2)
			if pad:
				draw_set_transform(Vector2(r.get_center().x, r.end.y + 8), 0.0, Vector2(PX, PX))
				draw_texture(pad, -Vector2(pad.get_width() * 0.5, pad.get_height()))
				draw_set_transform(Vector2.ZERO)
				continue
			_dashed_rect(r, Color(1, 1, 1, 0.45))
			draw_string(ColonyMap.FONT, Vector2(r.position.x, r.get_center().y + 8), "+", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 28, Color(1, 1, 1, 0.55))
	var font := ColonyMap.FONT
	for label in [["SOLAR FIELD", Vector2(24, 1.6)], ["GREENHOUSE", Vector2(16, 11.6)], ["HAB", Vector2(31, 11.6)],
			["LAB", Vector2(16, 20.6)], ["LIFE SUPPORT", Vector2(31, 20.6)], ["SHACKLETON CRATER", Vector2(24, 28.6)]]:
		var at: Vector2 = label[1] * TILE - Vector2(200, 0)
		draw_string_outline(font, at, label[0], HORIZONTAL_ALIGNMENT_CENTER, 400, 40, 12, Station.INK)
		draw_string(font, at, label[0], HORIZONTAL_ALIGNMENT_CENTER, 400, 40, Color.WHITE)


func _dashed_rect(r: Rect2, c: Color) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		draw_dashed_line(pts[i], pts[(i + 1) % 4], c, 3.0, 10.0)
