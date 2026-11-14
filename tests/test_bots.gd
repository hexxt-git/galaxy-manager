extends SceneTree

## Headless soak test of the wandering bots: godot --headless --path . -s res://tests/test_bots.gd
## Drives the bots' physics by hand at a fixed delta, as fast as possible, and measures how well they move.

const NavGrid := preload("res://scripts/bots/nav_grid.gd")
const DT := 1.0 / 60.0
const WANDER_SECONDS := 600.0
const FORCED_SECONDS := 180.0
const STALL_SPEED := 0.1  # moving slower than this share of SPEED while on a path counts as stuck
const SHARP_TURN := deg_to_rad(30.0)  # heading change in one tick that reads as a jerk
const HUG_CELLS := 2  # within this many grid cells of touching an obstacle counts as near-wall

var failures := 0
var main: Node
var map: Node2D
var nav: NavGrid
var bots: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, what: String) -> void:
	if cond:
		print("ok: ", what)
	else:
		failures += 1
		printerr("FAIL: ", what)


func _room_rect(name: String) -> Rect2:
	for r in map.ROOMS:
		if r.name == name:
			return Rect2(Vector2(r.x, r.back) * map.SCALE, Vector2(r.segs * map.SEG, r.front - r.back) * map.SCALE)
	return Rect2()


func _point_in(rect: Rect2, rng: RandomNumberGenerator) -> Vector2:
	while true:
		var p := nav.random_point(rng)
		if rect.has_point(p):
			return p
	return Vector2.ZERO


func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	map = main.get_node("World/Map")
	var spawner := main.get_node("World/Bots")
	await spawner.spawned
	nav = spawner.nav
	bots = spawner.get_children()
	main.get_node("World/Player").set_physics_process(false)
	for b in bots:
		b.set_physics_process(false)

	var t0 := Time.get_ticks_usec()
	var probe := NavGrid.new()
	probe.build(main.get_viewport().world_2d.direct_space_state, bots[0].get_node("Feet"), map.floor_rects,
		[main.get_node("World/Player").get_rid()] as Array[RID])
	print("grid build: %.0f ms, %d target cells" % [(Time.get_ticks_usec() - t0) / 1000.0, probe.targets.size()])
	_check(bots.size() == 6, "six bots spawned")
	_check(bots.all(func(b): return nav.is_walkable(b.global_position)), "bots spawn on walkable floor")
	var colours := {}
	for b in bots:
		colours[b.colour] = true
	_check(colours.size() == bots.size(), "bots have distinct colours")

	var storage := _room_rect("Storage")
	var control := _room_rect("Control")
	var cafe := _room_rect("Cafeteria")
	var side_door := Rect2(storage.end.x, storage.position.y, control.position.x - storage.end.x, storage.size.y)
	var p := nav.find_path(_point_in(storage, RandomNumberGenerator.new()), _point_in(control, RandomNumberGenerator.new()))
	_check(_crosses(p, side_door), "storage -> control path takes the side door")

	var lone = bots[0]
	lone.global_position = _point_in(storage, RandomNumberGenerator.new())
	lone._path = PackedVector2Array([lone.global_position, Vector2(lone.global_position.x, storage.end.y + 400)])
	lone._idx = 1
	var touched := false
	for k in 120:
		lone._physics_process(DT)
		touched = touched or lone.get_slide_collision_count() > 0
	_check(touched, "walking straight into a wall registers slide collisions")

	var w := _soak("wander", WANDER_SECONDS, {})
	_check(w.min_reached >= 40, "every bot reaches many targets while wandering")
	var s := _soak("side door", FORCED_SECONDS, {"a": storage, "b": control})
	var h1 := _soak("cafeteria<->storage", FORCED_SECONDS, {"a": cafe, "b": storage})
	var h2 := _soak("cafeteria<->control", FORCED_SECONDS, {"a": cafe, "b": control})
	for r in [w, s, h1, h2]:
		_check(r.stuck <= 0.1, "%s: stuck time about zero (%.2f s)" % [r.name, r.stuck])
		_check(r.recoveries == 0, "%s: stuck recovery never triggered" % r.name)
		_check(r.contact_ratio < 0.01, "%s: wall contacts rare (%.2f%%)" % [r.name, r.contact_ratio * 100.0])
		_check(r.sharp_per_trip < 1.5, "%s: smooth paths (%.2f sharp turns per trip)" % [r.name, r.sharp_per_trip])
	_check(s.side_crossings >= 20, "side door run crosses the side door (%d)" % s.side_crossings)
	for r in [s, h1, h2]:
		_check(r.min_reached >= 10, "%s: every bot keeps crossing" % r.name)

	print("FAILURES: ", failures)
	quit(1 if failures else 0)


