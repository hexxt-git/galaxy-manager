extends CharacterBody2D

## Shared look of the player and bots: recoloured character sprite with a hopping walk.

const SPEED := 390.0
# Bounce walk: each step is a hop that leans to alternating sides.
const STEPS_PER_SEC := 5.6
const HOP := 6.0
const LEAN := 0.08
const SWAY := 1.4
const SETTLE_SPEED := 14.0
const LIGHT_FADE := 4.0  # per second, when walking between rooms of different light
# Ground shadow, matching the props' baked ones (GROUND_RGBA in art-src/props/prop.js). Art px at the map's scale.
const SHADOW_RADII := Vector2(19, 5)
const SHADOW_SHIFT := Vector2(0, -1)
const SHADOW_BACKPACK := 4.0  # shift toward the backpack side, which carries more of the body's weight
const SHADOW_COLOR := Color8(24, 24, 40, 56)
const SHADOW_WOBBLE := 0.12  # outline wander, as a fraction of the radius
const SHADOW_SCALE := 2.0  # station_map.gd SCALE
const SHADOW_Z := -7  # on the floor: under walls, side-wall tops and the sight overlay
# name -> [body, shadow]
const COLOURS := {
	"red": [Color("c51111"), Color("7a0838")],
	"blue": [Color("132ed1"), Color("09158e")],
	"green": [Color("117f2d"), Color("0a4d2e")],
	"pink": [Color("ed54ba"), Color("ab2bad")],
	"orange": [Color("ef7d0d"), Color("b33e15")],
	"yellow": [Color("f5f557"), Color("c38823")],
	"black": [Color("3f474e"), Color("1e1f26")],
	"white": [Color("d6e0f0"), Color("8394bf")],
	"purple": [Color("6b2fbb"), Color("3b177c")],
	"cyan": [Color("38fedc"), Color("24a8be")],
}

@export_enum("red", "blue", "green", "pink", "orange", "yellow", "black", "white", "purple", "cyan")
var colour := "red":
	set(value):
		colour = value
		if is_node_ready():
			_apply_colour()

@onready var sprite: Sprite2D = $Sprite

var _step := 0.0
var _light := Vector2(-1, -1)  # room light, ground shadow opacity
var _shadow: Sprite2D

static var _shadow_tex: Texture2D


func _ready() -> void:
	_apply_colour()
	_shadow = _make_shadow()
	add_child(_shadow)
	_place_shadow()


# A sibling of the sprite, so it stays on the ground while the sprite hops.
func _make_shadow() -> Sprite2D:
	if not _shadow_tex:
		var half := (SHADOW_RADII * (1.0 + SHADOW_WOBBLE)).ceil()
		var size := Vector2i(half * 2.0)
		var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
		for y in size.y:
			for x in size.x:
				var p := (Vector2(x, y) + Vector2(0.5, 0.5) - half) / SHADOW_RADII
				var a := p.angle()
				var r := 1.0 + SHADOW_WOBBLE * (0.6 * sin(3.0 * a + 1.3) + 0.4 * sin(5.0 * a + 4.1))
				if p.length() <= r:
					img.set_pixel(x, y, SHADOW_COLOR)
		_shadow_tex = ImageTexture.create_from_image(img)
	var s := Sprite2D.new()
	s.name = "Shadow"
	s.texture = _shadow_tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(SHADOW_SCALE, SHADOW_SCALE)
	s.z_index = SHADOW_Z
	s.z_as_relative = false
	s.material = ShaderMaterial.new()
	s.material.shader = preload("res://assets/shaders/room_light.gdshader")
	return s


# The unflipped sprite faces right, backpack on the left.
func _place_shadow() -> void:
	var back := SHADOW_BACKPACK if sprite.flip_h else -SHADOW_BACKPACK
	_shadow.position = (SHADOW_SHIFT + Vector2(back, 0)) * SHADOW_SCALE
	_shadow.flip_h = sprite.flip_h


func _process(delta: float) -> void:
	var map := get_tree().get_first_node_in_group("station_map")
	var room: Dictionary = map.room_at(global_position) if map else {}
	var target := Vector2(room.get("light", 1.0), room.get("shadow", SHADOW_COLOR.a))
	_light = target if _light.x < 0.0 else _light.move_toward(target, LIGHT_FADE * delta)
	(sprite.material as ShaderMaterial).set_shader_parameter("light", _light.x)
	_shadow.material.set_shader_parameter("light", _light.x)
	_shadow.material.set_shader_parameter("shadow", _light.y)


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
