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
const SIDE_DOOR := 48       # floor visible through a side door, between the cap's floor line and the next strip's top

const PROP_DIR := "res://assets/art/props/"
const FLOOR_DIR := "res://assets/art/"
const DECAL_DIR := "res://assets/art/floors/decals/"
# Floor details scattered per room, keyed by floor. Whole-tile ones snap to the floor's tile grid.
const DECALS := {
	"floor_tile": ["cafeteria_crack", "cafeteria_drain", "cafeteria_scuff", "cafeteria_stain"],
	"floors/storage": ["storage_hatch", "storage_hazard", "storage_oil", "storage_scuff"],
	"floors/control": ["control_cable_cover", "control_scorch", "control_grate"],
}
const DECAL_SNAP := {"storage_hatch": 56, "storage_hazard": 56}
const DECAL_AREA := {"floor_tile": 45000.0, "floors/storage": 14000.0, "floors/control": 14000.0}  # art px² of floor per decal
const WORKSTATION := preload("res://scenes/workstation.tscn")
const ROOM_LIGHT := preload("res://assets/shaders/room_light.gdshader")
const FLOOR_AO := preload("res://assets/shaders/floor_ao.gdshader")
const Vision := preload("res://scripts/map/vision.gd")
# Corner darkening on floors. Each point of light below 1 adds the *_DIM amounts, so dim rooms get deeper corners.
const AO_RADIUS := 35.0   # art px out of the corner
const AO_REACH := 133.0   # art px along the walls
const AO_STRENGTH := 0.18
const AO_DIM_RADIUS := 52.5
const AO_DIM_REACH := 245.0
const AO_DIM_STRENGTH := 0.9
const AO_Z := -7  # over floors, decals and the vent; under the sight overlay (-6) and everything standing

# origin and floor footprint in art px; footprint Rect2 is relative to the origin, or a Vector2 for ellipse radii
const PROPS := {
	"crate": {"origin": Vector2(33, 58), "foot": Rect2(-27, -22, 54, 22)},
	"plant": {"origin": Vector2(24, 49), "foot": Rect2(-8, -8, 17, 8)},
	"canister": {"origin": Vector2(20, 51), "foot": Rect2(-14, -15, 28, 15)},
	"locker": {"origin": Vector2(30, 86), "foot": Rect2(-25, -14, 50, 14)},
	"vent": {"origin": Vector2(29, 31), "foot": null},
	"table_set": {"origin": Vector2(122, 104), "foot": Vector2(118, 86)},
	"electrical_panel": {"origin": Vector2(90, 87), "foot": Rect2(-84, -16, 168, 16)},
	"shelf": {"origin": Vector2(33, 83), "foot": Rect2(-27, -13, 55, 13)},
	"generator": {"origin": Vector2(40, 65), "foot": Rect2(-34, -23, 68, 23)},
	"reactor_core": {"origin": Vector2(46, 128), "foot": Rect2(-40, -41, 80, 41)},
	"pipe_junction": {"origin": Vector2(51, 88), "foot": Rect2(-45, -19, 87, 20)},
	"dish_antenna": {"origin": Vector2(35, 94), "foot": Rect2(-28, -23, 55, 23)},
	"med_scanner": {"origin": Vector2(46, 102), "foot": Rect2(-38, -41, 76, 38), "walkable": true},
	"specimen_tank": {"origin": Vector2(27, 73), "foot": Rect2(-21, -24, 42, 24)},
	"stretcher": {"origin": Vector2(53, 73), "foot": Rect2(-47, -32, 94, 32)},
	"swivel_chair": {"origin": Vector2(21, 66), "foot": Rect2(-14, -17, 28, 17)},
	"cargo_cart": {"origin": Vector2(36, 70), "foot": Rect2(-30, -26, 60, 26)},
	"hydro_planter": {"origin": Vector2(50, 48), "foot": Rect2(-46, -14, 91, 16)},
}

