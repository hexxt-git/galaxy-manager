extends RefCounted

## Walkable-floor grid for bots, sampled from the physics space with the bot's own collision shape,
## so it follows whatever the map builds. Paths keep away from walls where there's room
## and are string-pulled into straight runs with rounded corners.

const CELL := 8.0
const COMFORT := 5       # clearance, in cells past touching, that paths try to keep
const WALL_COST := 4.0   # extra cost per cell of clearance short of COMFORT
const TARGET_CLEAR := 3  # random targets need this much clearance
const PULL_LOOKAHEAD := 24
const CORNER_RADIUS := 64.0
const ARC_STEPS := 6
const NEIGHBOURS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var astar := AStarGrid2D.new()
var targets := PackedVector2Array()

var _region := Rect2i()
var _clear := PackedInt32Array()  # per cell: Chebyshev distance to the nearest blocked cell, 0 when blocked


## feet: the collision shape as placed on the body; areas: floor regions in world px;
## exclude: bodies that aren't obstacles (the player).
func build(space: PhysicsDirectSpaceState2D, feet: CollisionShape2D, areas: Array[Rect2], exclude: Array[RID] = [], mask := 1) -> void:
	var bounds := areas[0]
	for a in areas:
		bounds = bounds.merge(a)
	var lo := Vector2i((bounds.position / CELL).floor())
	var hi := Vector2i((bounds.end / CELL).ceil())
	_region = Rect2i(lo, hi - lo + Vector2i.ONE)
	astar.region = _region
	astar.cell_size = Vector2(CELL, CELL)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()

	var w := _region.size.x
	var n := w * _region.size.y
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = feet.shape
	q.collision_mask = mask
	q.exclude = exclude
	var free := PackedByteArray()
	free.resize(n)
	for i in n:
		var p := Vector2(_cell(i)) * CELL
		var ok := false
		for a in areas:
			if a.has_point(p):
				ok = true
				break
		if ok:
			q.transform = Transform2D(0.0, p) * feet.transform
			ok = space.intersect_shape(q, 1).is_empty()
		free[i] = 1 if ok else 0
	_keep_largest_component(free)
	_compute_clearance(free)

	for i in n:
		var id := _cell(i)
		if _clear[i] == 0:
			astar.set_point_solid(id)
		else:
			astar.set_point_weight_scale(id, 1.0 + WALL_COST * maxi(0, COMFORT - _clear[i]))
			if _clear[i] >= TARGET_CLEAR:
				targets.append(Vector2(id) * CELL)


func _cell(i: int) -> Vector2i:
	return _region.position + Vector2i(i % _region.size.x, i / _region.size.x)


func _index(id: Vector2i) -> int:
	if not _region.has_point(id):
		return -1
	var l := id - _region.position
	return l.y * _region.size.x + l.x


func clearance(id: Vector2i) -> int:
	var i := _index(id)
	return 0 if i < 0 else _clear[i]


func cell_of(p: Vector2) -> Vector2i:
	return Vector2i((p / CELL).round())


func is_walkable(p: Vector2) -> bool:
	return clearance(cell_of(p)) > 0


func random_point(rng: RandomNumberGenerator) -> Vector2:
	return targets[rng.randi() % targets.size()]


func _keep_largest_component(free: PackedByteArray) -> void:
	var comp := PackedInt32Array()
	comp.resize(free.size())
	comp.fill(-1)
	var sizes: Array[int] = []
	for start in free.size():
		if free[start] == 0 or comp[start] >= 0:
			continue
		var c := sizes.size()
		var stack := PackedInt32Array([start])
		comp[start] = c
		var size := 0
		while not stack.is_empty():
			var i := stack[stack.size() - 1]
			stack.remove_at(stack.size() - 1)
			size += 1
			var id := _cell(i)
			for d in NEIGHBOURS:
				var j := _index(id + d)
				if j >= 0 and free[j] == 1 and comp[j] < 0:
					comp[j] = c
					stack.append(j)
		sizes.append(size)
	var best := sizes.find(sizes.max())
	for i in free.size():
		if comp[i] != best:
			free[i] = 0


