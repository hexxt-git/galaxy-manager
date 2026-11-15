extends Control

## Full-screen choice of one card out of a few. Pauses the game while open.
## Cards are wide rows stacked under a header plate, so the same layout fits portrait phones and landscape PCs.

signal chosen(card: Dictionary)

const HUD := preload("res://scripts/colony/hud.gd")
const INK := Color("0d0d12")
const MUTED := Color("46546b")
const LOCK := 2.0  # seconds before a card can be picked, so a stray tap doesn't choose
const WIDTH := 640.0
const WINDOW := Vector2(196, 164)
# upgrade id -> [picture (a prop, or "" for a crewmate), resource icon it helps]
const UPGRADE_ART := {
	"bed": ["potato_bed", "food"], "bed_x": ["potato_bed", "food"], "automation": ["potato_bed", "food"],
	"panel": ["solar_panel", "power"], "panel_x": ["solar_panel", "power"], "coating": ["solar_panel", "power"],
	"reactor": ["fission_reactor", "power"], "bit": ["ice_drill", "water"], "recycler": ["ice_melter", "water"],
	"lab_x": ["lab_bench", "research"], "boots": ["", "crew"], "training": ["", "crew"],
}
const ROLE_ICON := {"ice": "water", "air": "o2", "harvest": "food", "solar": "power", "rocks": "research"}

