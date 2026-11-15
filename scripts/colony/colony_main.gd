extends Node2D

## Wires the colony prototype together: map, rules, player, crew, card pickers, task panel, map overlay and lighting.

const BOT := preload("res://scenes/bot.tscn")
const HELPER := preload("res://scripts/colony/helper.gd")
const NavGrid := preload("res://scripts/bots/nav_grid.gd")
const PLAYLOG := preload("res://scripts/colony/playlog.gd")
const TUTORIAL := preload("res://scripts/colony/tutorial.gd")
const DIALOG := preload("res://scripts/colony/dialog.gd")
const CRATER_DARK := preload("res://assets/shaders/crater_dark.gdshader")
const VISION := preload("res://scripts/colony/colony_vision.gd")
const OUTSIDE_DARK := preload("res://assets/shaders/outside_dark.gdshader")
const POPUP_RISE := 70.0
const POPUP_TIME := 1.2
const FADE_IN := 0.8

@onready var colony: Colony = $Colony
@onready var map: ColonyMap = $World/Map
@onready var items: Node2D = $World/Items
@onready var helpers: Node2D = $World/Helpers
@onready var player: CharacterBody2D = $World/Player
@onready var hands: Hands = $World/Player/Hands
@onready var detector: InteractionDetector = $World/Player/InteractionDetector
@onready var panel: TaskPanel = $HUD/TaskPanel
@onready var hud: Control = $HUD/Hud
@onready var picker: Control = $HUD/Picker
@onready var minimap: Control = $HUD/Minimap
@onready var guide: Node2D = $World/Guide
@onready var use_button: TextureButton = $HUD/UseButton

var nav: NavGrid
var _content: Control
var _offer_kind := ""
var _pending_offer: Array = []
var _area := ""
var _offer_ms := 0
var _open_ms := 0
var _open_title := ""
var playlog: Node
var dialog: Control = DIALOG.new()


var _dark_mat := ShaderMaterial.new()


func _add_crater_dark() -> void:
	var t := ColonyMap.TILE
	var past := 40.0 * t  # reaches as far as the outside darkness, so the two never meet in a seam
	var rect := Rect2(-past, 26.4 * t, map.cols() * t + past * 2.0, (map.rows() - 26.4) * t + past)
	_dark_mat.shader = CRATER_DARK
	_dark_mat.set_shader_parameter("rect_pos", rect.position)
	_dark_mat.set_shader_parameter("rect_size", rect.size)
	var dark := ColorRect.new()
	dark.material = _dark_mat
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark.position = rect.position
	dark.size = rect.size
	dark.z_index = 50
	dark.z_as_relative = false
	$World.add_child(dark)


# Past the border rocks it fades to night, so the map never shows an edge.
func _add_outside_dark() -> void:
	var t := ColonyMap.TILE
	var inner := Rect2(t, t, (map.cols() - 2) * t, (map.rows() - 2) * t + 50.0)
	var mat := ShaderMaterial.new()
	mat.shader = OUTSIDE_DARK
	var rect := inner.grow(40.0 * t)
	mat.set_shader_parameter("rect_pos", rect.position)
	mat.set_shader_parameter("rect_size", rect.size)
	mat.set_shader_parameter("inner_pos", inner.position)
	mat.set_shader_parameter("inner_size", inner.size)
	mat.set_shader_parameter("dark", RenderingServer.get_default_clear_color())
	var dark := ColorRect.new()
	dark.material = mat
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark.position = rect.position
	dark.size = rect.size
	dark.z_index = 50
	dark.z_as_relative = false
	$World.add_child(dark)