# Multi-source BFS from blocked cells; the region's outside counts as blocked.
func _compute_clearance(free: PackedByteArray) -> void:
	var n := free.size()
	_clear.resize(n)
	_clear.fill(-1)
	var queue := PackedInt32Array()
	for i in n:
		if free[i] == 0:
			_clear[i] = 0
			queue.append(i)
		else:
			var id := _cell(i)
			if id.x == _region.position.x or id.y == _region.position.y or id.x == _region.end.x - 1 or id.y == _region.end.y - 1:
				_clear[i] = 1
				queue.append(i)
	var head := 0
	while head < queue.size():
		var i := queue[head]
		head += 1
		var id := _cell(i)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var j := _index(id + Vector2i(dx, dy))
				if j >= 0 and _clear[j] < 0:
					_clear[j] = _clear[i] + 1
					queue.append(j)


func _nearest_free(p: Vector2) -> Vector2i:
	var c := cell_of(p)
	if clearance(c) > 0:
		return c
	var best := c
	var best_d := INF
	for r in range(1, 8):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var id := c + Vector2i(dx, dy)
				var d := p.distance_squared_to(Vector2(id) * CELL)
				if clearance(id) > 0 and d < best_d:
					best = id
					best_d = d
		if best_d < INF:
			break
	return best


## Smoothed path from `from` to the walkable spot nearest `to`, starting at `from`; empty when unreachable.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := _nearest_free(from)
	var b := _nearest_free(to)
	if clearance(a) == 0 or clearance(b) == 0:
		return PackedVector2Array()
	var ids := astar.get_id_path(a, b)
	if ids.is_empty():
		return PackedVector2Array()
	var needs := PackedInt32Array()
	var points := _pull(from, ids, needs)
	return _round_corners(points, needs)


# Greedy string pulling: jump to the farthest raw cell reachable in a straight line that keeps at least
# as much clearance as the raw path does over that stretch (capped at COMFORT).
# needs[k] gets the clearance kept by the leg points[k] -> points[k + 1].
func _pull(start: Vector2, ids: Array[Vector2i], needs: PackedInt32Array) -> PackedVector2Array:
	var points := PackedVector2Array([start])
	var from := start
	var i := 0
	var last := ids.size() - 1
	if last == 0:
		points.append(Vector2(ids[0]) * CELL)
		needs.append(1)
		return points
	while i < last:
		var need := mini(COMFORT, mini(clearance(ids[i]), clearance(ids[i + 1])))
		var best := i + 1
		var best_need := need
		var k := best + 1
		while k <= last and k - best <= PULL_LOOKAHEAD:
			need = mini(need, clearance(ids[k]))
			if line_clear(from, Vector2(ids[k]) * CELL, need):
				best = k
				best_need = need
			k += 1
		from = Vector2(ids[best]) * CELL
		points.append(from)
		needs.append(best_need)
		i = best
	return points


# Replaces each corner with a quadratic arc between points up to CORNER_RADIUS either side of it,
# shrunk until the arc keeps the clearance of the two legs it joins.
func _round_corners(points: PackedVector2Array, needs: PackedInt32Array) -> PackedVector2Array:
	var out := PackedVector2Array([points[0]])
	for k in range(1, points.size() - 1):
		var prev := points[k - 1]
		var c := points[k]
		var next := points[k + 1]
		var r := minf(CORNER_RADIUS, minf(prev.distance_to(c), c.distance_to(next)) * 0.5)
		var need := mini(needs[k - 1], needs[k])
		var arc := PackedVector2Array()
		while r >= CELL:
			arc = _arc(c + (prev - c).normalized() * r, c, c + (next - c).normalized() * r)
			var ok := true
			for m in arc.size() - 1:
				if not line_clear(arc[m], arc[m + 1], need):
					ok = false
					break
			if ok:
				break
			arc.clear()
			r *= 0.5
		if arc.is_empty():
			out.append(c)
		else:
			out.append_array(arc)
	out.append(points[points.size() - 1])
	return out


