extends Control

## Title screen: Tutorial or Play, and Quit where the platform has one.

const BUTTON := preload("res://scripts/ui/menu_button.gd")
const HUD := preload("res://scripts/colony/hud.gd")
const COLONY := "res://scenes/colony.tscn"
const SKY := Color("1d2846")
const RAY := Color("23315a")
const RAYS := 18
const STARS := 60
const K := 2  # screen px per art px, as in the HUD
const TITLE_K := 2
const HORIZON := 0.6  # of the height, pushed lower when the title and buttons need the room
const COL_TOP := 40
const COL_GAP := 24  # between the buttons and the hill tops

## [kind, name, x art px from the centre, depth 0 (horizon) .. 1 (bottom edge)]. Portrait sees only the middle
## ~180 art px each side; keep tall props near the centre low on the ground so they stay clear of the buttons.
const SCENE := [
	["decal", "regolith_crater_big", -60, 0.3],
	["decal", "regolith_crater_small", 100, 0.12],
	["decal", "regolith_crater_small", -150, 0.88],
	["decal", "regolith_pebbles", 40, 0.55],
	["decal", "regolith_boot_prints", -10, 0.82],
	["decal", "regolith_tyre_tracks", -150, 0.55],
	["decal", "regolith_pebbles", -260, 0.4],
	["decal", "regolith_crater_big", 270, 0.75],
	["decal", "regolith_crater_small", 330, 0.2],
	["prop", "boulder_e", -30, 0.1],
	["prop", "boulder_h", 380, 0.08],
	["prop", "solar_panel", -330, 0.15],
	["prop", "comms_dish", -150, 0.22],
	["prop", "ice_drill", 330, 0.3],
	["prop", "menu_rocket", 120, 0.36],
	["prop", "supply_drop", 230, 0.42],
	["prop", "solar_panel", -290, 0.55],
	["prop", "canister", -185, 0.62],
	["crew", "red", -20, 0.6],
	["prop", "boulder_f", 60, 0.58],
	["prop", "cargo_cart", 265, 0.65],
	["prop", "rover", -95, 0.75],
	["prop", "crate", 168, 0.78],
	["prop", "flag", 25, 0.8],
	["prop", "boulder_b", -390, 0.9],
	["crew", "cyan", 75, 0.95],
	["crew", "yellow", 150, 0.98],
	["prop", "dish_antenna", 360, 0.95],
	["crew", "orange", -240, 0.97],
	["prop", "boulder_e", -150, 1.0],
]

var _stars: Array = []  # [position 0..1 of the sky, size]
var _horizon := 0.0
var _ground: TextureRect
var _ridge: TextureRect
var _col: VBoxContainer
var _title: TextureRect
var _items: Array = []  # [TextureRect, entry]
var _rays: ImageTexture
var _rays_key := Rect2()  # title centre and screen size the rays were drawn for


