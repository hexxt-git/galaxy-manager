extends CharacterBody2D

const SPEED := 390.0
# Bounce walk: each step is a hop that leans to alternating sides.
const STEPS_PER_SEC := 4.0
const HOP := 6.0
const LEAN := 0.08
const SWAY := 1.4
const SETTLE_SPEED := 14.0
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

@export var joystick: Joystick
@export_enum("red", "blue", "green", "pink", "orange", "yellow", "black", "white", "purple", "cyan")
var colour := "red":
	set(value):
		colour = value
		if is_node_ready():
			_apply_colour()

@onready var sprite: Sprite2D = $Sprite
@onready var detector: InteractionDetector = $InteractionDetector

var _step := 0.0
var _busy := false


func _ready() -> void:
	add_to_group("player")
	_apply_colour()


## While busy (a task panel is open) the player stands still and can't focus or use anything.
func set_busy(busy: bool) -> void:
	_busy = busy
	detector.locked = busy


func _unhandled_input(event: InputEvent) -> void:
	if not _busy and event.is_action_pressed("interact"):
		if detector.try_interact():
			get_viewport().set_input_as_handled()


func _apply_colour() -> void:
	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("body_color", COLOURS[colour][0])
	mat.set_shader_parameter("shadow_color", COLOURS[colour][1])


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if joystick and joystick.vector != Vector2.ZERO:
		dir = joystick.vector
	if _busy:
		dir = Vector2.ZERO
	velocity = dir * SPEED
	move_and_slide()
	_animate(dir, delta)


func _animate(dir: Vector2, delta: float) -> void:
	if dir.x != 0.0:
		sprite.flip_h = dir.x < 0.0
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
