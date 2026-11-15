extends Control

## Resource chips (value, trend, progress to the next crewmate or upgrade; red when running low), the current
## objective with flare tags, event messages, the crew list, the focused target's prompt, and the drop and map buttons.

signal drop_pressed
signal map_pressed

const CREWMATE := preload("res://scripts/crewmate.gd")
const INK := Color("0d0d12")
const OK := Color.WHITE
const LOW := Color("ff6b5e")
const MUTED := Color("aab3c2")
const BAR_BG := Color(1, 1, 1, 0.15)
const BAR_FG := Color("7ed957")
const MESSAGE_TIME := 4.0
const TREND_WINDOW := 10.0  # seconds the per-minute trend is measured over
const RUNOUT := 60.0  # a stock that would empty within this many seconds counts as low

var colony: Colony
var hands: Hands
var detector: InteractionDetector
var player: Node
var blocked := ""  # why the focused target can't be used right now

var _chips := {}  # id -> {value, sub, bar}
var _goal := _label(22, Color("f2c230"))
var _message := _label(22, Color("ffd2a8"))
var _prompt := _label(24, OK)
var _crew := VBoxContainer.new()
var _drop := Button.new()
var _map := Button.new()
var _message_t := 0.0
var _rows: Array = []  # [node, label]
var _history: Array = []  # [time, res copy]


func _label(size: int, colour: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 6)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = MOUSE_FILTER_IGNORE
	return l


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	var band := ColorRect.new()
	band.color = Color(0.05, 0.06, 0.09, 0.8)
	band.mouse_filter = MOUSE_FILTER_IGNORE
	band.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	band.offset_bottom = 232
	add_child(band)
	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	top.offset_left = 12
	top.offset_right = -116
	top.offset_top = 10
	top.add_theme_constant_override("separation", 6)
	top.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(top)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.mouse_filter = MOUSE_FILTER_IGNORE
	top.add_child(grid)
	for id in ["o2", "water", "food", "power", "research", "crew"]:
		grid.add_child(_chip(id, {"o2": "OXYGEN", "water": "WATER", "food": "FOOD", "power": "POWER", "research": "RESEARCH", "crew": "CREW"}[id]))
	top.add_child(_goal)
	top.add_child(_message)

	_crew.position = Vector2(12, 248)
	_crew.mouse_filter = MOUSE_FILTER_IGNORE
	_crew.add_theme_constant_override("separation", 2)
	add_child(_crew)

	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	_prompt.offset_left = -440
	_prompt.offset_right = -24
	_prompt.offset_top = -270
	_prompt.offset_bottom = -212
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	add_child(_prompt)

	for b in [[_drop, "DROP", drop_pressed, PRESET_BOTTOM_RIGHT, Rect2(-330, -150, 110, 60)],
			[_map, "MAP", map_pressed, PRESET_TOP_RIGHT, Rect2(-104, 14, 92, 56)]]:
		var btn: Button = b[0]
		btn.text = b[1]
		btn.add_theme_font_size_override("font_size", 24)
		btn.set_anchors_and_offsets_preset(b[3])
		var r: Rect2 = b[4]
		btn.offset_left = r.position.x
		btn.offset_top = r.position.y
		btn.offset_right = r.end.x
		btn.offset_bottom = r.end.y
		btn.add_to_group("blocks_joystick")
		var sig: Signal = b[2]
		btn.pressed.connect(sig.emit)
		add_child(btn)


func _chip(id: String, title: String) -> Control:
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.06)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 6
	box.add_theme_stylebox_override("panel", style)
	box.custom_minimum_size = Vector2(190, 0)
	box.mouse_filter = MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(v)
	var head := _label(13, MUTED)
	head.text = title
	head.autowrap_mode = TextServer.AUTOWRAP_OFF
	var value := _label(26, OK)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	var sub := _label(14, MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 5)
	bar.max_value = 1.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = BAR_BG
	bg.set_corner_radius_all(3)
	var fg := StyleBoxFlat.new()
	fg.bg_color = BAR_FG
	fg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	bar.mouse_filter = MOUSE_FILTER_IGNORE
	for c in [head, value, sub, bar]:
		v.add_child(c)
	_chips[id] = {"value": value, "sub": sub, "bar": bar, "box": style}
	return box


func show_message(text: String, seconds := MESSAGE_TIME) -> void:
	_message.text = text
	_message_t = seconds