# x: inner left, segs: width in wall segments, back/front: floor lines.
# back_wall false when the room shares the wall of the room above it.
# side_doors: [side ("left"/"right"), floor line of the end cap above the opening]; cuts through merged walls.
# light (optional, default 1): brightness of the floor, props and characters inside the room.
# contrast (optional, default 1): colour exponent for props and workstations; above 1 is darker and richer.
# Floors and decals carry their room grade baked in (ROOM_GRADE in art-src/pixel/contrast.py).
# shadow (optional, default 0.22, as exported): opacity of the ground shadows under props and characters.
const ROOMS := [
	{"name": "Cafeteria", "x": 0, "segs": 16, "back": 0, "front": 720, "back_wall": true, "doors": [2, 11], "floor": "floor_tile"},
	{"name": "Storage", "x": 0, "segs": 7, "back": 720, "front": 1200, "back_wall": false, "doors": [], "side_doors": [["right", 910]], "floor": "floors/storage"},
	{"name": "Control", "x": 512, "segs": 8, "back": 720, "front": 1200, "back_wall": false, "doors": [], "floor": "floors/control", "light": 0.9, "contrast": 2.0, "shadow": 0.7},
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
	["hydro_planter", Vector2(200, 32)],
	["hydro_planter", Vector2(824, 32)],
	["stretcher", Vector2(512, 180)],
	["swivel_chair", Vector2(512, 560)],
	["dish_antenna", Vector2(900, 580)],
	["shelf", Vector2(290, 733)],
	["shelf", Vector2(345, 733)],
	["cargo_cart", Vector2(150, 950)],
	["generator", Vector2(60, 880)],
	["specimen_tank", Vector2(400, 1080)],
	["electrical_panel", Vector2(610, 736)],
	["generator", Vector2(580, 880)],
	["med_scanner", Vector2(700, 900)],
	["reactor_core", Vector2(930, 1000)],
	["pipe_junction", Vector2(800, 1080)],
]

const STATIONS := [
	["Navigation", Vector2(880, 790)],
	["Life Support", Vector2(970, 790)],
]

var floor_rects: Array[Rect2] = []  # every floor region drawn, in world px

var _textures: Dictionary[String, Texture2D] = {}
var _room_mats: Dictionary[String, ShaderMaterial] = {}  # by room name, for rooms with their own lighting
var _strips: Array = []  # side walls: [x0, x1, top floor line, bottom floor line, side door ys, {side: the room there}]
var _walls: Dictionary = {}  # floor line -> [[x0, x1, doors], ...]
var _h_sight: Array = []  # horizontal wall pieces that block sight: [x0, x1, floor line]
var _v_sight: Array = []  # side wall pieces: [x0, x1, top floor line, bottom floor line, top is a door jamb, bottom is one]


func _ready() -> void:
	add_to_group("station_map")
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
		# after add_child: the Interactable gives the sprite its own copy of the material in _ready
		var room := room_at(entry[1] * SCALE)
		var mat: ShaderMaterial = ws.get_node("Sprite").material
		mat.set_shader_parameter("light", room.get("light", 1.0))
		mat.set_shader_parameter("contrast", room.get("contrast", 1.0))


## The room containing a world px position, or {} outside every room.
func room_at(world: Vector2) -> Dictionary:
	var p := world / SCALE
	for room in ROOMS:
		if Rect2(room.x, room.back, room.segs * SEG, room.front - room.back).has_point(p):
			return room
	return {}


# Every room gets the material, even unlit ones, so all ground shadows share the shader's colour.
func _light(item: CanvasItem, room: Dictionary) -> void:
	var key: String = room.get("name", "")
	if key not in _room_mats:
		var mat := ShaderMaterial.new()
		mat.shader = ROOM_LIGHT
		mat.set_shader_parameter("light", room.get("light", 1.0))
		mat.set_shader_parameter("contrast", room.get("contrast", 1.0))
		if room.has("shadow"):
			mat.set_shader_parameter("shadow", room.shadow)
		_room_mats[key] = mat
	item.material = _room_mats[key]


func _load(path: String) -> Texture2D:
	if path not in _textures:
		_textures[path] = load(path)
	return _textures[path]


func _tex(name: String) -> Texture2D:
	return _load(PROP_DIR + name + ".png")


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

	var floor_top := back - WALL_ORIGIN_Y if room.back_wall else back
	_floor(room, Rect2(x0, floor_top, x1 - x0, front - floor_top))
	var visible_floor := Rect2(x0, back, x1 - x0, front - WALL_ORIGIN_Y - back)
	_scatter_decals(room, visible_floor)
	_floor_ao(room, visible_floor)

	var side := {"left": [], "right": []}
	for d in room.get("side_doors", []):
		side[d[0]].append(d[1])
	_strips.append([x0 - CORNER_W, x0, back, front, side.left, {"right": room}])
	_strips.append([x1, x1 + CORNER_W, back, front, side.right, {"left": room}])
	if room.back_wall:
		_add_wall(back, [x0, x1, []])
	_add_wall(front, [x0, x1, room.doors])


