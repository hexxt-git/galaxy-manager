class_name Station
extends Node2D

## A placeholder machine or sign on the colony grid. The origin is the bottom-centre of its footprint.
## What using it does lives in Colony; this node only draws, blocks and forwards interactions.

signal used(station: Station, by: Node)

# letter -> [kind, title, colour, blocks movement, usable]
const KINDS := {
	"S": ["solar", "Solar panel", Color("3d5a9e"), true, true],
	"D": ["drill", "Ice drill", Color("6a8fb0"), true, true],
	"G": ["bed", "Potato bed", Color("5f9c4a"), true, true],
	"W": ["melter", "Ice melter", Color("4aa3c9"), true, true],
	"L": ["lab", "Lab", Color("8a6cc9"), true, true],
	"N": ["reactor", "Reactor", Color("6b7a52"), true, true],
	"R": ["outcrop", "Rock outcrop", Color("7d7468"), true, true],
	"O": ["oven", "ISRU oven", Color("c9743f"), true, true],
	"E": ["electrolyzer", "Electrolyzer", Color("6fc7e0"), true, true],
	"Q": ["comms", "Comms dish", Color("5fb3a8"), true, true],
	"note": ["note", "Note", Color("f2e6a0"), false, true],
	"c": ["kitchen", "Kitchen", Color("d0a07f"), true, true],
	"b": ["decor", "Bunk", Color("8f9fb8"), true, false],
	"t": ["decor", "Table", Color("b0a080"), true, false],
	"x": ["decor", "Crate", Color("8a7d5c"), true, false],
	"h": ["decor", "Planter", Color("b07cc6"), true, false],
	"p": ["decor", "Plant", Color("5fbf45"), true, false],
	"y": ["decor", "Specimen tank", Color("8fcf63"), true, false],
	"f": ["decor", "Shelf", Color("a9bcc4"), true, false],
	"j": ["decor", "Pipes", Color("8a909c"), true, false],
	"v": ["decor", "Canister", Color("a9bcc4"), true, false],
	"m": ["decor", "Locker", Color("bcd0cd"), true, false],
	"a": ["decor", "Cargo cart", Color("4a92c9"), true, false],
	"w": ["decor", "Rover", Color("4a92c9"), true, false],
	"d": ["decor", "Supply drop", Color("a9bcc4"), true, false],
}
# letter -> [sprite in assets/art/props, its origin in art px]
const ART := {
	"G": ["potato_bed", Vector2(48, 72)], "L": ["lab_bench", Vector2(48, 104)],
	"c": ["kitchen", Vector2(72, 90)], "b": ["bunk", Vector2(48, 72)], "t": ["mess_table", Vector2(48, 58)],
	"note": ["info_sign", Vector2(24, 55)],
	"x": ["crate", Vector2(33, 58)], "h": ["hydro_planter", Vector2(50, 48)], "p": ["plant", Vector2(24, 49)],
	"y": ["specimen_tank", Vector2(27, 73)], "f": ["shelf", Vector2(33, 83)], "j": ["pipe_junction", Vector2(51, 88)],
	"v": ["canister", Vector2(20, 51)], "m": ["locker", Vector2(30, 86)],
	"a": ["cargo_cart", Vector2(36, 70)], "w": ["rover", Vector2(48, 86)], "d": ["supply_drop", Vector2(24, 66)],
	"S": ["solar_panel", Vector2(72, 103)], "D": ["ice_drill", Vector2(48, 103)], "R": ["rock_outcrop", Vector2(50, 66)],
	"W": ["ice_melter", Vector2(72, 108)], "E": ["electrolyzer", Vector2(48, 97)],
	"O": ["isru_oven", Vector2(48, 87)], "N": ["fission_reactor", Vector2(48, 83)], "Q": ["comms_dish", Vector2(48, 101)],
}
const INK := Color("0d0d12")
const REACH := 56.0

var kind := ""
var art: Texture2D
var art_origin := Vector2.ZERO
var _dust_spots := PackedVector2Array()
var _label := Node2D.new()  # solar cell pixels in a fixed random order; dust fills them front to back
var title := ""
var colour := Color.WHITE
var size := Vector2(64, 64)
var state := {}
var status := ""
var interact := Interactable.new()