var _header := PanelContainer.new()
var _header_icon := TextureRect.new()
var _title := Label.new()
var _row := VBoxContainer.new()
var _pills: Array[Panel] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_to_group("blocks_joystick")
	hide()
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.08, 0.85)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = WIDTH
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	_header.add_theme_stylebox_override("panel", HUD.nine("chip", 12, Vector4(18, 10, 18, 22)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_header.add_child(row)
	_header_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	row.add_child(_header_icon)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", INK)
	row.add_child(_title)
	box.add_child(_header)
	_row.add_theme_constant_override("separation", 14)
	box.add_child(_row)


func open(title: String, cards: Array) -> void:
	_title.text = title
	_header_icon.texture = HUD.ui_tex(HUD.ICONS["crew" if cards and cards[0].has("colour") else "research"])
	for c in _row.get_children():
		c.queue_free()
	_pills.clear()
	var buttons: Array[Button] = []
	for card in cards:
		var b := _card(card)
		b.disabled = true
		b.scale = Vector2(0.96, 0.96)
		_row.add_child(b)
		buttons.append(b)
	_set_pills(false)
	show()
	get_tree().paused = true
	var tw := create_tween()
	for b in buttons:
		b.pivot_offset = Vector2(WIDTH, b.custom_minimum_size.y) * 0.5
		tw.parallel().tween_property(b, "scale", Vector2.ONE, LOCK).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		_set_pills(true)
		for b in buttons:
			if is_instance_valid(b):
				b.disabled = false)


## The column's height with its text wrapped at `width` (a wrapping label's own minimum is measured at zero width).
func _height(col: VBoxContainer, width: float) -> float:
	var h := col.get_theme_constant("separation") * (col.get_child_count() - 1.0)
	for c: Control in col.get_children():
		if c is Label and c.autowrap_mode != TextServer.AUTOWRAP_OFF:
			var fs: int = c.get_theme_font_size("font_size")
			h += c.get_theme_font("font").get_multiline_string_size(c.text, HORIZONTAL_ALIGNMENT_LEFT, width, fs).y
		else:
			h += c.get_combined_minimum_size().y
	return h


func _set_pills(ready: bool) -> void:
	for p in _pills:
		if is_instance_valid(p):
			p.add_theme_stylebox_override("panel", HUD.nine("pill" if ready else "pill_off", 12, Vector4.ZERO))
			(p.get_child(0) as Label).add_theme_color_override("font_color", INK if ready else Color("62666e"))


func _label(text: String, size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = MOUSE_FILTER_IGNORE
	return l


## An icon and a word, e.g. the crewmate's role or what an upgrade helps.
func _tag(icon: String, text: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = MOUSE_FILTER_IGNORE
	var t := TextureRect.new()
	t.texture = HUD.ui_tex(HUD.ICONS[icon], 1)
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.mouse_filter = MOUSE_FILTER_IGNORE
	h.add_child(t)
	var l := _label(text, 18, INK)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(l)
	return h


## The dark screen on the left: the crewmate, or the station an upgrade builds or improves.
func _window(card: Dictionary) -> Control:
	var w := Panel.new()
	w.custom_minimum_size = WINDOW
	w.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	w.clip_contents = true
	w.mouse_filter = MOUSE_FILTER_IGNORE
	w.add_theme_stylebox_override("panel", HUD.nine("card_window", 10, Vector4.ZERO))
	var tex: Texture2D
	if card.has("colour"):
		tex = HUD.portrait(card.colour)
	else:
		var prop: String = UPGRADE_ART.get(card.id, ["", "research"])[0]
		tex = HUD.portrait("blue") if prop == "" else _prop(prop)
	var pic := TextureRect.new()
	pic.texture = tex
	pic.mouse_filter = MOUSE_FILTER_IGNORE
	# bottom-centred and allowed to spill past the sides: wide props are cropped by the window
	pic.size = tex.get_size()
	pic.position = Vector2((WINDOW.x - tex.get_width()) * 0.5, WINDOW.y - tex.get_height() - 8.0)
	w.add_child(pic)
	return w


func _prop(name: String) -> Texture2D:
	var img := ColonyMap.texture(ColonyMap.PROPS + name + ".png").get_image()
	img.resize(img.get_width() * ColonyMap.PX, img.get_height() * ColonyMap.PX, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


func _card(card: Dictionary) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	var face := HUD.nine("card", 16)
	var hover := HUD.nine("card_hover", 16)
	for st in ["normal", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, face)
	for st in ["hover", "pressed"]:
		b.add_theme_stylebox_override(st, hover)
	b.custom_minimum_size = Vector2(WIDTH, WINDOW.y + 42)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_right = -18
	row.offset_top = 16
	row.offset_bottom = -26
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	b.add_child(row)
	row.add_child(_window(card))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(col)
	var top := HBoxContainer.new()
	top.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(top)
	var name_l := _label(card.get("name", card.title), 26, INK)
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_l)
	var pill := Panel.new()
	pill.custom_minimum_size = Vector2(104, 52)
	pill.mouse_filter = MOUSE_FILTER_IGNORE
	pill.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var pick := _label("PICK", 20, INK)
	pick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pick.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	pick.offset_bottom = -8
	pill.add_child(pick)
	top.add_child(pill)
	_pills.append(pill)
	b.button_down.connect(func() -> void: pill.add_theme_stylebox_override("panel", HUD.nine("pill_pressed", 12, Vector4.ZERO)))
	if card.has("role"):
		var perk: Array = Colony.PERKS[card.perk]
		var tags := HBoxContainer.new()
		tags.add_theme_constant_override("separation", 20)
		tags.mouse_filter = MOUSE_FILTER_IGNORE
		tags.add_child(_tag(ROLE_ICON.get(card.role, "crew"), Colony.ROLES[card.role][0]))
		tags.add_child(_tag("crew", perk[0]))
		col.add_child(tags)
		col.add_child(_label("%s %s Helps out anywhere else." % [Colony.ROLES[card.role][1], perk[1]], 18, MUTED))
	else:
		var build: bool = Colony.UPGRADES.has(card.get("id", "")) and Colony.UPGRADES[card.id][2].has("slot")
		col.add_child(_tag(UPGRADE_ART.get(card.get("id", ""), ["", "research"])[1], "NEW BUILDING" if build else "UPGRADE"))
		col.add_child(_label(card.text, 18, MUTED))
	b.custom_minimum_size.y = maxf(WINDOW.y, _height(col, WIDTH - WINDOW.x + row.offset_right - row.offset_left - 16)) \
			+ row.offset_top - row.offset_bottom
	b.pressed.connect(func() -> void:
		hide()
		get_tree().paused = false
		chosen.emit(card))
	return b
