extends Node

## Guided first run. One step at a time, always pointed at with a trail; each finished step brings the next resource
## onto the HUD: power, then water, air, food and crew. While it runs nothing drains, only the steps reached so far
## can be used, and water and potatoes are topped up so no slip can strand the player.

const WATER_GIFT := 8.0  # after the first melt: enough to split air and tend a bed, with plenty to spare
const OFF_TRAIL := 24.0  # straying this far from the trail redraws it from where the player is
const TRAIL_HEAD := 160.0  # only this much of the trail ahead is checked for the player, so it can't skip ahead
const SMOOTH := 2400.0
const MENU_SCRIPT := preload("res://scripts/menu.gd")
const ALL_CHIPS := ["o2", "water", "food", "power", "research", "crew"]

# [goal line, station kind usable from this step on, chip revealed when it's done]
const STEPS := [
	["Wipe the dusty solar panels", "solar", "water"],
	["Drill ice in the dark crater", "drill", ""],
	["Bring the ice to the Ice melter", "melter", "o2"],
	["Make air at the Electrolyzer", "electrolyzer", "food"],
	["Pick potatoes in the Greenhouse", "bed", ""],
	["Bring the potatoes to the Kitchen", "kitchen", "crew"],
	["Call a crewmate at the Comms dish", "comms", "research"],
	["Dig moon rocks at an outcrop outside", "outcrop", ""],
	["Bring the rocks to the Lab", "lab", ""],
	["Pick your first upgrade", "", ""],
]
const CREW_STEP := 6  # finishing it is the "base online" milestone
const UPGRADE_STEP := 9

# step -> what the commander says when it starts
const BRIEF := {
	0: ["Commander's log: I'm the first one awake at Shackleton Base, on the Moon's south pole.",
		"Everything here runs on electricity: heaters, lights, the machines that make air. And power is low.",
		"Regolith, sharp moon dust, has coated the solar panels so sunlight can't reach the cells. Let's wipe them.",
		"I'll follow the yellow dots. They always lead to the next job."],
	1: ["Power's back! Next: water. We need it to drink, to grow food, and even to make air.",
		"No rivers here. But the crater floor south of the base never sees sunlight: it's colder than -170 C.",
		"That makes it a cold trap. Ice from comets has stayed frozen down there for billions of years. Let's drill some up."],
	2: ["Got ice! Out in the vacuum it would just sublimate, turning straight into gas.",
		"So it gets melted indoors. The Ice melter in life support warms it and filters it into clean water."],
	3: ["Water's flowing. But the Moon has no air, and we can't breathe water.",
		"Water is H2O: two hydrogen atoms and one oxygen. Electricity can pull them apart. That's electrolysis.",
		"The Electrolyzer does exactly that: water in, oxygen out. The ISS makes its air the same way."],
	4: ["Air's flowing. Last essential: food. Shipping it from Earth costs thousands of dollars per kilo.",
		"So we grow our own. The Greenhouse turns water, power and light into potatoes: lots of calories in little space.",
		"Let's pick some."],
	5: ["Water and power reach the base through pipes and wires, but food has to be carried.",
		"Take the potatoes to the Kitchen in the hab."],
	6: ["Power, water, air and food: the base can keep a crew alive now.",
		"So Earth can send help. Radio them from the Comms dish to call a crewmate!"],
	7: ["A crewmate! They'll pick up jobs on their own.",
		"To grow further we need to learn how to build with what's here. That starts with moon rocks.",
		"Let's dig some at the rock outcrop outside."],
	8: ["Got samples! Take them to the Lab.",
		"Its spectrometer splits the light a rock gives off into a spectrum. Each mineral leaves its own lines, like a barcode."],
	9: ["That's research: knowledge we can spend.",
		"Each upgrade makes the base better at something. Pick the one we need most!"],
}
const OUTRO := ["That's the whole loop: power, water, air, food, crew and research.",
	"Every crewmate breathes, drinks and eats, so keep all four flowing.",
	"The base is yours, Commander. Grow it to %d crew!" % Colony.WIN_CREW]