static func button(text: String, primary := false) -> Button:
	return BUTTON.new(text, primary)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in STARS:
		_stars.append([Vector2(rng.randf(), rng.randf() * 0.85), 2.0 if rng.randf() < 0.8 else 4.0])

	_sky("menu_earth.png", Vector2(0.2, 0.09))
	_sky("menu_planet.png", Vector2(0.84, 0.05))
	_ridge = TextureRect.new()
	_ridge.texture = scaled(ColonyMap.texture(ColonyMap.PROPS + "menu_ridge.png"), K)
	_ridge.stretch_mode = TextureRect.STRETCH_TILE
	_ridge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_ridge)
	_ground = TextureRect.new()
	_ground.texture = ColonyMap.texture(ColonyMap.ART + "regolith.png")
	_ground.stretch_mode = TextureRect.STRETCH_TILE
	_ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_ground)
	var entries := SCENE.duplicate()
	var order := func(e: Array) -> float: return e[3] - (2.0 if e[0] == "decal" else 0.0)
	entries.sort_custom(func(a, b): return order.call(a) < order.call(b))
	for e in entries:
		var t := TextureRect.new()
		match e[0]:
			"decal": t.texture = scaled(ColonyMap.texture(ColonyMap.ART + "decals/" + e[1] + ".png"), K)
			"prop": t.texture = scaled(ColonyMap.texture(ColonyMap.PROPS + e[1] + ".png"), K)
			"crew": t.texture = HUD.portrait(e[1], false, K)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(t)
		_items.append([t, e])

	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 0)
	add_child(_col)
	_col.add_child(_spacer(1.0))
	_title = TextureRect.new()
	_title.texture = scaled(ColonyMap.texture(ColonyMap.PROPS + "menu_title.png"), TITLE_K)
	_title.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_title.item_rect_changed.connect(queue_redraw)
	_col.add_child(_title)
	var gap := _spacer(1.4)
	gap.custom_minimum_size.y = 40
	_col.add_child(gap)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	_col.add_child(buttons)
	var tutorial := button("TUTORIAL", true)
	tutorial.pressed.connect(_start.bind(true))
	buttons.add_child(tutorial)
	var play := button("PLAY")
	play.pressed.connect(_start.bind(false))
	buttons.add_child(play)
	if OS.get_name() not in ["Android", "iOS", "Web"]:
		var quit := button("QUIT")
		quit.pressed.connect(get_tree().quit)
		buttons.add_child(quit)
	_col.add_child(_spacer(0.4))
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var w := size.x
	var h := size.y
	var ridge_h := _ridge.texture.get_height()
	_horizon = maxf(h * HORIZON, COL_TOP + _col.get_combined_minimum_size().y + COL_GAP + ridge_h * 0.6)
	_horizon = minf(_horizon, h - 120)
	_col.position = Vector2(0, COL_TOP)
	_col.size = Vector2(w, _horizon - ridge_h * 0.6 - COL_GAP - COL_TOP)
	_ridge.position = Vector2(0, _horizon - ridge_h + 2 * K)
	_ridge.size = Vector2(w, ridge_h)
	_ground.position = Vector2(0, _horizon)
	_ground.size = Vector2(w, h - _horizon)
	for item in _items:
		var t: TextureRect = item[0]
		var e: Array = item[1]
		var ts := t.texture.get_size()
		var at := Vector2(w * 0.5 + e[2] * K, _horizon + 6 * K + e[3] * (h - _horizon - 12 * K))
		if e[0] == "decal":
			t.position = (at - ts * 0.5).floor()
		else:
			t.position = (at - Vector2(ts.x * 0.5, ts.y - 3 * K)).floor()
		t.size = ts
	queue_redraw()


static func scaled(tex: Texture2D, k: int) -> Texture2D:
	var img := tex.get_image()
	img.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


## Sky art centred at `at` (0..1 of the screen).
func _sky(file: String, at: Vector2) -> void:
	var tex := scaled(ColonyMap.texture(ColonyMap.PROPS + file), K)
	var t := TextureRect.new()
	t.texture = tex
	t.anchor_left = at.x
	t.anchor_right = at.x
	t.anchor_top = at.y
	t.anchor_bottom = at.y
	t.offset_left = -tex.get_width() * 0.5
	t.offset_right = tex.get_width() * 0.5
	t.offset_top = -tex.get_height() * 0.5
	t.offset_bottom = tex.get_height() * 0.5
	add_child(t)


func _spacer(weight: float) -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.size_flags_stretch_ratio = weight
	return c


func _start(tutorial: bool) -> void:
	Colony.start_tutorial = tutorial
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(black)  # also swallows further clicks
	var tw := create_tween()
	tw.tween_property(black, "color:a", 1.0, 0.3)
	tw.tween_callback(get_tree().change_scene_to_file.bind(COLONY))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), SKY)
	var rays := _ray_texture(_title.get_global_rect().get_center() - global_position)
	draw_texture_rect(rays, Rect2(Vector2.ZERO, rays.get_size() * K), false)
	for s in _stars:
		var p: Vector2 = s[0] * Vector2(size.x, _horizon)
		draw_rect(Rect2((p / K).floor() * K, Vector2(s[1], s[1])), Color(1, 1, 1, 0.55))


## Sun rays fanning out from the title, drawn at art resolution so they step in K-px pixels like the sprites.
func _ray_texture(c: Vector2) -> Texture2D:
	var key := Rect2(c, Vector2(size.x, _horizon))
	if _rays and key == _rays_key:
		return _rays
	_rays_key = key
	var w := maxi(1, ceili(size.x / K))
	var h := maxi(1, ceili(_horizon / K))
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(SKY)
	var ac := c / K
	var wedge := TAU / RAYS
	for y in h:
		for x in w:
			if fposmod(atan2(y + 0.5 - ac.y, x + 0.5 - ac.x), wedge) < wedge * 0.5:
				img.set_pixel(x, y, RAY)
	_rays = ImageTexture.create_from_image(img)
	return _rays