func _ready() -> void:
	var fade := _black_cover()
	$HUD.add_child(dialog)
	playlog = PLAYLOG.new()
	playlog.colony = colony
	playlog.main = self
	add_child(playlog)
	items.add_to_group("item_layer")
	map.build(items)
	_add_crater_dark()
	var vision := VISION.new()
	vision.viewer = player
	vision.map = map
	add_child(vision)
	_add_outside_dark()
	colony.setup(map, items)
	player.global_position = map.spawn
	player.set_meta("base_speed", Colony.WALK)
	for s in map.stations:
		s.used.connect(_on_station_used)
	colony.message.connect(hud.show_message)
	colony.popup.connect(_popup)
	colony.offer.connect(_on_offer)
	colony.station_added.connect(_on_station_added)
	colony.crew_changed.connect(hud.rebuild_crew)
	colony.won.connect(_on_won)
	hud.colony = colony
	hud.hands = hands
	hud.detector = detector
	hud.player = player
	hud.drop_pressed.connect(_drop)
	hud.map_pressed.connect(func() -> void:
		minimap.toggle()
		playlog.write("map", {"open": minimap.visible, "via": "button"}))
	minimap.map = map
	minimap.colony = colony
	minimap.player = player
	guide.colony = colony
	guide.player = player
	guide.detector = detector
	guide.hands = hands
	picker.chosen.connect(_on_chosen)
	panel.closed.connect(_clear_content)
	colony.did.connect(func(s: Station, actor: Node, result: String) -> void:
		playlog.write("did", {"who": _who(actor), "station": s.title, "station_id": str(s.name), "station_state": s.state,
			"at": actor.global_position, "after": result}))
	colony.message.connect(func(text: String) -> void: playlog.write("message", {"text": text}))
	colony.won.connect(func() -> void: playlog.write("won", {}))
	hands.changed.connect(func() -> void: playlog.write("hands", {"holding": Items.label(hands.type, hands.count) if hands.count else "nothing"}))
	colony.add_crew(player)
	hud.show_message("Move: WASD or the stick.  Use: E or the USE button.  Drop: G.  Map: M.", 10.0)
	var tutorial: Node = null
	if Colony.start_tutorial:
		tutorial = TUTORIAL.new()
		tutorial.main = self
		add_child(tutorial)
	await _build_nav()
	if tutorial:
		tutorial.begin()
	var tw := fade.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(fade.get_child(0), "modulate:a", 0.0, FADE_IN)
	tw.tween_callback(fade.queue_free)


## Black over everything until the map, crew and paths are ready.
func _black_cover() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 100
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	add_child(layer)
	return layer


func _who(actor: Node) -> String:
	return "you" if actor == player else "%s the %s" % [actor.crew_name, Colony.ROLES[actor.role][0]]


func _build_nav() -> void:
	# new collision shapes only reach the physics space's queries after a physics step
	await get_tree().physics_frame
	await get_tree().physics_frame
	var probe := BOT.instantiate()
	var grid := NavGrid.new()
	grid.build(get_world_2d().direct_space_state, probe.get_node("Feet"), map.floor_rects, [player.get_rid()])
	probe.free()
	nav = grid
	for h in helpers.get_children():
		h.nav = grid


func _process(delta: float) -> void:
	colony.tick(delta)
	var why := ""
	var target: Node = detector.focus.get_parent() if is_instance_valid(detector.focus) else null
	if target is Station and target.kind != "note":
		why = colony.blocked_reason(target, player)
	hud.blocked = why
	hands.caption = _caption()
	guide.blocked = why != ""
	use_button.disabled = target == null or why != ""
	update_light()
	var area := map.char_at(player.global_position)
	if area != _area:
		_area = area
		playlog.write("area", {"where": {".": "inside", ",": "surface", ":": "crater"}.get(area, area), "at": player.global_position.round()})


## The crater's light circle follows the camera, so it moves along when the camera glances somewhere.
func update_light() -> void:
	var cam: Camera2D = player.get_node("Camera")
	_dark_mat.set_shader_parameter("light_pos", player.global_position + Vector2(0, -40) + cam.offset)


func _caption() -> String:
	if hands.is_empty():
		return ""
	var goals := colony.destinations(hands.type)
	if goals.is_empty():
		return Items.label(hands.type, hands.count)
	var names := []
	for g in goals:
		if g.title not in names:
			names.append(g.title)
	return "%s -> %s" % [Items.DEFS[hands.type].name, " or ".join(names)]