func _arc(a: Vector2, c: Vector2, b: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for m in ARC_STEPS + 1:
		var t := float(m) / ARC_STEPS
		pts.append(a.lerp(c, t).lerp(c.lerp(b, t), t))
	return pts


## Walking cost from every cell to the walkable spot nearest `to`, weighted like find_path's; -1 where unreachable.
## Slow (hundreds of ms), so it's meant for a worker thread; walk_down() then reads paths off it for free.
func cost_field(to: Vector2) -> PackedInt32Array:
	var n := _clear.size()
	var cost := PackedInt32Array()
	cost.resize(n)
	cost.fill(-1)
	var goal := _index(_nearest_free(to))
	if goal < 0 or _clear[goal] == 0:
		return cost
	var w := _region.size.x
	# Dial's algorithm: step costs are small ints, so a ring of buckets stands in for a heap
	const RING := 512
	var buckets := []
	buckets.resize(RING)
	for k in RING:
		buckets[k] = []
	var done := PackedByteArray()
	done.resize(n)
	cost[goal] = 0
	buckets[0].append(goal)
	var pending := 1
	var at := 0
	while pending > 0:
		var b: Array = buckets[at % RING]
		if b.is_empty():
			at += 1
			continue
		var i: int = b.pop_back()
		pending -= 1
		if done[i]:
			continue
		done[i] = 1
		var x := i % w
		var y := i / w
		for dy in range(-1, 2):
			var ny := y + dy
			if ny < 0 or ny >= _region.size.y:
				continue
			for dx in range(-1, 2):
				var nx := x + dx
				if (dx == 0 and dy == 0) or nx < 0 or nx >= w:
					continue
				var j := ny * w + nx
				if _clear[j] == 0 or done[j]:
					continue
				if dx != 0 and dy != 0 and (_clear[y * w + nx] == 0 or _clear[ny * w + x] == 0):
					continue
				var step := (14 if dx != 0 and dy != 0 else 10) * (1 + int(WALL_COST) * maxi(0, COMFORT - _clear[j]))
				var c := cost[i] + step
				if cost[j] < 0 or c < cost[j]:
					cost[j] = c
					buckets[c % RING].append(j)
					pending += 1
	return cost


## Path from `from` downhill on a cost_field() to its goal, smoothed for its first `smooth` px (smoothing is the
## costly part); empty when unreachable.
func walk_down(field: PackedInt32Array, from: Vector2, smooth := INF) -> PackedVector2Array:
	var id := _nearest_free(from)
	var i := _index(id)
	if i < 0 or field[i] < 0:
		return PackedVector2Array()
	var ids: Array[Vector2i] = [id]
	while field[i] > 0:
		var best := i
		var best_id := id
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var nid := id + Vector2i(dx, dy)
				var j := _index(nid)
				if j < 0 or field[j] < 0 or field[j] >= field[best]:
					continue
				if dx != 0 and dy != 0 and (clearance(id + Vector2i(dx, 0)) == 0 or clearance(id + Vector2i(0, dy)) == 0):
					continue
				best = j
				best_id = nid
		if best == i:
			break
		i = best
		id = best_id
		ids.append(id)
	var cut := mini(ids.size(), int(minf(smooth / CELL, ids.size())))
	var needs := PackedInt32Array()
	var out := _round_corners(_pull(from, ids.slice(0, maxi(cut, 1)), needs), needs)
	for k in range(cut, ids.size()):
		out.append(Vector2(ids[k]) * CELL)
	return out


func line_clear(a: Vector2, b: Vector2, need: int) -> bool:
	var steps := ceili(a.distance_to(b) / (CELL * 0.5))
	for s in steps + 1:
		if clearance(cell_of(a.lerp(b, float(s) / maxf(steps, 1)))) < need:
			return false
	return true
