class_name Joystick
extends Control

## Floating touch joystick: appears where the finger lands, follows the drag, hides on release.

const RADIUS := 110.0
const KNOB_RADIUS := 48.0
const DEAD_ZONE := 0.15

var vector := Vector2.ZERO

var _touch := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
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
	draw_circle(_origin, RADIUS, Color(1, 1, 1, 0.18))
	draw_arc(_origin, RADIUS, 0, TAU, 64, Color(0.05, 0.05, 0.07, 0.6), 6.0)
	draw_circle(_knob, KNOB_RADIUS, Color(1, 1, 1, 0.55))
	draw_arc(_knob, KNOB_RADIUS, 0, TAU, 48, Color(0.05, 0.05, 0.07, 0.8), 6.0)
