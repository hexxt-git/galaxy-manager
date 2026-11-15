extends "res://scripts/bots/bot.gd"

## A crewmate with a favourite task. They do it while it's wanted; otherwise they pitch in on whatever the base needs most.
## Slower than the player, so the commander's own work still counts.

const WORK_TIME := 4.0
const BASE_SPEED := 0.7  # of the player's walking speed
const THINK_EVERY := 0.5
const DIRTY := 0.3
const SPREAD := 36.0
const GREETINGS := ["Hey chief!", "Hi boss!", "Good going, captain!", "Morning, commander!", "Reporting for duty!",
	"Looking sharp, chief!", "Nice base, boss!", "Captain! Good to see you.", "Hey boss, need a hand?"]
const GREET_NEAR := 260.0  # px from the player to greet them in passing
const GREET_EVERY := 300.0  # seconds near the player, on average, between greetings in passing
const SAY_TIME := 2.6
const FAVOURITE := 0.8  # head start for their favourite task: they only help elsewhere when it has nothing to do  # crew sharing a station stand side by side

var role := "ice"
var perk := ""
var crew_name := ""
var busy_with := "idle"  # what they're doing right now, for the HUD
var greets := true  # walk up to say hello on arrival, and now and then in passing
var _arrived := false
var _saying := ""
var _say_t := 0.0
var _greet_in := 0.0
var colony: Colony
var BUBBLE: StyleBox = preload("res://scripts/colony/hud.gd").nine("chip", 12, Vector4.ZERO)
var hands := Hands.new()

var _then := Callable()
var _work := -1.0
var _think := 0.0


func _ready() -> void:
	hands.name = "Hands"
	add_child(hands)
	set_meta("perk", perk)
	set_meta("base_speed", BASE_SPEED * Colony.WALK)
	wander = false
	add_to_group("helpers")
	super()
	target_reached.connect(func() -> void:
		if busy_with == "saying hello":
			_say(GREETINGS.pick_random())
			_work = SAY_TIME
		else:
			_work = _work_time() if _then.is_valid() else -1.0)
	_greet_in = randf_range(GREET_EVERY * 0.6, GREET_EVERY * 1.4)


func _work_time() -> float:
	return WORK_TIME * (0.5 if perk == "steady" else 1.0) / colony.work_speed()


func _physics_process(delta: float) -> void:
	super(delta)
	if _say_t > 0.0:
		_say_t -= delta
		if _say_t <= 0.0:
			_saying = ""
			queue_redraw()
	elif greets and _arrived and colony:
		_greet_in_passing(delta)
	if (has_path() and not wander) or colony == null:
		return
	if _work >= 0.0:
		_work -= delta
		if _work < 0.0:
			var t := _then
			_then = Callable()
			if t.is_valid():
				t.call()
		return
	_think -= delta
	if _think <= 0.0:
		_think = THINK_EVERY
		_decide()


func _say(text: String) -> void:
	_saying = text
	_say_t = SAY_TIME
	queue_redraw()


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


## Now and then, when the player is close, a quick hello without stopping work.
func _greet_in_passing(delta: float) -> void:
	var p := _player()
	if p == null or global_position.distance_to(p.global_position) > GREET_NEAR:
		return
	_greet_in -= delta
	if _greet_in <= 0.0:
		_greet_in = randf_range(GREET_EVERY * 0.6, GREET_EVERY * 1.4)
		_say(GREETINGS.pick_random())


func _decide() -> void:
	if greets and not _arrived:
		_arrived = true
		var p := _player()
		if p:
			busy_with = "saying hello"
			var side := Vector2(70.0 if randf() < 0.5 else -70.0, 10.0)
			_go(p.global_position + side, func() -> void: pass)
			if not has_path():
				_say(GREETINGS.pick_random())
				_work = SAY_TIME
			return
	var doing := _deliver()
	if doing == "" and not hands.is_empty():
		hands.toss(Vector2.DOWN)
	if doing == "":
		for task in _order():
			doing = _try(task)
			if doing != "":
				break
	doing = doing if doing != "" else "idle"
	if doing != busy_with:
		get_tree().call_group("playlog", "write", "crew_decide", {"name": crew_name, "role": role, "doing": doing,
			"was": busy_with, "holding": Items.label(hands.type, hands.count) if hands.count else "", "at": global_position})
	busy_with = doing
	wander = doing == "idle"


