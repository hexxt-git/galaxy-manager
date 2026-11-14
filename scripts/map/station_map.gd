extends Node2D

## Builds the station from the layout tables below: room floors, walls with doors, props and collisions.
## Everything is authored in art pixels and drawn at SCALE, matching the sprites' native density.
## Must be a y-sorted child of a y-sorted node so walls and props sort with the player.

const SCALE := 2.0
const SEG := 64             # wall_h tiling period
const WALL_ORIGIN_Y := 109  # wall_h / wall_door / wall_fill / wall_corner floor line
const WALL_ROWS := 115      # their height
const WALL_FACE := 94       # rows above this height are wall top; the face (or a side wall's top) below
const CORNER_W := 18        # side wall width
const END_W := 10           # wall_corner pieces reach this far in from the outer edge
const MERGE_GAP := 30       # side walls closer than this are drawn as one
# Per column kind (bit 1: a side wall above, bit 2: one below; see wall_h.js), indexed by kind.
const KIND_FILL := ["", "wall_fill_a", "wall_fill_b", "wall_v"]
const KIND_END := ["wall_corner", "wall_corner_a", "wall_corner_b", ""]
const WALL_DEPTH := 16      # side wall overlap past the floor line, for collision
const WALL_TUCK := 32       # how far past a horizontal wall's top edge you can walk, half hidden behind it
const DOOR_GAP := Vector2(34, 94)  # opening inside wall_door, x range

const PROP_DIR := "res://assets/art/props/"
const FLOOR_DIR := "res://assets/art/"
const WORKSTATION := preload("res://scenes/workstation.tscn")

# origin and floor footprint in art px; footprint Rect2 is relative to the origin, or a Vector2 for ellipse radii
const PROPS := {
	"crate": {"origin": Vector2(31, 58), "foot": Rect2(-27, -22, 54, 22)},
	"plant": {"origin": Vector2(33, 69), "foot": Rect2(-12, -12, 24, 12)},
	"canister": {"origin": Vector2(24, 66), "foot": Rect2(-18, -20, 36, 20)},
	"locker": {"origin": Vector2(30, 86), "foot": Rect2(-25, -14, 50, 14)},
	"vent": {"origin": Vector2(33, 36), "foot": null},
	"table_set": {"origin": Vector2(158, 124), "foot": Vector2(152, 110)},
}

# x: inner left, segs: width in wall segments, back/front: floor lines.
# back_wall false when the room shares the wall of the room above it.
const ROOMS := [
	{"name": "Cafeteria", "x": 0, "segs": 16, "back": 0, "front": 720, "back_wall": true, "doors": [2, 11], "floor": "floor_tile"},
	{"name": "Storage", "x": 0, "segs": 7, "back": 720, "front": 1200, "back_wall": false, "doors": [], "floor": "floors/storage"},
	{"name": "Control", "x": 512, "segs": 8, "back": 720, "front": 1200, "back_wall": false, "doors": [], "floor": "floors/control"},
]

# Lockers sit on the wall line behind them (y = wall + footprint depth), so nothing fits behind.
const LAYOUT := [
	["table_set", Vector2(290, 330)],
	["table_set", Vector2(734, 330)],
	["plant", Vector2(40, 60)],
	["plant", Vector2(984, 60)],
	["plant", Vector2(512, 60)],
	["canister", Vector2(40, 560)],
	["canister", Vector2(984, 560)],
	["locker", Vector2(30, 734)],
	["locker", Vector2(80, 734)],
	["locker", Vector2(130, 734)],
	["crate", Vector2(330, 880)],
	["crate", Vector2(342, 940)],
	["crate", Vector2(272, 1010)],
	["canister", Vector2(40, 1060)],
	["canister", Vector2(90, 1075)],
	["plant", Vector2(410, 770)],
	["vent", Vector2(640, 1010)],
	["plant", Vector2(560, 1070)],
	["canister", Vector2(984, 1070)],
]

const STATIONS := [
	["Navigation", Vector2(880, 790)],
	["Life Support", Vector2(970, 790)],
]

var _textures := {}
var _strips := []  # side walls: [x0, x1, top floor line, bottom floor line]
var _walls := {}   # floor line -> [[x0, x1, doors], ...]
var _h_sight := []  # horizontal wall pieces that block sight: [x0, x1, floor line]
var _v_sight := []  # side walls: [x0, x1, top floor line, bottom floor line]


func _ready() -> void:
	y_sort_enabled = true
	for room in ROOMS:
		_build_room(room)
	_build_walls()
	for entry in LAYOUT:
		_add_prop(entry[0], entry[1])
	for entry in STATIONS:
		var ws: Node2D = WORKSTATION.instantiate()
		ws.title = entry[0]
		ws.position = entry[1] * SCALE
		add_child(ws)