func _unhandled_input(event: InputEvent) -> void:
	for action in ["interact", "drop", "map", "move_left", "move_right", "move_up", "move_down"]:
		if event.is_action_pressed(action):
			playlog.write("key", {"action": action})
	if event.is_action_pressed("drop") and not panel.visible:
		_drop()
	elif event.is_action_pressed("map"):
		minimap.toggle()
		playlog.write("map", {"open": minimap.visible, "via": "key"})


func _drop() -> void:
	var dir := player.velocity.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.LEFT if player.sprite.flip_h else Vector2.RIGHT
	if hands.count:
		playlog.write("drop", {"item": Items.label(hands.type, hands.count)})
	hands.toss(dir)


func _on_offer(kind: String, cards: Array) -> void:
	if panel.visible:
		_pending_offer = [kind, cards]
		return
	_offer_kind = kind
	playlog.write("offer", {"kind": kind, "cards": cards, "food": colony.res.food, "research": colony.res.research,
		"power": colony.power, "crew": colony.crew.size()})
	_offer_ms = Time.get_ticks_msec()
	minimap.hide()
	if kind == "crew":
		picker.open("A lander is ready. Who joins the base?  (-%d food)" % colony.crew_cost(), cards)
	else:
		picker.open("Spend %d research on an upgrade" % colony.upgrade_cost(), cards)


func _on_chosen(card: Dictionary) -> void:
	var kind := _offer_kind
	playlog.write("chose", {"kind": kind, "card": card, "decide_s": (Time.get_ticks_msec() - _offer_ms) / 1000.0})
	colony.choose(kind, card)
	if kind == "crew":
		_spawn_helper(card)


func _spawn_helper(card: Dictionary) -> void:
	var h := BOT.instantiate()
	h.set_script(HELPER)
	h.colour = card.colour
	h.role = card.role
	h.perk = card.perk
	h.crew_name = card.name
	h.nav = nav
	h.colony = colony
	h.position = map.spawn + Vector2(randf_range(-80, 80), 40)
	h.add_collision_exception_with(player)
	helpers.add_child(h)
	colony.add_crew(h)


func _on_station_added(s: Station) -> void:
	s.used.connect(_on_station_used)
	_build_nav()


func _popup(at: Vector2, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Color("f2c230"))
	l.add_theme_color_override("font_outline_color", Color("0d0d12"))
	l.add_theme_constant_override("outline_size", 8)
	l.z_index = 60
	l.position = at - Vector2(100, 20)
	l.size = Vector2(200, 30)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$World.add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - POPUP_RISE, POPUP_TIME)
	tw.tween_property(l, "modulate:a", 0.0, POPUP_TIME).set_delay(POPUP_TIME * 0.4)
	tw.chain().tween_callback(l.queue_free)