const GLANCE_IN := 1.4
const GLANCE_OUT := 1.1
const BRIEF_DELAY := 2.0  # seconds after a step is done before the next one is explained
const USE_PULSE := 0.12

var main: Node2D
var colony: Colony
var hands: Hands
var guide: Node2D
var hud: Control
var dialog: Control
var step := 0
var _briefed := -1
var _talking := false
var _started := false
var _t := 0.0
var _fields := {}  # goal cell -> NavGrid.cost_field() for it
var _field_task := -1
var _field_cell := Vector2i.ZERO
var _field_out := PackedInt32Array()
var _goal := Vector2i(-1, -1)  # nav cell the trail leads to
var _path := PackedVector2Array()  # the planned route; the drawn trail is its unwalked rest, starting at the player
var _rough := false  # the trail is a one-off find_path while the field is still being built
var _use_pos := Vector2.INF
var _cam: Tween
var _delay := 0.0


func _ready() -> void:
	colony = main.colony
	hands = main.hands
	guide = main.guide
	hud = main.hud
	colony.hold = true
	colony.res = {"o2": 1.5, "water": 0.0, "food": 0.0, "research": 0.0}
	for s in colony.stations_of("solar"):
		s.state.dust = 0.7
	hud.only_show(["power"])
	guide.lead = true
	guide.show_trail = false
	colony.only = [STEPS[0][1]]
	dialog = main.dialog
	main.player.get_node("Camera").process_mode = Node.PROCESS_MODE_ALWAYS
	_enter(0)


## Called once the map is ready to be seen.
func begin() -> void:
	_started = true


func _enter(i: int) -> void:
	step = i
	hud.goal_text = STEPS[i][0]
	main.playlog.write("tutorial_step", {"step": i, "goal": STEPS[i][0]})


func _done(i: int) -> bool:
	match i:
		0: return colony.stations_of("solar").all(func(s: Station) -> bool: return s.state.dust < 0.05)
		1: return colony.count("ice") >= 1
		2: return colony.count("melted") >= 1
		3: return colony.count("split") >= 1
		4: return hands.holds("potato") or colony.res.food >= colony.crew_cost()
		5: return colony.res.food >= colony.crew_cost()
		6: return colony.crew.size() >= 2
		7: return hands.holds("sample") or colony.count("rocks") >= 1
		8: return colony.count("rocks") >= 1
		9: return colony.count("upgrades") >= 1
	return false


func _process(delta: float) -> void:
	if not _started or _talking:
		return
	_t += delta
	_keep_stocked()
	while _briefed == step and _done(step):
		var chip: String = STEPS[step][2]
		if step == 2:
			colony.res.water = maxf(colony.res.water, WATER_GIFT)
		if chip != "":
			hud.reveal(chip)
		if step == 8:
			colony.res.research = maxf(colony.res.research, colony.upgrade_cost())
		if step == CREW_STEP:
			_banner()
		if step == STEPS.size() - 1:
			_finish()
			return
		_enter(step + 1)
		_delay = BRIEF_DELAY
	_point()
	guide.show_trail = _briefed == step
	if step == UPGRADE_STEP and _briefed == step and not _busy():
		colony.offer_upgrade()  # in case the first offer couldn't open
	if _briefed != step:
		_delay = BRIEF_DELAY if _busy() else _delay - delta
		if _delay <= 0.0:
			_brief(step)
			return
	_pulse_use()


## Something else has the screen: a task or minigame, the card picker, or a note being read. Briefs wait for it.
func _busy() -> bool:
	return main.panel.visible or main.picker.visible or dialog.visible or get_tree().paused


