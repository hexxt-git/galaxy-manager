extends Node

## Detailed playtest log: one JSON line per event to user://playtests/<date>_<time>.jsonl.
## Besides the events other scripts send through write() (any node can reach it via the "playlog" group),
## it records on its own:
##   trail     — the player's position, speed, area, held item, focus and open UI every TRAIL seconds
##   crew      — every crewmate's position, activity, held item and stuck count every CREW_TRAIL seconds
##   state     — every resource and its rate per minute, the power breakdown, beds, panels and loose items every SNAPSHOT seconds
##   changes   — movement start/stop, focus changes, panels getting dusty, power and O2 shortfalls
##   summary   — totals for the session when the game closes

const TRAIL := 0.5
const CREW_TRAIL := 1.0
const SNAPSHOT := 2.0
const DUSTY := [0.5, 0.9]
const AREAS := {".": "inside", ",": "surface", ":": "crater"}

var colony: Colony
var main: Node
var path := ""
var _file: FileAccess
var _t_trail := 0.0
var _t_crew := 0.0
var _t_state := 0.0
var _last_res := {}
var _last_state_t := 0.0
var _moving := false
var _focus := ""
var _dust := {}  # station -> DUSTY threshold index crossed
var _short := false
var _no_o2 := false
var _counts := {}
var _by_who := {}
var _area_time := {}
var _walked := 0.0
var _idle := 0.0
var _short_time := 0.0
var _last_pos := Vector2.INF
var _summary_written := false


func _ready() -> void:
	add_to_group("playlog")
	if DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute("user://playtests")
	path = "user://playtests/%s.jsonl" % Time.get_datetime_string_from_system().replace(":", "-")
	_file = FileAccess.open(path, FileAccess.WRITE)
	write("start", {"file": ProjectSettings.globalize_path(path), "viewport": get_viewport().get_visible_rect().size, "os": OS.get_name()})


func write(event: String, data := {}) -> void:
	_counts[event] = _counts.get(event, 0) + 1
	if event == "did":
		var key := "%s @ %s" % [data.get("who", "?"), data.get("station", "?")]
		_by_who[key] = _by_who.get(key, 0) + 1
	if _file == null:
		return
	var entry := {"t": snappedf(colony.time if colony else 0.0, 0.01), "ms": Time.get_ticks_msec(), "event": event}
	for k in data:
		entry[k] = _plain(data[k])
	_file.store_line(JSON.stringify(entry))
	_file.flush()


func _plain(v: Variant) -> Variant:
	if v is Vector2:
		return [snappedf(v.x, 0.1), snappedf(v.y, 0.1)]
	if v is float:
		return snappedf(v, 0.01)
	if v is Array:
		return v.map(_plain)
	if v is Dictionary:
		var d := {}
		for k in v:
			d[str(k)] = _plain(v[k])
		return d
	if v is Object:
		return str(v)
	return v


func _area(at: Vector2) -> String:
	return AREAS.get(colony.map.char_at(at), "?")


func _held(h: Hands) -> String:
	return Items.label(h.type, h.count) if h and h.count > 0 else ""


func _ui() -> String:
	if main.picker.visible:
		return "picker"
	if main.panel.visible:
		return "panel"
	if main.minimap.visible:
		return "map"
	return ""


func _process(delta: float) -> void:
	if colony == null or main == null or colony.map == null or main.player == null:
		return
	var player: Node2D = main.player
	var area := _area(player.global_position)
	_area_time[area] = _area_time.get(area, 0.0) + delta
	if _last_pos != Vector2.INF:
		_walked += player.global_position.distance_to(_last_pos)
	_last_pos = player.global_position

	var moving: bool = player.velocity.length() > 1.0
	if moving != _moving:
		_moving = moving
		write("move_start" if moving else "move_stop", {"at": player.global_position, "area": area})
	if not moving and _ui() == "":
		_idle += delta
	var focus := ""
	var det: InteractionDetector = main.detector
	if is_instance_valid(det.focus):
		focus = "%s (%s)" % [det.focus.prompt, det.focus.get_parent().name]
	if focus != _focus:
		_focus = focus
		write("focus", {"target": focus, "at": player.global_position})

	_t_trail -= delta
	if _t_trail <= 0.0:
		_t_trail = TRAIL
		write("trail", {"at": player.global_position, "speed": player.velocity.length(), "speed_scale": player.speed_scale,
			"area": area, "holding": _held(main.hands), "focus": focus, "ui": _ui()})
	_t_crew -= delta
	if _t_crew <= 0.0:
		_t_crew = CREW_TRAIL
		for h in main.helpers.get_children():
			write("crew", {"name": h.crew_name, "role": h.role, "perk": h.perk, "at": h.global_position, "area": _area(h.global_position),
				"doing": h.busy_with, "holding": _held(h.hands), "walking": h.has_path(), "wander": h.wander, "stuck_recoveries": h.recoveries})
	_t_state -= delta
	if _t_state <= 0.0:
		_t_state = SNAPSHOT
		_snapshot()
	_watch_changes(delta)