func _crosses(path: PackedVector2Array, area: Rect2) -> bool:
	for i in path.size() - 1:
		for k in 9:
			if area.has_point(path[i].lerp(path[i + 1], k / 8.0)):
				return true
	return false


## spec empty: wander; else bots shuttle between random spots in rooms spec.a and spec.b.
func _soak(name: String, seconds: float, spec: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)
	var forced := not spec.is_empty()
	var side_door: Rect2 = Rect2(_room_rect("Storage").end.x, _room_rect("Storage").position.y,
		_room_rect("Control").position.x - _room_rect("Storage").end.x, _room_rect("Storage").size.y)
	var stat := []
	for i in bots.size():
		var b = bots[i]
		b.rng.seed = rng.randi()
		b.reached = 0
		b.recoveries = 0
		b.wander = not forced
		b.velocity = Vector2.ZERO
		b.go_to(b.global_position)
		b._idx = b._path.size()
		b._wait = 0.0
		if forced:
			b.global_position = _point_in(spec.a, rng)
			b.set_meta("side", 0)
			b.go_to(_point_in(spec.b, rng))
		stat.append({"stuck": 0.0, "stall": 0.0, "worst": 0.0, "moving": 0, "contacts": 0, "in_door": false, "side": 0,
			"hug": 0, "sharp": 0, "heading": Vector2.ZERO})
	for tick in int(seconds / DT):
		for i in bots.size():
			var b = bots[i]
			var st: Dictionary = stat[i]
			var before: Vector2 = b.global_position
			var on_path: bool = b.has_path()
			b._physics_process(DT)
			var still_going: bool = b.has_path()
			if not still_going:
				st.heading = Vector2.ZERO
			if forced and not b.has_path() and b._wait <= 0.0:
				var into: Rect2 = spec.b if spec.a.has_point(b.global_position) else spec.a
				b.go_to(_point_in(into, rng))
			if not on_path:
				st.stall = 0.0
				st.heading = Vector2.ZERO
				continue
			st.moving += 1
			if b.get_slide_collision_count() > 0:
				st.contacts += 1
			var in_door := side_door.has_point(b.global_position)
			if in_door and not st.in_door:
				st.side += 1
			st.in_door = in_door
			if nav.clearance(nav.cell_of(b.global_position)) <= HUG_CELLS:
				st.hug += 1
			var step: Vector2 = b.global_position - before
			if step.length() > 0.5:
				if st.heading != Vector2.ZERO and absf(st.heading.angle_to(step)) > SHARP_TURN:
					st.sharp += 1
				st.heading = step
			if still_going and step.length() < b.SPEED * DT * STALL_SPEED:
				st.stuck += DT
				st.stall += DT
				st.worst = maxf(st.worst, st.stall)
			else:
				st.stall = 0.0
	var r := {"name": name, "stuck": 0.0, "worst": 0.0, "moving": 0, "contacts": 0, "recoveries": 0,
		"min_reached": 1 << 30, "total_reached": 0, "side_crossings": 0, "hug": 0, "sharp": 0}
	for i in bots.size():
		var st: Dictionary = stat[i]
		r.stuck += st.stuck
		r.worst = maxf(r.worst, st.worst)
		r.moving += st.moving
		r.contacts += st.contacts
		r.recoveries += bots[i].recoveries
		r.min_reached = mini(r.min_reached, bots[i].reached)
		r.total_reached += bots[i].reached
		r.side_crossings += st.side
		r.hug += st.hug
		r.sharp += st.sharp
	r.contact_ratio = float(r.contacts) / maxf(r.moving, 1)
	r.sharp_per_trip = float(r.sharp) / maxf(r.total_reached, 1)
	print("[%s] %ds x %d bots: reached %d (min/bot %d), stuck %.2fs, longest stall %.2fs, wall-contact ticks %d/%d (%.2f%%), recoveries %d, side-door crossings %d, near-wall %.1f%%, sharp turns/trip %.2f" % [
		name, int(seconds), bots.size(), r.total_reached, r.min_reached, r.stuck, r.worst, r.contacts, r.moving,
		r.contact_ratio * 100.0, r.recoveries, r.side_crossings, 100.0 * r.hug / maxf(r.moving, 1),
		r.sharp_per_trip])
	return r