## The commander says what's next while the camera glances at where it is.
func _brief(i: int) -> void:
	_briefed = i
	guide.show_trail = false
	guide.queue_redraw()
	colony.only = STEPS.slice(0, i + 1).map(func(s: Array) -> String: return s[1])  # the next machine opens as it's explained
	_talking = true
	_pulse_use(false)
	var target: Node2D = guide.target
	var cam: Camera2D = main.player.get_node("Camera")
	_lift_shadows(true)
	if target:
		var look := target.global_position - Vector2(0, 80)
		_glance(cam, look - cam.global_position, GLANCE_IN)
	dialog.say(BRIEF[i], main.player.colour)
	await dialog.closed
	_lift_shadows(false)
	_glance(cam, Vector2.ZERO, GLANCE_OUT)
	_talking = false
	guide.show_trail = true
	if i == UPGRADE_STEP:
		colony.offer_upgrade()


## Line-of-sight shadows are cast from the player, so they'd cover whatever the camera glances at.
func _lift_shadows(on: bool) -> void:
	for c in main.get_children():
		if c.has_method("lift"):
			c.lift(on)


## Eases the camera to `offset` from the player, the light circle with it. A new glance replaces one in flight.
func _glance(cam: Camera2D, offset: Vector2, time: float) -> void:
	if _cam and _cam.is_valid():
		_cam.kill()
	_cam = cam.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_cam.tween_method(func(o: Vector2) -> void:
		cam.offset = o
		main.update_light(), cam.offset, offset, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## The USE button bounces while the player stands at the thing to use.
func _pulse_use(on := true) -> void:
	var btn: Control = main.use_button
	var focus: Interactable = main.detector.focus
	on = on and is_instance_valid(focus) and is_instance_valid(guide.target) and focus.get_parent() == guide.target and not guide.blocked
	if _use_pos == Vector2.INF:
		_use_pos = btn.position
	var k := 1.0 + USE_PULSE * absf(sin(_t * 7.0)) if on else 1.0
	btn.scale = Vector2(2, 2) * k
	btn.position = _use_pos - btn.size * (k - 1.0)  # grow round its centre; the button is drawn at 2x from its corner
	if not on:
		_use_pos = Vector2.INF


## Whatever the player does, the current step stays doable: water never runs too low to split or tend, and the beds
## refill whenever no potatoes are left in hand or on the ground.
func _keep_stocked() -> void:
	if step >= 3:
		colony.res.water = maxf(colony.res.water, Colony.SPLIT_WATER + Colony.TEND_WATER)
	if step in [4, 5]:
		var short: float = colony.crew_cost() - colony.res.food
		if short > 0.0 and not hands.holds("potato") and _drop_of("potato") == null:
			for s in colony.stations_of("bed"):
				s.state.grown = maxf(s.state.grown, short)


func _drop_of(item: String) -> ItemDrop:
	return _nearest(get_tree().get_nodes_in_group("drops").filter(func(d: ItemDrop) -> bool:
		return d.type == item and not d.is_queued_for_deletion())) as ItemDrop


func _nearest(nodes: Array) -> Node2D:
	var best: Node2D = null
	for n in nodes:
		if best == null or main.player.global_position.distance_squared_to(n.global_position) < main.player.global_position.distance_squared_to(best.global_position):
			best = n
	return best


func _station(kind: String, filter := Callable()) -> Station:
	var options := colony.stations_of(kind)
	if filter.is_valid():
		options = options.filter(filter)
	return _nearest(options) as Station


## For a carrying step: the destination while carrying `item`, else a dropped stack of it, else where it comes from.
func _carry(item: String, to: String, from: String) -> Array:
	if hands.holds(item):
		return [_station(to), true]
	var drop := _drop_of(item)
	if drop:
		return [drop, false, "Pick it up"]
	return [_station(from), false]


func _target() -> Array:
	match step:
		0: return [_station("solar", func(s: Station) -> bool: return s.state.dust >= 0.05), false]
		1: return [_station("drill"), false]
		2: return _carry("ice", "melter", "drill")
		3: return [_station("electrolyzer"), false]
		4: return [_station("bed"), false]
		5: return _carry("potato", "kitchen", "bed")
		6: return [_station("comms"), false]
		7: return [_station("outcrop"), false]
		8: return _carry("sample", "lab", "outcrop")
	return [null, false]


func _point() -> void:
	var t := _target()
	var node: Node2D = t[0]
	guide.target = node
	guide.target_tag = t[1]
	guide.target_label = t[2] if t.size() > 2 else (node.title if node is Station else "")
	var focus: Interactable = main.detector.focus
	if node == null or main.nav == null or is_instance_valid(focus) and focus.get_parent() == node:
		guide.trail = PackedVector2Array()
		_goal = Vector2i(-1, -1)
		return
	var to := (node as Station).front() if node is Station else node.global_position
	var at: Vector2 = main.player.global_position
	var goal: Vector2i = main.nav.cell_of(to)
	var field := _field(goal, to)
	if goal == _goal and not (_rough and not field.is_empty()) and _follow(at):
		return
	_goal = goal
	_rough = field.is_empty()
	_path = main.nav.find_path(at, to) if _rough else main.nav.walk_down(field, at, SMOOTH)
	guide.trail = _path


## Starts the trail at the player while they're still on the planned path; false once they've strayed from it.
func _follow(at: Vector2) -> bool:
	var best := -1
	var best_d: float = OFF_TRAIL
	var walked := 0.0
	for i in _path.size() - 1:
		if walked > TRAIL_HEAD:
			break
		walked += _path[i].distance_to(_path[i + 1])
		var d := at.distance_to(Geometry2D.get_closest_point_to_segment(at, _path[i], _path[i + 1]))
		if d <= best_d:
			best = i
			best_d = d
	if best < 0:
		return false
	_path = _path.slice(best)
	var trail := _path.slice(1)
	trail.insert(0, at)
	guide.trail = trail
	return true


## The cost field towards `goal`, built on a worker thread the first time it's asked for; empty until it's ready.
func _field(goal: Vector2i, to: Vector2) -> PackedInt32Array:
	if goal in _fields:
		return _fields[goal]
	if _field_task >= 0:
		if not WorkerThreadPool.is_task_completed(_field_task):
			return PackedInt32Array()
		WorkerThreadPool.wait_for_task_completion(_field_task)
		_field_task = -1
		_fields[_field_cell] = _field_out
		return _field(goal, to)
	_field_cell = goal
	_field_task = WorkerThreadPool.add_task(func() -> void: _field_out = main.nav.cost_field(to))
	return PackedInt32Array()


func _exit_tree() -> void:
	if _field_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_field_task)