func _snapshot() -> void:
	var r := colony.res
	var dt := colony.time - _last_state_t
	var rates := {}
	for k in r:
		rates[k] = (r[k] - _last_res.get(k, r[k])) / dt * 60.0 if dt > 0.0 else 0.0
	_last_res = r.duplicate()
	_last_state_t = colony.time
	var panels: Array = colony.stations_of("solar")
	var beds: Array = colony.stations_of("bed")
	var drops := {}
	for d in get_tree().get_nodes_in_group("drops"):
		drops[d.type] = drops.get(d.type, 0) + d.count
	write("state", {
		"o2": r.o2, "water": r.water, "food": r.food, "research": r.research, "per_min": rates,
		"power": {"supply": colony.power.x, "demand": colony.power.y, "ratio": clampf(colony.power.x / colony.power.y, 0.0, 1.0),
			"solar": panels.map(func(s: Station) -> float: return Colony.PANEL_POWER * (1.0 - s.state.dust)),
			"reactors": colony.stations_of("reactor").size(),
			"beds": beds.size(), "crew": colony.crew.size()},
		"dust": panels.map(func(s: Station) -> float: return s.state.dust),
		"potatoes_per_min_beds": colony.food_rate(),
		"unlocked": colony.unlocked.keys(), "mults": {"bed": colony.mult("bed_x"), "panel": colony.mult("panel_x"), "bit": colony.mult("bit"), "lab": colony.mult("lab_x")},
		"on_ground": drops, "crew": colony.crew.size(), "next_crew_food": colony.crew_cost(),
		"next_upgrade_research": colony.upgrade_cost(), "upgrades": colony.levels.duplicate(),
		"slots_free": {"bed": colony.map.free_slots("G"), "panel": colony.map.free_slots("S"), "reactor": colony.map.free_slots("N")},
		"objective": colony.current_objective()[0], "step": colony.step,
	})


func _watch_changes(delta: float) -> void:
	for s in colony.stations_of("solar"):
		var level := 0
		for i in DUSTY.size():
			if s.state.dust >= DUSTY[i]:
				level = i + 1
		if level != _dust.get(s, 0):
			_dust[s] = level
			write("panel_dust", {"panel": str(s.name), "dust": s.state.dust, "level": ["clean", "dusty", "caked"][level]})
	var short: bool = colony.power.x < colony.power.y
	if short:
		_short_time += delta
	if short != _short:
		_short = short
		write("power_short_start" if short else "power_short_end", {"supply": colony.power.x, "demand": colony.power.y})
	var no_o2: bool = colony.res.o2 <= 0.0
	if no_o2 != _no_o2:
		_no_o2 = no_o2
		write("o2_empty_start" if no_o2 else "o2_empty_end", {})


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_summary()


func _exit_tree() -> void:
	_summary()


func _summary() -> void:
	if _summary_written or _file == null or colony == null:
		return
	_summary_written = true
	write("summary", {
		"duration": colony.time, "crew": colony.crew.size(), "won": colony.finished, "res": colony.res.duplicate(),
		"upgrades": colony.levels.duplicate(), "stats": colony.stats.duplicate(), "events": _counts.duplicate(),
		"actions": _by_who.duplicate(), "seconds_by_area": _area_time.duplicate(), "walked_px": _walked,
		"player_idle_s": _idle, "power_short_s": _short_time,
	})