func _deliver() -> String:
	if hands.holds("ice") and _use_nearest("melter"):
		return "delivering ice"
	if hands.holds("sample"):
		if colony.wants("air") > 0.0 and _use_nearest("oven"):
			return "baking rocks into O2"
		if _use_nearest("lab"):
			return "delivering rocks"
	if hands.holds("potato") and _use_nearest("kitchen"):
		return "stocking potatoes"
	return ""


## Most wanted first, with a head start for the favourite; the favourite again as a last resort.
func _order() -> Array:
	var score := func(t: String) -> float: return colony.wants(t) + (FAVOURITE if t == role else 0.0)
	var open: Array = Colony.TASKS.filter(func(t: String) -> bool: return colony.wants(t) > 0.0)
	open.sort_custom(func(a: String, b: String) -> bool: return score.call(a) > score.call(b))
	return open + [role]


func _try(task: String) -> String:
	match task:
		"ice":
			if _pick_up("ice"):
				return "picking up ice"
			if _use_nearest("drill"):
				return "drilling"
		"air":
			if _use_nearest("electrolyzer"):
				return "splitting water into air"
		"harvest":
			if _pick_up("potato"):
				return "picking up potatoes"
			if _use_nearest("bed"):
				return "tending potatoes"
		"solar":
			if _use_nearest("solar", func(s: Station) -> bool: return s.state.dust > DIRTY):
				return "wiping panels"
		"rocks":
			if _pick_up("sample"):
				return "fetching a rock"
			if _use_nearest("outcrop"):
				return "digging rocks"
	return ""


func _pick_up(item: String) -> bool:
	var drop := _nearest(get_tree().get_nodes_in_group("drops").filter(
			func(d: ItemDrop) -> bool: return d.type == item and d.resting and not d.is_queued_for_deletion()))
	if drop == null:
		return false
	var ref: WeakRef = weakref(drop)
	_go(drop.global_position, func() -> void:
		if ref.get_ref():
			hands.pick(ref.get_ref()))
	return true


## Walks to the nearest usable station of `kind` and uses it; false if none can be used now.
func _use_nearest(kind: String, filter := Callable()) -> bool:
	var options := colony.stations_of(kind).filter(func(s: Station) -> bool:
		return colony.blocked_reason(s, self) == "" and (not filter.is_valid() or filter.call(s)))
	var s := _nearest(options) as Station
	if s == null:
		return false
	_go(s.front() + Vector2(randf_range(-SPREAD, SPREAD), 0), func() -> void:
		if colony.blocked_reason(s, self) == "":
			colony.finish(s, self))
	return true


func _go(at: Vector2, then: Callable) -> void:
	_then = then
	if global_position.distance_to(at) < 24.0:
		_work = _work_time()
	elif not go_to(at):
		get_tree().call_group("playlog", "write", "crew_no_path", {"name": crew_name, "from": global_position, "to": at})
		_work = _work_time()


func _nearest(nodes: Array) -> Node2D:
	var best: Node2D = null
	for n in nodes:
		if best == null or global_position.distance_squared_to(n.global_position) < global_position.distance_squared_to(best.global_position):
			best = n
	return best


func _draw() -> void:
	var font := ColonyMap.FONT
	var text := "%s · %s" % [crew_name, Colony.ROLES[role][0]]
	draw_string_outline(font, Vector2(-100, -192), text, HORIZONTAL_ALIGNMENT_CENTER, 200, 22, 8, Color("0d0d12"))
	draw_string(font, Vector2(-100, -192), text, HORIZONTAL_ALIGNMENT_CENTER, 200, 22, Color.WHITE)
	if _saying != "":
		var w := font.get_string_size(_saying, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 28.0
		var box := Rect2(-w * 0.5, -262, w, 44)
		draw_style_box(BUBBLE, box)
		draw_colored_polygon(PackedVector2Array([Vector2(-10, box.end.y - 3), Vector2(10, box.end.y - 3), Vector2(0, box.end.y + 12)]), Color("dfe5ea"))
		draw_string(font, Vector2(box.position.x, box.position.y + 29), _saying, HORIZONTAL_ALIGNMENT_CENTER, w, 22, Color("0d0d12"))
