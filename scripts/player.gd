extends "res://scripts/crewmate.gd"

@export var joystick: Joystick

@onready var detector: InteractionDetector = $InteractionDetector

var _busy := false


func _ready() -> void:
	add_to_group("player")
	super()


## While busy (a task panel is open) the player stands still and can't focus or use anything.
func set_busy(busy: bool) -> void:
	_busy = busy
	detector.locked = busy


func _unhandled_input(event: InputEvent) -> void:
	if not _busy and event.is_action_pressed("interact"):
		if detector.try_interact():
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if joystick and joystick.vector != Vector2.ZERO:
		dir = joystick.vector
	if _busy:
		dir = Vector2.ZERO
	velocity = dir * SPEED
	move_and_slide()
	_animate(dir, delta)