func setup(letter: String, footprint: Vector2) -> Station:
	var k: Array = KINDS[letter]
	kind = k[0]
	title = k[1]
	colour = k[2]
	size = footprint
	if letter not in ["note"] and KINDS[letter][0] != "decor":
		_label.z_index = 45
		_label.z_as_relative = false
		_label.draw.connect(_draw_label)
		add_child(_label)
	if ART.has(letter):
		art = ColonyMap.texture(ColonyMap.PROPS + ART[letter][0] + ".png")
		art_origin = ART[letter][1] + Vector2(0, 3)
	if k[3]:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = size - Vector2(12, 16)
		shape.shape = rect
		shape.position = Vector2(0, -size.y * 0.5 - 4)
		body.add_child(shape)
		add_child(body)
	if not k[4]:
		interact.free()
		interact = null
		return self
	interact.collision_layer = 4
	interact.collision_mask = 0
	var area := CollisionShape2D.new()
	var reach := RectangleShape2D.new()
	reach.size = size + Vector2(REACH, REACH) * 2.0
	area.shape = reach
	area.position = Vector2(0, -size.y * 0.5)
	interact.add_child(area)
	add_child(interact)
	interact.interacted.connect(func(by: Node) -> void: used.emit(self, by))
	return self


## Where crew stand to use it.
func front() -> Vector2:
	return global_position + Vector2(0, 30)


func set_status(text: String, prompt: String) -> void:
	interact.prompt = prompt
	if text != status:
		status = text
		queue_redraw()
		_label.queue_redraw()


func _draw() -> void:
	if art:
		_draw_art()
		return
	var r := Rect2(Vector2(-size.x * 0.5, -size.y) + Vector2(4, 4), size - Vector2(8, 8))
	draw_rect(r, colour)
	draw_rect(r, INK, false, 4.0)
	var font := ColonyMap.FONT
	var fs := 16 if kind == "note" else 18
	var text := "i" if kind == "note" else title
	var recipe: String = Colony.RECIPES.get(kind, "")
	var y := r.get_center().y - (10.0 if recipe != "" else 0.0)
	draw_string(font, Vector2(r.position.x, y), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, INK)
	if recipe != "":
		y += 20.0
		draw_string(font, Vector2(r.position.x, y), recipe, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 14, Color(0, 0, 0, 0.7))
	if status != "":
		draw_string(font, Vector2(r.position.x, y + 20.0), status, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 14, INK)


const DUST := [Color("a9a49a"), Color("a19c92")]
const DUST_PATCHES := 4
const DUST_RAGGED := 9.0  # art px of randomness in how far a patch has spread


func _dust_spots_for(img: Image) -> PackedVector2Array:
	var spots := PackedVector2Array()
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.9 and c.b > c.r + 0.15 and c.b > 0.3:
				spots.append(Vector2(x, y))
	if spots.is_empty():
		return spots
	# dust gathers outward from a few patches: each spot is ranked by its distance to the nearest patch centre
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var centres := []
	for i in DUST_PATCHES:
		centres.append(spots[rng.randi() % spots.size()])
	var ranked := []
	for p in spots:
		var d := INF
		for c in centres:
			d = minf(d, p.distance_to(c))
		ranked.append([d + rng.randf() * DUST_RAGGED, p])
	ranked.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return PackedVector2Array(ranked.map(func(r: Array) -> Vector2: return r[1]))


func _draw_art() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(ColonyMap.PX, ColonyMap.PX))
	draw_texture(art, -art_origin)
	if kind == "solar" and state.has("dust"):
		if _dust_spots.is_empty():
			_dust_spots = _dust_spots_for(art.get_image())
		var n := int(_dust_spots.size() * 0.85 * state.dust)
		for i in n:
			draw_rect(Rect2(_dust_spots[i] - art_origin, Vector2.ONE), DUST[i % 2])
	draw_set_transform(Vector2.ZERO)


## Name, recipe and status above the sprite, on their own layer so nothing standing in front hides them. They fade
## in as the player comes near, so the map isn't covered in text.
const LABEL_NEAR := 300.0
const LABEL_FAR := 560.0
var _player: Node2D


func _process(_delta: float) -> void:
	if not _label.is_inside_tree():
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var d := _player.global_position.distance_to(global_position - Vector2(0, size.y * 0.5))
	_label.modulate.a = clampf((LABEL_FAR - d) / (LABEL_FAR - LABEL_NEAR), 0.0, 1.0)
	_label.visible = _label.modulate.a > 0.0

func _draw_label() -> void:
	var font := ColonyMap.FONT
	var w := 520.0
	var lines := [[title, 26, Color.WHITE]]
	var recipe: String = Colony.RECIPES.get(kind, "")
	if recipe != "":
		lines.append([recipe, 20, Color("cfe6ee")])
	if status != "":
		lines.append([status, 22, Color("f2c230")])
	var height := 0.0
	for l in lines:
		height += l[1] + 2.0
	var top := -(art_origin.y * ColonyMap.PX if art else size.y)
	var y := top - height - 30.0  # leaves room for the guide's BRING HERE tag
	for l in lines:
		_label.draw_string_outline(font, Vector2(-w * 0.5, y), l[0], HORIZONTAL_ALIGNMENT_CENTER, w, l[1], 9, INK)
		_label.draw_string(font, Vector2(-w * 0.5, y), l[0], HORIZONTAL_ALIGNMENT_CENTER, w, l[1], l[2])
		y += l[1] + 2.0
