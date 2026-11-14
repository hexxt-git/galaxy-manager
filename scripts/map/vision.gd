extends Node2D

## Line-of-sight dimming: everything the viewer can't see through the map's walls is dimmed.
## Shadows are rasterised at 1/PIXEL resolution into SubViewports and shown with nearest filtering,
## aligned to a world grid so their stair-steps stay put while the camera moves.
## When the viewer crosses a wall, the walls' blocking edges change; the old shadow dithers out, then the new one in.

const PIXEL := 4
const FAR := 8000.0
const EYE := Vector2(0, -12)  # sight originates at the player's feet
const TRANSITION := 0.8

@export var viewer: Node2D
@export var map: Node2D

var _old := _Mask.new()
var _new := _Mask.new()
var _overlay := Sprite2D.new()
var _mat := ShaderMaterial.new()
var _origin := Vector2.ZERO
var _eye := Vector2.ZERO
var _key: Variant = null
var _t := 1.0


class _Mask:
	var vp := SubViewport.new()
	var canvas := Node2D.new()
	var chooser := Vector2.ZERO  # eye position that decides which wall edges block


func _ready() -> void:
	for m in [_old, _new]:
		m.vp.disable_3d = true
		m.vp.transparent_bg = false
		m.vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		m.canvas.draw.connect(_draw_mask.bind(m))
		m.vp.add_child(m.canvas)
		add_child(m.vp)

	_mat.shader = preload("res://assets/shaders/sight_dither.gdshader")
	_mat.set_shader_parameter("mask_old", _old.vp.get_texture())
	_mat.set_shader_parameter("mask_new", _new.vp.get_texture())
	_overlay.material = _mat
	_overlay.texture = _new.vp.get_texture()
	_overlay.centered = false
	_overlay.scale = Vector2(PIXEL, PIXEL)
	add_child(_overlay)


func _process(delta: float) -> void:
	if not viewer or not map:
		return
	_eye = viewer.global_position + EYE
	var key: Variant = map.sight_key(_eye)
	if _key == null:
		_new.chooser = _eye
		_old.chooser = _eye
	elif key != _key:
		_old.chooser = _new.chooser
		_t = 0.0
	_key = key
	_new.chooser = _eye
	_t = minf(_t + delta / TRANSITION, 1.0)

	var view := get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()
	_origin = (view.position / PIXEL).floor() * PIXEL - Vector2(PIXEL, PIXEL)
	var size := Vector2i((view.size / PIXEL).ceil()) + Vector2i(3, 3)
	for m in [_old, _new]:
		m.vp.size = size
		m.canvas.queue_redraw()
	_overlay.position = _origin
	_mat.set_shader_parameter("t", _t)
	_mat.set_shader_parameter("grid_origin", _origin / PIXEL)


func _draw_mask(m: _Mask) -> void:
	m.canvas.draw_rect(Rect2(Vector2.ZERO, m.vp.size), Color.BLACK)
	for seg in map.sight_segments(_eye, m.chooser):
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		if absf((a - _eye).cross(b - _eye)) < 1.0:
			continue
		var quad := PackedVector2Array([
			a, b, b + (b - _eye).normalized() * FAR, a + (a - _eye).normalized() * FAR,
		])
		for i in quad.size():
			quad[i] = (quad[i] - _origin) / PIXEL
		m.canvas.draw_colored_polygon(quad, Color.RED)
