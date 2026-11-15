class_name Joystick
extends Control

## Floating touch joystick: appears where the finger lands, follows the drag, hides on release.

const RADIUS := 110.0
const KNOB_RADIUS := 48.0
const DEAD_ZONE := 0.15
const ART_SCALE := 3.0
const BASE := preload("res://assets/art/ui/joy_base.png")
const KNOB := preload("res://assets/art/ui/joy_knob.png")

var vector := Vector2.ZERO

var _touch := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch == -1 and not _over_blocking_ui(event.position):
			_touch = event.index
			_origin = event.position
			_set_knob(event.position)
		elif not event.pressed and event.index == _touch:
			_touch = -1
			vector = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch:
		_set_knob(event.position)


# Emulated touches from the mouse reach _input even when a button consumed the click,
# so buttons and open panels opt out via the "blocks_joystick" group.
func _over_blocking_ui(pos: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group("blocks_joystick"):
		var c := node as Control
		# the transform includes the control's scale, which get_global_rect() leaves out
		if c and c.is_visible_in_tree() and (c.get_global_transform() * Rect2(Vector2.ZERO, c.size)).has_point(pos):
			return true
	return false


func _set_knob(pos: Vector2) -> void:
	var offset := (pos - _origin).limit_length(RADIUS)
	_knob = _origin + offset
	var v := offset / RADIUS
	vector = v if v.length() > DEAD_ZONE else Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	if _touch == -1:
		return
	# Touch events arrive in viewport coordinates; this control fills the viewport, so they map 1:1.
	draw_set_transform(_origin, 0.0, Vector2(ART_SCALE, ART_SCALE))
	draw_texture(BASE, -Vector2(32, 32))
	draw_set_transform(_knob, 0.0, Vector2(ART_SCALE, ART_SCALE))
	draw_texture(KNOB, -Vector2(14, 13))
	draw_set_transform(Vector2.ZERO)