func rebuild_crew() -> void:
	for c in _crew.get_children():
		c.queue_free()
	_rows.clear()
	for c in colony.crew:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = MOUSE_FILTER_IGNORE
		var dot := ColorRect.new()
		dot.color = CREWMATE.COLOURS[c.colour][0]
		dot.custom_minimum_size = Vector2(16, 16)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = MOUSE_FILTER_IGNORE
		row.add_child(dot)
		var l := _label(17, OK)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(l)
		_crew.add_child(row)
		_rows.append([c, l])


func _trend(key: String) -> float:
	if _history.size() < 2:
		return 0.0
	var a: Array = _history.front()
	var dt: float = colony.time - a[0]
	return (colony.res[key] - a[1][key]) / dt * 60.0 if dt > 0.5 else 0.0


func _show(id: String, value: String, sub: String, low: bool, bar := -1.0) -> void:
	var c: Dictionary = _chips[id]
	c.value.text = value
	c.value.add_theme_color_override("font_color", LOW if low else OK)
	c.sub.text = sub
	c.box.bg_color = Color(1, 0.3, 0.25, 0.18) if low else Color(1, 1, 1, 0.06)
	c.bar.visible = bar >= 0.0
	c.bar.value = clampf(bar, 0.0, 1.0)


func _stock(id: String) -> void:
	var v: float = colony.res[id]
	var rate := _trend(id)
	var runs_out := rate < -0.01 and v / -rate * 60.0 < RUNOUT
	var sub := "%+.1f / min" % rate if absf(rate) >= 0.05 else "steady"
	_show(id, "%.1f" % v, sub, v < 1.0 or runs_out)


func _process(delta: float) -> void:
	if colony == null:
		return
	_history.append([colony.time, colony.res.duplicate()])
	while _history.size() > 2 and colony.time - _history.front()[0] > TREND_WINDOW:
		_history.pop_front()

	_stock("o2")
	_stock("water")
	var food: float = colony.res.food
	var cost := colony.crew_cost()
	var full := colony.crew.size() >= Colony.MAX_CREW
	_show("food", "%.1f" % food, "base is full" if full else ("ready: go to Comms" if food >= cost else "next crewmate %d" % cost), food < 0.5 and _trend("food") < 0.0, -1.0 if full else food / cost)
	var p := colony.power
	var ratio := clampf(p.x / p.y, 0.0, 1.0) if p.y > 0.0 else 1.0
	_show("power", "%.1f / %.1f" % [p.x, p.y], "beds at %d%%" % int(ratio * 100) if ratio < 1.0 else "enough for everything", ratio < 1.0)
	var r: float = colony.res.research
	var rc := colony.upgrade_cost()
	_show("research", "%d" % r, "next upgrade %d" % rc, false, r / rc)
	var t := "%d:%02d" % [int(colony.time) / 60, int(colony.time) % 60]
	var unshielded: bool = colony.unlocked.has("shield") and colony.res.shield < colony.shield_need()
	var crew_sub := "shield %d / %d" % [colony.res.shield, colony.shield_need()] if colony.unlocked.has("shield") else "time %s" % t
	var goal := Colony.MAX_CREW if colony.finished else Colony.WIN_CREW
	_show("crew", "%d / %d" % [colony.crew.size(), goal], crew_sub, unshielded and colony.flare_in < 30.0, float(colony.crew.size()) / goal)

	var tags := []
	if colony.fatigue > 0.0:
		tags.append("FLARE FATIGUE %ds" % ceili(colony.fatigue))
	elif colony.flare_in < 30.0:
		tags.append("FLARE IN %ds" % ceili(colony.flare_in))
	_goal.text = ("[%s]  " % "  ".join(tags) if tags else "") + "> " + colony.current_objective()[0]
	_message_t -= delta
	_message.visible = _message_t > 0.0
	_drop.visible = hands and not hands.is_empty()
	var focus := detector.focus if detector else null
	if focus == null:
		_prompt.text = ""
	elif blocked != "":
		_prompt.text = blocked
		_prompt.add_theme_color_override("font_color", MUTED)
	else:
		_prompt.text = focus.prompt
		_prompt.add_theme_color_override("font_color", OK)
	for row in _rows:
		var c: Node = row[0]
		if not is_instance_valid(c):
			continue
		if c == player:
			row[1].text = "You · Commander"
		else:
			row[1].text = "%s · %s (%s) · %s" % [c.crew_name, Colony.ROLES[c.role][0], Colony.PERKS[c.perk][0], c.busy_with]