func _finish() -> void:
	main.playlog.write("tutorial_done", {"time": colony.time})
	colony.hold = false
	colony.only = []
	hud.goal_text = ""
	hud.only_show(ALL_CHIPS)
	guide.lead = false
	guide.trail = PackedVector2Array()
	_pulse_use(false)
	set_process(false)
	var quiet := 0.0
	while quiet < BRIEF_DELAY:
		await get_tree().process_frame
		quiet = 0.0 if _busy() else quiet + get_process_delta_time()
	_lift_shadows(true)
	dialog.say(OUTRO, main.player.colour)
	await dialog.closed
	_lift_shadows(false)
	hud.show_message("Tutorial complete!", 6.0)


## The "base online" banner; the game keeps running underneath.
func _banner() -> void:
	var title := TextureRect.new()
	title.texture = MENU_SCRIPT.scaled(ColonyMap.texture(ColonyMap.PROPS + "menu_base_online.png"), 2)
	title.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var half := title.texture.get_size() * 0.5
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.anchor_top = 0.4
	title.anchor_bottom = 0.4
	title.offset_left = -half.x
	title.offset_right = half.x
	title.offset_top = -half.y
	title.offset_bottom = half.y
	title.pivot_offset = half
	title.scale = Vector2(0.5, 0.5)
	main.get_node("HUD").add_child(title)
	var tw := title.create_tween()
	tw.tween_property(title, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.5)
	tw.tween_property(title, "modulate:a", 0.0, 0.8)
	tw.tween_callback(title.queue_free)