# A world-aligned region of the repeating floor tile, so neighbouring floors line up.
func _floor(room: Dictionary, rect: Rect2) -> void:
	var fl := Sprite2D.new()
	fl.texture = _load(FLOOR_DIR + room.floor + ".png")
	fl.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	fl.region_enabled = true
	fl.region_rect = rect
	floor_rects.append(Rect2(rect.position * SCALE, rect.size * SCALE))
	fl.centered = false
	fl.scale = Vector2(SCALE, SCALE)
	fl.position = rect.position * SCALE
	fl.z_index = -10
	fl.z_as_relative = false
	add_child(fl)


# rect: the floor left visible between the room's walls, in art px.
func _floor_ao(room: Dictionary, rect: Rect2) -> void:
	var dark: float = 1.0 - room.get("light", 1.0)
	var mat := ShaderMaterial.new()
	mat.shader = FLOOR_AO
	mat.set_shader_parameter("rect_pos", rect.position * SCALE)
	mat.set_shader_parameter("rect_size", rect.size * SCALE)
	mat.set_shader_parameter("radius", (AO_RADIUS + dark * AO_DIM_RADIUS) * SCALE)
	mat.set_shader_parameter("reach", (AO_REACH + dark * AO_DIM_REACH) * SCALE)
	mat.set_shader_parameter("strength", AO_STRENGTH + dark * AO_DIM_STRENGTH)
	mat.set_shader_parameter("pixel", float(Vision.PIXEL))
	var ao := ColorRect.new()
	ao.material = mat
	ao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ao.position = rect.position * SCALE
	ao.size = rect.size * SCALE
	ao.z_index = AO_Z
	ao.z_as_relative = false
	add_child(ao)


func _add_wall(y: float, wall: Array) -> void:
	if y not in _walls:
		_walls[y] = []
	_walls[y].append(wall)


func _build_walls() -> void:
	_strips.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var strips: Array = []
	for s in _strips:
		var joined := false
		for m in strips:
			if m[2] == s[2] and m[3] == s[3] and s[0] - m[1] <= MERGE_GAP:
				m[1] = maxf(m[1], s[1])
				m[4] = m[4] + s[4]
				m[5] = m[5].merged(s[5])
				joined = true
		if not joined:
			strips.append(s.duplicate())

	# Side doors split a strip into pieces: the one above ends in a wall face (a band of column kind 1),
	# the one below starts again SIDE_DOOR of floor further down (kind 2), like a room's back corners.
	var pieces: Array = []
	var door_lines: Array = []
	for s in strips:
		var doors: Array = s[4]
		doors.sort()
		var top: float = s[2]
		var after_door := false
		for y0 in doors:
			var y1: float = y0 + SIDE_DOOR + WALL_ORIGIN_Y
			pieces.append([s[0], s[1], top, y0, after_door, true])
			# each room's floor runs to the middle of the doorway, or all the way when nothing is on the other side
			var mid: float = (s[0] + s[1]) / 2.0
			var floors: Dictionary = s[5]
			var left: Dictionary = floors.get("left", floors.get("right"))
			var right: Dictionary = floors.get("right", left)
			_floor(left, Rect2(s[0], y0 - WALL_ORIGIN_Y, mid - s[0], y1 - y0 + WALL_ORIGIN_Y))
			_floor(right, Rect2(mid, y0 - WALL_ORIGIN_Y, s[1] - mid, y1 - y0 + WALL_ORIGIN_Y))
			door_lines.append_array([y0, y1])
			top = y1
			after_door = true
		pieces.append([s[0], s[1], top, s[3], after_door, false])

	# Side walls are flat lit tops drawn under everything; their ends hide under the wall bands.
	for p in pieces:
		var top: float = p[2]
		var h: float = p[3] - WALL_FACE - top
		for part in [["wall_v", p[0], p[1] - p[0]], ["wall_ink", p[0] - 2, 4], ["wall_ink", p[1] - 2, 4]]:
			var spr := _tiled(part[0], Rect2(part[1], top, part[2], h), top)
			spr.z_index = -5
			spr.z_as_relative = false
		var solid_top := top - (WALL_ORIGIN_Y - WALL_TUCK if p[4] else WALL_DEPTH)
		_solid(Rect2(p[0], solid_top, p[1] - p[0], p[3] - solid_top))
		_v_sight.append(p)

	for y in _walls:
		for w in _walls[y]:
			_build_wall(w[0], w[1], y, w[2])
		_build_joins(y, _walls[y], pieces)
	for y in door_lines:
		if y not in _walls:
			_build_joins(y, [], pieces)


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


