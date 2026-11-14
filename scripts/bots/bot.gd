extends "res://scripts/crewmate.gd"

## Wanders the station: walks a NavGrid path to a random spot, maybe pauses, then picks another.

const NavGrid := preload("res://scripts/bots/nav_grid.gd")

signal target_reached

const PAUSE := Vector2(0.3, 1.5)
const PAUSE_CHANCE := 0.5
const MIN_TRIP := 200.0
const STUCK_WINDOW := 0.5
const STUCK_RATIO := 0.3  # moving less than this share of SPEED over a window counts as stuck

var nav: NavGrid
var rng := RandomNumberGenerator.new()
var wander := true
var reached := 0
var recoveries := 0

var _path := PackedVector2Array()
var _idx := 0
var _goal := Vector2.ZERO
var _wait := 0.0
var _window_from := Vector2.ZERO
var _window_t := 0.0
var _strikes := 0


func _ready() -> void:
	add_to_group("bots")
	super()


func has_path() -> bool:
	return _idx < _path.size()


func go_to(target: Vector2) -> bool:
	_goal = target
	_path = nav.find_path(global_position, target)
	_idx = 1
	_window_from = global_position
	_window_t = 0.0
	return has_path()


func _physics_process(delta: float) -> void:
	if nav == null:
		return
	var dir := Vector2.ZERO
	if has_path():
		dir = _follow(delta)
	else:
		velocity = Vector2.ZERO
		_wait -= delta
		if _wait <= 0.0 and wander:
			_pick_target()
	move_and_slide()
	_animate(dir, delta)
	if has_path():
		_check_stuck(delta)


# Spends this tick's travel along the path, so speed stays exact through waypoints and it never overshoots.
func _follow(delta: float) -> Vector2:
	var pos := global_position
	var budget := SPEED * delta
	while _idx < _path.size():
		var d := pos.distance_to(_path[_idx])
		if d > budget:
			pos += (_path[_idx] - pos) * (budget / d)
			break
		budget -= d
		pos = _path[_idx]
		_idx += 1
	velocity = (pos - global_position) / delta
	if not has_path():
		_arrive()
	return velocity / SPEED


func _arrive() -> void:
	reached += 1
	_strikes = 0
	_wait = rng.randf_range(PAUSE.x, PAUSE.y) if rng.randf() < PAUSE_CHANCE else 0.0
	target_reached.emit()


func _pick_target() -> void:
	for i in 8:
		var t := nav.random_point(rng)
		if t.distance_to(global_position) >= MIN_TRIP and go_to(t):
			return


func _check_stuck(delta: float) -> void:
	_window_t += delta
	if _window_t < STUCK_WINDOW:
		return
	var moved := global_position.distance_to(_window_from)
	_window_from = global_position
	_window_t = 0.0
	if moved >= SPEED * STUCK_WINDOW * STUCK_RATIO:
		_strikes = 0
		return
	recoveries += 1
	_strikes += 1
	if _strikes >= 2:
		# last resort: hop to the next point on the path, or anywhere walkable
		_strikes = 0
		global_position = _path[_idx] if has_path() else nav.random_point(rng)
	go_to(_goal)
