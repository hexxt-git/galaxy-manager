extends Control

## Full-screen choice of one card out of a few. Pauses the game while open.

signal chosen(card: Dictionary)

const CREWMATE := preload("res://scripts/crewmate.gd")
const HUD := preload("res://scripts/colony/hud.gd")
const INK := Color("0d0d12")
const LOCK := 2.0  # seconds before a card can be picked, so a stray tap doesn't choose

var _title := Label.new()
var _row := HBoxContainer.new()


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
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 28)
	box.offset_left = 40
	box.offset_right = -40
	add_child(box)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_size_override("font_size", 34)
	box.add_child(_title)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 14)
	box.add_child(_row)


func open(title: String, cards: Array) -> void:
	_title.text = title
	for c in _row.get_children():
		c.queue_free()
	var buttons: Array[Button] = []
	for card in cards:
		var b := _card(card)
		b.disabled = true
		b.scale = Vector2(0.96, 0.96)
		_row.add_child(b)
		buttons.append(b)
	show()
	get_tree().paused = true
	var tw := create_tween()
	for b in buttons:
		b.pivot_offset = b.custom_minimum_size * 0.5
		tw.parallel().tween_property(b, "scale", Vector2.ONE, LOCK).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		for b in buttons:
			if is_instance_valid(b):
				b.disabled = false)


func _card(card: Dictionary) -> Button:
	var b := Button.new()
	var face := HUD.nine("card", 16)
	var hover := HUD.nine("card_hover", 16)
	for st in ["normal", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, face)
	for st in ["hover", "pressed"]:
		b.add_theme_stylebox_override(st, hover)
	b.custom_minimum_size = Vector2(220, 400)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_right = -14
	v.offset_top = 20
	v.offset_bottom = -34
	v.add_theme_constant_override("separation", 12)
	v.mouse_filter = MOUSE_FILTER_IGNORE
	b.add_child(v)
	if card.has("colour"):
		var who := TextureRect.new()
		who.texture = HUD.portrait(card.colour)
		who.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		who.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		who.mouse_filter = MOUSE_FILTER_IGNORE
		v.add_child(who)
	for t in [[card.title, 24], [card.text, 18]]:
		var l := Label.new()
		l.text = t[0]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", t[1])
		l.add_theme_color_override("font_color", INK)
		l.mouse_filter = MOUSE_FILTER_IGNORE
		v.add_child(l)
	b.pressed.connect(func() -> void:
		hide()
		get_tree().paused = false
		chosen.emit(card))
	return b
