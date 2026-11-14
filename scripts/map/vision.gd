extends Node2D

## Line-of-sight dimming: everything the viewer can't see through the map's walls is dimmed.
## Shadows are rasterised at 1/PIXEL resolution into SubViewports and shown with nearest filtering,
## aligned to a world grid so their stair-steps stay put while the camera moves.
## When the viewer crosses a wall, the walls' blocking edges change; the old shadow dithers out, then the new one in.
## The overlay only covers the floor, decals and vent. Standing things (props, wall faces) are dimmed whole, by
## whether the spot they stand on is visible, so a tall prop behind a wall isn't half lit. Bots fade out entirely. Side-wall tops are dimmed
## whole too, by whether any floor along their near side is visible, so the wall's own jambs can't shade them.

const PIXEL := 4
const FAR := 8000.0
const EYE := Vector2(0, -12)  # sight originates at the player's feet
const TRANSITION := 0.8
const DIM := Color(0.7, 0.7, 0.74)  # matches the shader's dim
const OVERLAY_Z := -6  # above floors, decals and the vent; below side-wall tops (-5) and everything y-sorted
const STRIP_Z := -5
const STRIP_SAMPLES := 12

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
var _standing := []  # [node, anchor in world px, wall floor line or NAN, dim amount 0..1]
var _strips := []  # [sprite, world rect, dim amount 0..1]


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
	_overlay.z_index = OVERLAY_Z
	_overlay.z_as_relative = false
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
	_dim_standing(delta)


func _collect_standing() -> void:
	for c in map.get_children():
		if c is Sprite2D and c.z_index == STRIP_Z:
			var r: Rect2 = c.get_rect()
			_strips.append([c, Rect2(c.position + r.position * c.scale, r.size * c.scale), 0.0])
			continue
		if not c is CanvasItem or c is CollisionObject2D or c.z_index not in [0, -1]:
			continue
		var line := NAN
		var anchor: Vector2 = c.position
		if c is Sprite2D and c.texture and c.texture.resource_path.get_file().begins_with("wall_"):
			line = c.position.y
			anchor.x = c.position.x + (c.get_rect().get_center() * c.scale).x
		_standing.append([c, anchor, line, 0.0])


func _dim_standing(delta: float) -> void:
	if _standing.is_empty():
		_collect_standing()
	var segs: Array = map.sight_segments(_eye, _eye)
	var half_wall: float = map.WALL_ORIGIN_Y * map.SCALE / 2.0
	var step := delta / (TRANSITION / 2.0)
	for item in _standing:
		var node: CanvasItem = item[0]
		if not is_instance_valid(node):
			continue
		var hidden: bool
		if is_nan(item[2]):
			hidden = not _sees(item[1] + Vector2(0, -4), segs)
		else:
			# a wall's face points south: from its north side you only ever see the far room's face
			hidden = _eye.y < item[2] - half_wall or not _sees(Vector2(item[1].x, item[2] + 4), segs)
		item[3] = move_toward(item[3], 1.0 if hidden else 0.0, step)
		node.modulate = Color.WHITE.lerp(DIM, item[3])
	for item in _strips:
		var r: Rect2 = item[1]
		var x := r.position.x - 4.0 if _eye.x < r.get_center().x else r.end.x + 4.0
		var seen := false
		for k in STRIP_SAMPLES:
			if _sees(Vector2(x, lerpf(r.position.y, r.end.y, (k + 0.5) / STRIP_SAMPLES)), segs):
				seen = true
				break
		item[2] = move_toward(item[2], 0.0 if seen else 1.0, step)
		item[0].modulate = Color.WHITE.lerp(DIM, item[2])
	for bot in get_tree().get_nodes_in_group("bots"):
		var amount: float = move_toward(bot.get_meta("dim", 0.0), 0.0 if _sees(bot.global_position + EYE, segs) else 1.0, step)
		bot.set_meta("dim", amount)
		bot.modulate.a = 1.0 - amount


func _sees(p: Vector2, segs: Array) -> bool:
	for seg in segs:
		if Geometry2D.segment_intersects_segment(_eye, p, seg[0], seg[1]) != null:
			return false
	return true


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