func _tex(name: String) -> Texture2D:
	if name not in _textures:
		_textures[name] = load(PROP_DIR + name + ".png")
	return _textures[name]


func _sprite(tex: Texture2D, pos: Vector2, origin: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.offset = -origin
	s.scale = Vector2(SCALE, SCALE)
	s.position = pos * SCALE
	return s


func _solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size * SCALE
	shape.shape = r
	body.position = rect.get_center() * SCALE
	body.add_child(shape)
	add_child(body)


func _build_room(room: Dictionary) -> void:
	var x0: float = room.x
	var x1: float = room.x + room.segs * SEG
	var back: float = room.back
	var front: float = room.front

	# Floor: a world-aligned region of the repeating tile, so neighbouring rooms line up.
	var floor_top := back - WALL_ORIGIN_Y if room.back_wall else back
	var fl := Sprite2D.new()
	fl.texture = load(FLOOR_DIR + room.floor + ".png")
	fl.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	fl.region_enabled = true
	fl.region_rect = Rect2(x0, floor_top, x1 - x0, front - floor_top)
	fl.centered = false
	fl.scale = Vector2(SCALE, SCALE)
	fl.position = Vector2(x0, floor_top) * SCALE
	fl.z_index = -10
	fl.z_as_relative = false
	add_child(fl)

	_strips.append([x0 - CORNER_W, x0, back, front])
	_strips.append([x1, x1 + CORNER_W, back, front])
	if room.back_wall:
		_add_wall(back, [x0, x1, []])
	_add_wall(front, [x0, x1, room.doors])


func _add_wall(y: float, wall: Array) -> void:
	if y not in _walls:
		_walls[y] = []
	_walls[y].append(wall)


func _build_walls() -> void:
	_strips.sort_custom(func(a, b): return a[0] < b[0])
	var strips := []
	for s in _strips:
		var joined := false
		for m in strips:
			if m[2] == s[2] and m[3] == s[3] and s[0] - m[1] <= MERGE_GAP:
				m[1] = maxf(m[1], s[1])
				joined = true
		if not joined:
			strips.append(s.duplicate())

	# Side walls are flat lit tops drawn under everything; their ends hide under the wall bands.
	for s in strips:
		var top: float = s[2]
		var h: float = s[3] - WALL_FACE - top
		for part in [["wall_v", s[0], s[1] - s[0]], ["wall_ink", s[0] - 2, 4], ["wall_ink", s[1] - 2, 4]]:
			var spr := _tiled(part[0], Rect2(part[1], top, part[2], h), top)
			spr.z_index = -5
			spr.z_as_relative = false
		_solid(Rect2(s[0], top - WALL_DEPTH, s[1] - s[0], s[3] - top + WALL_DEPTH))
		_v_sight.append(s)

	for y in _walls:
		for w in _walls[y]:
			_build_wall(w[0], w[1], y, w[2])
		_build_joins(y, _walls[y], strips)


# Horizontal walls are solid over their drawn height, less WALL_TUCK, so you can only half hide behind a front face.
func _build_wall(x0: float, x1: float, y: float, doors: Array) -> void:
	var origin := Vector2(0, WALL_ORIGIN_Y)
	var depth := float(WALL_ORIGIN_Y - WALL_TUCK)
	var segs := int((x1 - x0) / SEG)
	# reaches past the ends into the side walls, so shadows have no gaps at corners
	var sight_from := x0 - CORNER_W - MERGE_GAP
	var i := 0
	while i < segs:
		var x := x0 + i * SEG
		if i in doors:
			add_child(_sprite(_tex("wall_door"), Vector2(x, y), origin))
			_solid(Rect2(x, y - depth, DOOR_GAP.x, depth))
			_solid(Rect2(x + DOOR_GAP.y, y - depth, 2 * SEG - DOOR_GAP.y, depth))
			_h_sight.append([sight_from, x + DOOR_GAP.x, y])
			sight_from = x + DOOR_GAP.y
			i += 2
			continue
		add_child(_sprite(_tex("wall_h"), Vector2(x, y), origin))
		_solid(Rect2(x, y - depth, SEG, depth))
		i += 1
	_h_sight.append([sight_from, x1 + CORNER_W + MERGE_GAP, y])


## Lines (in world px) that block sight from eye. Each wall blocks along its edge farthest from chooser
## (normally the eye), so the wall itself stays visible and its shadow starts where the floor beyond it begins.
func sight_segments(eye: Vector2, chooser: Vector2) -> Array:
	var c := chooser / SCALE
	var edge := func(y: float) -> float: return y if c.y < y - WALL_ORIGIN_Y / 2.0 else y - WALL_ORIGIN_Y
	var out := []
	for h in _h_sight:
		var y: float = edge.call(h[2])
		out.append([Vector2(h[0], y) * SCALE, Vector2(h[1], y) * SCALE])
	# side walls run between the horizontal walls' blocking lines; reaching past them would cut into a visible wall face
	for v in _v_sight:
		var x: float = v[1] if c.x < (v[0] + v[1]) / 2.0 else v[0]
		out.append([Vector2(x, edge.call(v[2])) * SCALE, Vector2(x, edge.call(v[3])) * SCALE])
	return out


## Which edge of every wall blocks sight from eye; changes exactly when sight_segments would switch edges.
func sight_key(eye: Vector2) -> Array:
	var e := eye / SCALE
	var key := []
	for y in _walls:
		key.append(e.y < y - WALL_ORIGIN_Y / 2.0)
	for v in _v_sight:
		key.append(e.x < (v[0] + v[1]) / 2.0)
	return key


# Splits the band along floor line y into runs of one column kind (-1: nothing) and draws fills over wall_h,
# ink seams wherever neighbouring kinds differ, and wall_corner pieces at the outer ends.
func _build_joins(y: float, walls: Array, strips: Array) -> void:
	var spans := []
	for w in walls:
		spans.append([w[0], w[1], 0])
	for s in strips:
		if s[3] == y:
			spans.append([s[0], s[1], 1])
		elif s[2] == y:
			spans.append([s[0], s[1], 2])
	var cuts := []
	for sp in spans:
		for x in [sp[0], sp[1]]:
			if x not in cuts:
				cuts.append(x)
	cuts.sort()
	var runs := [[cuts[0], cuts[0], -1]]
	for i in cuts.size() - 1:
		var mid: float = (cuts[i] + cuts[i + 1]) / 2.0
		var kind := -1
		for sp in spans:
			if sp[0] < mid and mid < sp[1]:
				kind = maxi(kind, 0) | sp[2]
		if kind == runs.back()[2]:
			runs.back()[1] = cuts[i + 1]
		else:
			runs.append([cuts[i], cuts[i + 1], kind])
	runs.append([cuts.back(), cuts.back(), -1])

	var top := y - WALL_ORIGIN_Y
	for i in range(1, runs.size() - 1):
		var r: Array = runs[i]
		if r[2] <= 0:
			continue
		var a: float = r[0]
		var b: float = r[1]
		if r[2] != 3:
			a += END_W if runs[i - 1][2] == -1 else 0
			b -= END_W if runs[i + 1][2] == -1 else 0
		_tiled(KIND_FILL[r[2]], Rect2(a, top, b - a, WALL_ROWS), y)
	for i in runs.size() - 1:
		var l: int = runs[i][2]
		var r: int = runs[i + 1][2]
		var e: float = runs[i][1]
		if l == -1 or r == -1:
			var kind := r if l == -1 else l
			if kind == 3:
				_tiled("wall_ink", Rect2(e - 2, top, 4, WALL_ROWS), y)
			elif kind != -1:
				var end := _sprite(_tex(KIND_END[kind]), Vector2(e, y), Vector2(2, WALL_ORIGIN_Y))
				if r == -1:
					end.scale.x = -SCALE
				add_child(end)
			continue
		# lit top rows differ when exactly one side has a wall above, lower rows when one has a wall below
		if (l ^ r) & 1:
			_tiled("wall_ink", Rect2(e - 2, top, 4, 4), y)
		if (l ^ r) & 2:
			_tiled("wall_ink", Rect2(e - 2, y - WALL_FACE, 4, WALL_FACE + WALL_ROWS - WALL_ORIGIN_Y), y)


# A texture repeated over rect, y-sorted at sort_y.
func _tiled(name: String, rect: Rect2, sort_y: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _tex(name)
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, rect.size)
	s.centered = false
	s.scale = Vector2(SCALE, SCALE)
	s.position = Vector2(rect.position.x, sort_y) * SCALE
	s.offset = Vector2(0, rect.position.y - sort_y)
	add_child(s)
	return s


func _add_prop(name: String, pos: Vector2) -> void:
	var spec: Dictionary = PROPS[name]
	var s := _sprite(_tex(name), pos, spec.origin)
	if spec.foot == null:
		# flat on the floor: never covers anyone
		s.z_index = -8
		s.z_as_relative = false
	add_child(s)
	if spec.foot is Rect2:
		var foot: Rect2 = spec.foot
		_solid(Rect2(pos + foot.position, foot.size))
	elif spec.foot is Vector2:
		var radii: Vector2 = spec.foot
		var body := StaticBody2D.new()
		var poly := CollisionPolygon2D.new()
		var pts := PackedVector2Array()
		for k in 20:
			var a := TAU * k / 20.0
			pts.append(Vector2(cos(a) * radii.x, sin(a) * radii.y) * SCALE)
		poly.polygon = pts
		body.position = pos * SCALE
		body.add_child(poly)
		add_child(body)