func _on_station_used(s: Station, by: Node) -> void:
	if s.kind == "note":
		playlog.write("note", {"note": s.state.note})
		colony.bump("notes")
		var note: Array = Colony.NOTES[s.state.note]
		dialog.say(note[1], "", note[0])
		return
	if colony.tutorial_gated(s):
		hud.show_message(colony.blocked_reason(s, by))
		return
	if not hands.is_empty() and not colony.accepts(s, hands.type):
		playlog.write("auto_drop", {"item": Items.label(hands.type, hands.count), "station": s.title})
		_drop()
	var why := colony.blocked_reason(s, by)
	playlog.write("use", {"station": s.title, "station_id": str(s.name), "station_state": s.state, "who": _who(by),
		"holding": Items.label(hands.type, hands.count) if hands.count else "", "blocked": why, "at": player.global_position})
	if why != "":
		hud.show_message(why)
		return
	var mode := colony.minigame(s, by)
	if mode == "":
		colony.finish(s, by)
		return
	var game := Minigame.new()
	var skin_path := "res://scripts/colony/minigames/%s.gd" % s.kind
	if ResourceLoader.exists(skin_path):
		game.skin = load(skin_path).new()
	game.mode = mode
	game.heat = s.kind == "drill"
	if s.kind == "lab":
		game.goal = mini(Colony.SCAN_HITS, hands.count)
	game.fact = Colony.MINIGAMES[s.kind][1]
	playlog.write("minigame_start", {"station": s.title, "mode": mode, "goal": game.goal if mode == "timing" else 0,
		"holding": Items.label(hands.type, hands.count) if hands.count else ""})
	game.logged.connect(func(what: String, data: Dictionary) -> void:
		data.merge({"station": s.title, "input": what})
		playlog.write("minigame_input", data))
	if s.kind == "lab":
		var left := [game.goal]
		game.scored.connect(func() -> void:
			var bonus := Colony.SCAN_PERFECT if game.flawless and left[0] == 1 else 1.0
			colony.analyze(s, by, ceili(float(hands.count) / left[0]), bonus)
			left[0] -= 1)
		game.finished.connect(func() -> void:
			playlog.write("minigame_done", {"station": s.title})
			panel.close())
	else:
		game.finished.connect(func() -> void:
			playlog.write("minigame_done", {"station": s.title})
			if colony.blocked_reason(s, by) == "":
				colony.finish(s, by, Colony.PERFECT if game.flawless and game.heat else 1.0)
			panel.close())
	_open(s.title, game)


func _open(title: String, content: Control) -> void:
	_clear_content()
	_open_ms = Time.get_ticks_msec()
	_open_title = title
	playlog.write("panel_open", {"title": title})
	panel.open(null, title)
	var window := panel.get_node("Window") as Control
	content.position = Vector2(12, 26)
	content.scale = Vector2(0.5, 0.5)
	content.size = (window.size - Vector2(24, 34)) * 2.0
	window.add_child(content)
	_content = content


func _clear_content() -> void:
	if is_instance_valid(_content):
		if _content is Minigame and not _content._done:
			playlog.write("minigame_cancel", {"title": _open_title, "progress": _content._progress})
		playlog.write("panel_close", {"title": _open_title, "open_s": (Time.get_ticks_msec() - _open_ms) / 1000.0})
		_content.queue_free()
	_content = null
	if not _pending_offer.is_empty():
		var o := _pending_offer
		_pending_offer = []
		_on_offer.call_deferred(o[0], o[1])


func _on_won() -> void:
	var cover := ColorRect.new()
	cover.color = Color(0.03, 0.04, 0.08, 0.92)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var l := Label.new()
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 32)
	l.text = ("SHACKLETON BASE IS ALIVE!\n\n%d crew live on the Moon, %d:%02d after you woke up alone.\n\n"
		+ "Ice became water and air, sunlight and a tiny reactor kept the lights on, potatoes kept everyone fed, and moon rocks taught you how.") % [
		Colony.WIN_CREW, int(colony.time) / 60, int(colony.time) % 60]
	l.text += "\n\n\nYou can keep going: the base has room for %d crew." % Colony.MAX_CREW
	cover.add_child(l)
	var more := Button.new()
	more.text = "KEEP GOING"
	more.add_theme_font_size_override("font_size", 30)
	for st in [["normal", "card"], ["focus", "card"], ["hover", "card_hover"], ["pressed", "card_hover"]]:
		more.add_theme_stylebox_override(st[0], hud.nine(st[1], 16))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		more.add_theme_color_override(c, Color("0d0d12"))
	more.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	more.offset_left = -160
	more.offset_right = 160
	more.offset_top = -200
	more.offset_bottom = -120
	more.pressed.connect(func() -> void:
		playlog.write("keep_going", {})
		cover.queue_free()
		get_tree().paused = false)
	cover.add_child(more)
	cover.process_mode = Node.PROCESS_MODE_ALWAYS
	$HUD.add_child(cover)
	get_tree().paused = true
