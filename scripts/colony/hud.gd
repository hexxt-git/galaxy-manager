extends Control

## Resource chips (value, trend, progress to the next crewmate or upgrade; red when running low), the current
## objective, event messages, the crew list, the focused target's prompt, and the drop and map buttons.

signal drop_pressed
signal map_pressed

const CREWMATE := preload("res://scripts/crewmate.gd")
const INK := Color("0d0d12")
const OK := Color.WHITE
const LOW := Color("c8453f")
const MUTED := Color("5f6b7a")
const MESSAGE_TIME := 4.0
const TREND_WINDOW := 10.0  # seconds the per-minute trend is measured over
const RUNOUT := 60.0  # a stock that would empty within this many seconds counts as low
const UI := "res://assets/art/ui/"
const UI_SCALE := 2  # same as the USE button
const ICONS := {"o2": "icon_o2", "water": "icon_water", "food": "icon_food", "power": "icon_power",
	"research": "icon_research", "crew": "icon_crew"}


static var _portraits := {}


## The crewmate sprite in their suit colour, cropped to the head when `head`.
static func portrait(colour: String, head := false, k := UI_SCALE) -> Texture2D:
	var key := "%s %s %d" % [colour, head, k]
	if not _portraits.has(key):
		var img := ColonyMap.texture("res://assets/art/character/character.png").get_image()
		img.convert(Image.FORMAT_RGBA8)
		var tones: Array = CREWMATE.COLOURS[colour]
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.0 and c.r8 == 255 and c.g8 == 0 and c.b8 == 0:
					img.set_pixel(x, y, Color(tones[0], c.a))
				elif c.a > 0.0 and c.r8 == 0 and c.g8 == 0 and c.b8 == 255:
					img.set_pixel(x, y, Color(tones[1], c.a))
		if head:
			img = img.get_region(Rect2i(0, 0, img.get_width(), 44))
		img.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
		_portraits[key] = ImageTexture.create_from_image(img)
	return _portraits[key]


## UI art upscaled by whole pixels, so it stays crisp like the world art.
static func ui_tex(name: String, k := UI_SCALE) -> Texture2D:
	var t := ColonyMap.texture(UI + name + ".png")
	if t == null:
		return null
	var img := t.get_image()
	img.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


## A 9-slice from the UI art, scaled like the USE button.
static func nine(name: String, margin: int, pad := Vector4(14, 8, 14, 10)) -> StyleBox:
	var tex := ui_tex(name)
	if tex == null:
		return StyleBoxEmpty.new()
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	for i in 4:
		sb.set_texture_margin(i, margin * UI_SCALE)
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	return sb


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
var _drop := TextureButton.new()
var _map := TextureButton.new()
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
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	top.offset_left = 12
	top.offset_right = -180
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

	_crew.mouse_filter = MOUSE_FILTER_IGNORE
	_crew.add_theme_constant_override("separation", 2)
	top.add_child(_crew)

	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	_prompt.offset_left = -440
	_prompt.offset_right = -24
	_prompt.offset_top = -270
	_prompt.offset_bottom = -212
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	add_child(_prompt)

	for b in [[_drop, "drop_button", drop_pressed, PRESET_BOTTOM_RIGHT, Vector2(-360, -204)],
			[_map, "map_button", map_pressed, PRESET_TOP_RIGHT, Vector2(-168, 12)]]:
		var btn: TextureButton = b[0]
		btn.texture_normal = ColonyMap.texture(UI + b[1] + ".png")
		btn.texture_pressed = ColonyMap.texture(UI + b[1] + "_pressed.png")
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		btn.set_anchors_and_offsets_preset(b[3])
		btn.offset_left = b[4].x
		btn.offset_top = b[4].y
		btn.offset_right = b[4].x + 76
		btn.offset_bottom = b[4].y + 80
		btn.scale = Vector2(UI_SCALE, UI_SCALE)
		btn.add_to_group("blocks_joystick")
		var sig: Signal = b[2]
		btn.pressed.connect(sig.emit)
		add_child(btn)


func _chip(id: String, title: String) -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _chip_style(false))
	box.custom_minimum_size = Vector2(236, 0)
	box.mouse_filter = MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(h)
	var icon := TextureRect.new()
	icon.texture = ui_tex(ICONS[id])
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	h.add_child(icon)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = MOUSE_FILTER_IGNORE
	h.add_child(v)
	var head := _label(15, MUTED)
	head.text = title
	head.autowrap_mode = TextServer.AUTOWRAP_OFF
	var value := _label(26, OK)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	var sub := _label(16, MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	bar.max_value = 1.0
	var bg := _bar_style("bar_bg")
	var fg := _bar_style("bar_fill")
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	bar.mouse_filter = MOUSE_FILTER_IGNORE
	for c in [head, value, sub, bar]:
		if c is Label:
			c.add_theme_constant_override("outline_size", 0)
			if c != head and c != sub:
				c.add_theme_color_override("font_color", INK)
		v.add_child(c)
	_chips[id] = {"value": value, "sub": sub, "bar": bar, "box": box, "low": false}
	return box


var _chip_styles := {}


func _bar_style(name: String) -> StyleBox:
	var sb := nine(name, 4, Vector4.ZERO)
	if sb is StyleBoxTexture:
		sb.texture_margin_bottom = 3 * UI_SCALE
	return sb


func _chip_style(low: bool) -> StyleBox:
	if not _chip_styles.has(low):
		_chip_styles[low] = nine("chip", 12, Vector4(14, 8, 16, 14))
	return _chip_styles[low]


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
		var face := TextureRect.new()
		face.texture = portrait(c.colour, true, 1)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.custom_minimum_size = Vector2(34, 22)
		face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		face.mouse_filter = MOUSE_FILTER_IGNORE
		row.add_child(face)
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
	c.value.add_theme_color_override("font_color", LOW if low else INK)
	c.sub.text = sub
	if c.low != low:
		c.low = low
		c.box.self_modulate = Color(1, 0.72, 0.68) if low else Color.WHITE
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
	var crew_sub := "time %s" % t
	var goal := Colony.MAX_CREW if colony.finished else Colony.WIN_CREW
	_show("crew", "%d / %d" % [colony.crew.size(), goal], crew_sub, false, float(colony.crew.size()) / goal)

	_goal.text = "> " + colony.current_objective()[0]
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
