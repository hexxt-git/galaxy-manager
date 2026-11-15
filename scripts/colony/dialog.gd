extends Control

## Visual-novel speech box: a crewmate's bust on the left (or a title tag, for signs), text typed out letter by
## letter. Pauses the game while open. A tap, click, E, Space or Enter finishes the line, or moves to the next one once it's all shown.

signal closed

const HUD := preload("res://scripts/colony/hud.gd")
const MENU := preload("res://scripts/menu.gd")
const K := 2  # screen px per art px for the box
const FACE_K := 4  # the bust is drawn bigger, like a visual novel
const BUST_ROWS := 46  # art px of the character kept for the bust: head and shoulders
const MARGIN := 16
const SINK := 40  # px of the bust tucked behind the box
const PAD := Vector2(30, 22)
const CPS := 42.0  # letters per second
const STOP_PAUSE := 0.22  # extra wait after . ! ?
const INK := Color("0d0d12")

var _lines: Array = []
var _i := 0
var _shown := 0.0
var _wait := 0.0
var _t := 0.0
var _box := TextureRect.new()
var _bust := TextureRect.new()
var _text := Label.new()
var _next := TextureRect.new()
var _title := Label.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	add_to_group("blocks_joystick")
	hide()
	_box.texture = MENU.scaled(ColonyMap.texture(ColonyMap.PROPS + "dialog_box.png"), K)
	var box_size := _box.texture.get_size()
	_anchor_bottom(_bust)
	_anchor_bottom(_box)
	_box.offset_left = -box_size.x * 0.5
	_box.offset_right = box_size.x * 0.5
	_box.offset_top = -box_size.y - MARGIN
	_box.offset_bottom = -MARGIN
	add_child(_bust)
	add_child(_box)
	_text.position = PAD
	_text.size = box_size - PAD * 2.0
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_text.add_theme_font_size_override("font_size", 30)
	_text.add_theme_color_override("font_color", INK)
	_text.add_theme_constant_override("line_spacing", -4)
	_box.add_child(_text)
	_title.position = PAD - Vector2(0, 6)
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", Color("b5651d"))
	_box.add_child(_title)
	_next.texture = MENU.scaled(ColonyMap.texture(ColonyMap.PROPS + "dialog_next.png"), K)
	_next.position = box_size - _next.texture.get_size() - Vector2(22, 14)
	_box.add_child(_next)


func _anchor_bottom(c: Control) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 1.0
	c.anchor_bottom = 1.0
	c.mouse_filter = MOUSE_FILTER_IGNORE


## Shows `lines` one after another, spoken by a crewmate in `colour` (none for a sign, headed by `title`);
## `closed` fires after the last.
func say(lines: Array, colour: String, title := "") -> void:
	_bust.visible = colour != ""
	if _bust.visible:
		var img := HUD.portrait(colour, false, FACE_K).get_image()
		img = img.get_region(Rect2i(0, 0, img.get_width(), BUST_ROWS * FACE_K))
		_bust.texture = ImageTexture.create_from_image(img)
	_title.text = title.to_upper()
	_title.visible = title != ""
	_text.position = PAD + (Vector2(0, 24) if title != "" else Vector2.ZERO)
	var box := _box.texture.get_size()
	var bust := _bust.texture.get_size() if _bust.texture else Vector2.ZERO
	_bust.offset_left = -box.x * 0.5 + 12
	_bust.offset_right = _bust.offset_left + bust.x
	_bust.offset_bottom = -MARGIN - box.y + SINK
	_bust.offset_top = _bust.offset_bottom - bust.y
	_lines = lines
	_i = 0
	_start_line()
	show()
	get_tree().paused = true
	_box.pivot_offset = box * 0.5
	_box.scale = Vector2(0.9, 0.9)
	_box.create_tween().tween_property(_box, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _start_line() -> void:
	_text.text = _lines[_i]
	_text.visible_characters = 0
	_shown = 0.0
	_wait = 0.0


func _typing() -> bool:
	return int(_shown) < _text.text.length()


func _advance() -> void:
	if _typing():
		_shown = _text.text.length()
		_text.visible_characters = -1
		return
	_i += 1
	if _i < _lines.size():
		_start_line()
		return
	hide()
	get_tree().paused = false
	closed.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_advance()


func _input(event: InputEvent) -> void:
	if not visible or event.is_echo():
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _typing():
		if _wait > 0.0:
			_wait -= delta
		else:
			var before := int(_shown)
			_shown += delta * CPS
			var at := mini(int(_shown), _text.text.length())
			if at > before and _text.text[at - 1] in ".!?":
				_wait = STOP_PAUSE
		_text.visible_characters = int(_shown)
	_next.visible = not _typing()
	_next.position.y = _box.texture.get_size().y - _next.texture.get_size().y - 14 + roundf(sin(_t * 6.0)) * 2.0 * K
