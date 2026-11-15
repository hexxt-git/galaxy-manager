extends CharacterBody2D

## Shared look of the player and bots: recoloured character sprite with a hopping walk.

const StationMap := preload("res://scripts/map/station_map.gd")
const ROOM_LIGHT := preload("res://assets/shaders/room_light.gdshader")

const SPEED := 390.0
# Bounce walk: each step is a hop that leans to alternating sides.
const STEPS_PER_SEC := 5.6
const HOP := 6.0
const LEAN := 0.08
const SWAY := 1.4
const SETTLE_SPEED := 14.0
const LIGHT_FADE := 4.0  # per second, when walking between rooms of different light
const SHADOW_TEX := preload("res://assets/art/character/shadow.png")
const GROUND_ALPHA := 56.0 / 255.0  # opacity every ground shadow is exported with
# Art px, drawn at the map's SCALE.
const SHADOW_SHIFT := Vector2(0, -1)
const SHADOW_BACKPACK := 4.0  # shift toward the backpack side, which carries more of the body's weight
const SHADOW_Z := -7  # on the floor: under walls, side-wall tops and the sight overlay
# name -> [body, shadow]
const COLOURS := {
	"red": [Color("c51111"), Color("900b2c")],
	"blue": [Color("132ed1"), Color("0c1ca2")],
	"green": [Color("117f2d"), Color("0c5c2e")],
	"pink": [Color("ed54ba"), Color("bf37b1")],
	"orange": [Color("ef7d0d"), Color("c55113")],
	"yellow": [Color("f5f557"), Color("d2a933")],
	"black": [Color("3f474e"), Color("282b32")],
	"white": [Color("d6e0f0"), Color("9cabce")],
	"purple": [Color("6b2fbb"), Color("491e8f")],
	"cyan": [Color("38fedc"), Color("2ac2c7")],
}

@export_enum("red", "blue", "green", "pink", "orange", "yellow", "black", "white", "purple", "cyan")
var colour := "red":
	set(value):
		colour = value
		if is_node_ready():
			_apply_colour()

@onready var sprite: Sprite2D = $Sprite

var speed_scale := 1.0

var _step := 0.0
var _light := Vector2(-1, -1)  # room light, ground shadow opacity
var _shadow: Sprite2D
var _shadow_mat: ShaderMaterial
var _map: StationMap


func _ready() -> void:
	_apply_colour()
	_shadow = _make_shadow()
	add_child(_shadow)
	_place_shadow()


# A sibling of the sprite, so it stays on the ground while the sprite hops.
func _make_shadow() -> Sprite2D:
	var s := Sprite2D.new()
	s.name = "Shadow"
	s.texture = SHADOW_TEX
	s.scale = Vector2(StationMap.SCALE, StationMap.SCALE)
	s.z_index = SHADOW_Z
	s.z_as_relative = false
	_shadow_mat = ShaderMaterial.new()
	_shadow_mat.shader = ROOM_LIGHT
	s.material = _shadow_mat
	return s


# The unflipped sprite faces right, backpack on the left.
func _place_shadow() -> void:
	var back := SHADOW_BACKPACK if sprite.flip_h else -SHADOW_BACKPACK
	_shadow.position = (SHADOW_SHIFT + Vector2(back, 0)) * StationMap.SCALE
	_shadow.flip_h = sprite.flip_h


func _process(delta: float) -> void:
	if not is_instance_valid(_map):
		_map = get_tree().get_first_node_in_group("station_map") as StationMap
	var room: Dictionary = _map.room_at(global_position) if _map else {}
	var target := Vector2(room.get("light", 1.0), room.get("shadow", GROUND_ALPHA))
	_light = target if _light.x < 0.0 else _light.move_toward(target, LIGHT_FADE * delta)
	(sprite.material as ShaderMaterial).set_shader_parameter("light", _light.x)
	_shadow_mat.set_shader_parameter("light", _light.x)
	_shadow_mat.set_shader_parameter("shadow", _light.y)


func _apply_colour() -> void:
	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("body_color", COLOURS[colour][0])
	mat.set_shader_parameter("shadow_color", COLOURS[colour][1])


func _animate(dir: Vector2, delta: float) -> void:
	if dir.x != 0.0:
		sprite.flip_h = dir.x < 0.0
		_place_shadow()
	if dir == Vector2.ZERO:
		_step = 0.0
		var k := minf(1.0, SETTLE_SPEED * delta)
		sprite.rotation = lerpf(sprite.rotation, 0.0, k)
		sprite.position = sprite.position.lerp(Vector2.ZERO, k)
		return
	_step += delta * STEPS_PER_SEC * maxf(dir.length(), 0.5)
	var t := fmod(_step, 1.0)
	var side := 1.0 if int(_step) % 2 == 0 else -1.0
	var arc := sin(PI * t)
	sprite.position = Vector2(side * SWAY * arc, -HOP * arc)
	sprite.rotation = side * LEAN * arc