## Lines (in world px) that block sight. Each wall blocks along its edge farthest from chooser
## (normally the eye), so the wall itself stays visible and its shadow starts where the floor beyond it begins.
func sight_segments(chooser: Vector2) -> Array:
	var c := chooser / SCALE
	var edge := func(y: float) -> float: return y if c.y < y - WALL_ORIGIN_Y / 2.0 else y - WALL_ORIGIN_Y
	var out: Array = []
	for h in _h_sight:
		var y: float = edge.call(h[2])
		out.append([Vector2(h[0], y) * SCALE, Vector2(h[1], y) * SCALE])
	# side walls run between the horizontal walls' blocking lines; reaching past them would cut into a visible wall face.
	# At a side door the piece above always stops at its cap's floor line, since the cap is opaque from both sides,
	# and both jambs also block across the strip, for eyes standing in the doorway.
	for v in _v_sight:
		var x: float = v[1] if c.x < (v[0] + v[1]) / 2.0 else v[0]
		var a: float = edge.call(v[2])
		var b: float = v[3] if v[5] else edge.call(v[3])
		out.append([Vector2(x, a) * SCALE, Vector2(x, b) * SCALE])
		if v[4]:
			out.append([Vector2(v[0], a) * SCALE, Vector2(v[1], a) * SCALE])
		if v[5]:
			out.append([Vector2(v[0], b) * SCALE, Vector2(v[1], b) * SCALE])
	return out


## Which edge of every wall blocks sight from eye; changes exactly when sight_segments would switch edges.
func sight_key(eye: Vector2) -> Array:
	var e := eye / SCALE
	var key: Array[bool] = []
	for y in _walls:
		key.append(e.y < y - WALL_ORIGIN_Y / 2.0)
	for v in _v_sight:
		# the side only matters while the eye is level with the wall; its span ends where the band keys flip
		var lo: float = v[2] - WALL_ORIGIN_Y / 2.0
		var hi: float = v[3] if v[5] else v[3] - WALL_ORIGIN_Y / 2.0
		key.append(e.x < (v[0] + v[1]) / 2.0 if lo <= e.y and e.y < hi else true)
		if v[4]:
			key.append(e.y < v[2] - WALL_ORIGIN_Y / 2.0)
	return key


# Splits the band along floor line y into runs of one column kind (-1: nothing) and draws fills over wall_h,
# ink seams wherever neighbouring kinds differ, and wall_corner pieces at the outer ends.
func _build_joins(y: float, walls: Array, strips: Array) -> void:
	var spans: Array = []
	for w in walls:
		spans.append([w[0], w[1], 0])
	for s in strips:
		if s[3] == y:
			spans.append([s[0], s[1], 1])
		elif s[2] == y:
			spans.append([s[0], s[1], 2])
	var cuts: Array = []
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
		if b > a:
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
	_light(s, room_at(pos * SCALE))
	if spec.foot == null:
		# flat on the floor: never covers anyone
		s.z_index = -8
		s.z_as_relative = false
	elif spec.get("walkable", false):
		# stood on, so it always draws under the player
		s.z_index = -1
		s.z_as_relative = false
	add_child(s)
	if spec.get("walkable", false):
		return
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


# Seeded by room name, so the layout is the same every run.
func _scatter_decals(room: Dictionary, area: Rect2) -> void:
	var names: Array = DECALS.get(room.floor, [])
	if names.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(room.name)
	for k in int(area.get_area() / DECAL_AREA[room.floor]):
		var name: String = names[rng.randi() % names.size()]
		var tex := _load(DECAL_DIR + name + ".png")
		var size := tex.get_size()
		var pos: Vector2
		if name in DECAL_SNAP:
			var cell: float = DECAL_SNAP[name]
			var cells := ((area.size - size) / cell).floor()
			if cells.x < 0 or cells.y < 0:
				continue
			pos = ((area.position / cell).ceil() + Vector2(rng.randi_range(0, int(cells.x)), rng.randi_range(0, int(cells.y)))) * cell
			if not area.encloses(Rect2(pos, size)):
				continue
		else:
			pos = (area.position + Vector2(rng.randf() * (area.size.x - size.x), rng.randf() * (area.size.y - size.y))).floor()
		var d := _sprite(tex, pos, Vector2.ZERO)
		d.z_index = -9
		d.z_as_relative = false
		add_child(d)
