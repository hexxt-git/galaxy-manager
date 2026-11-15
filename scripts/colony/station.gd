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
	"P": ["pit", "Regolith pit", Color("9b8a6a"), true, true],
	"Z": ["shield", "Shield wall", Color("a08c5a"), true, true],
	"O": ["oven", "ISRU oven", Color("c9743f"), true, true],
	"E": ["electrolyzer", "Electrolyzer", Color("6fc7e0"), true, true],
	"Q": ["comms", "Comms dish", Color("5fb3a8"), true, true],
	"note": ["note", "Note", Color("f2e6a0"), false, true],
	"c": ["decor", "Kitchen", Color("d0a07f"), true, false],
	"b": ["decor", "Bunk", Color("8f9fb8"), true, false],
	"t": ["decor", "Table", Color("b0a080"), true, false],
	"x": ["decor", "Crate", Color("8a7d5c"), true, false],
}
const INK := Color("0d0d12")
const REACH := 56.0

var kind := ""
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


func _draw() -> void:
	var r := Rect2(Vector2(-size.x * 0.5, -size.y) + Vector2(4, 4), size - Vector2(8, 8))
	draw_rect(r, colour)
	draw_rect(r, INK, false, 4.0)
	var font := ThemeDB.fallback_font
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
