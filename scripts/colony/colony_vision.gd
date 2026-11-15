extends Node2D

## Line-of-sight dimming for the colony map: everything the viewer can't see through the walls is dimmed.
## Shadows are rasterised at 1/PIXEL resolution into SubViewports and shown with nearest filtering,
## aligned to a world grid so their stair-steps stay put while the camera moves.
## When the viewer crosses a wall, the walls' blocking edges change; the old shadow dithers out, then the new one in.
## The overlay only covers the ground. Standing things (stations, walls, rocks, dropped items) are dimmed whole, by
## whether the spot they stand on is visible, so a tall prop behind a wall isn't half lit. Crew fade out entirely.

const PIXEL := 4
const FAR := 8000.0
const EYE := Vector2(0, -12)  # sight originates at the player's feet
const TRANSITION := 0.8
const DIM := Color(0.7, 0.7, 0.74)
const OVERLAY_Z := -6  # above the ground, decals and AO; below everything y-sorted

@export var viewer: Node2D
@export var map: Node2D

var _old := _Mask.new()
var _new := _Mask.new()
var _masks: Array[_Mask] = [_old, _new]
var _overlay := Sprite2D.new()
var _mat := ShaderMaterial.new()
var _origin := Vector2.ZERO
var _eye := Vector2.ZERO
var _key: Variant = null
var _t := 1.0
var _half_wall := 0.0  # world px
var _collected := false
var _standing: Array = []  # [node, anchor in world px, wall floor line or NAN, dim amount 0..1]
var _lifted := false


class _Mask:
	var vp := SubViewport.new()
	var canvas := Node2D.new()
	var chooser := Vector2.ZERO  # eye position that decides which wall edges block
	var segs: Array = []  # map.sight_segments(chooser)


func _ready() -> void:
	for m in _masks:
		m.vp.disable_3d = true
		m.vp.transparent_bg = false
		m.vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		m.canvas.draw.connect(_draw_mask.bind(m))
		m.vp.add_child(m.canvas)
		add_child(m.vp)

	_mat.shader = preload("res://assets/shaders/sight_dither.gdshader")
	_mat.set_shader_parameter("mask_old", _old.vp.get_texture())
	_mat.set_shader_parameter("mask_new", _new.vp.get_texture())
	_mat.set_shader_parameter("dim", DIM)
	_overlay.material = _mat
	_overlay.texture = _new.vp.get_texture()
	_overlay.centered = false
	_overlay.scale = Vector2(PIXEL, PIXEL)
	_overlay.z_index = OVERLAY_Z
	_overlay.z_as_relative = false
	add_child(_overlay)


## Lifts every shadow (e.g. while the camera looks away from the viewer); off puts them back.
func lift(on: bool) -> void:
	_lifted = on
	_overlay.visible = not on
	if not on:
		return
	for item in _standing:
		if is_instance_valid(item[0]):
			item[0].modulate = Color.WHITE
	for n in get_tree().get_nodes_in_group("drops") + get_tree().get_nodes_in_group("bots"):
		n.modulate = Color.WHITE


func _process(delta: float) -> void:
	if not viewer or not map or _lifted:
		return
	_eye = viewer.global_position + EYE
	var key: Variant = map.sight_key(_eye)
	if _key == null:
		_old.chooser = _eye
	elif key != _key:
		_old.chooser = _new.chooser
		_old.segs = _new.segs
		_t = 0.0
	_key = key
	_new.chooser = _eye
	_t = minf(_t + delta / TRANSITION, 1.0)

	var view := get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()
	_origin = (view.position / PIXEL).floor() * PIXEL - Vector2(PIXEL, PIXEL)
	var size := Vector2i((view.size / PIXEL).ceil()) + Vector2i(3, 3)
	for m in _masks:
		m.vp.size = size
	_new.segs = map.sight_segments(_new.chooser)
	_new.canvas.queue_redraw()
	# the shader ignores the old mask once the transition is done
	if _t < 1.0:
		_old.canvas.queue_redraw()
	_overlay.position = _origin
	_mat.set_shader_parameter("t", _t)
	_mat.set_shader_parameter("grid_origin", _origin / PIXEL)
	_dim_standing(delta)


func _collect_standing() -> void:
	_collected = true
	_half_wall = map.WALL_FACE * map.PX / 2.0
	for c in map.get_parent().get_children():
		if not c is Node2D or c == viewer or c is CollisionObject2D or c.z_index != 0 or c.get_child_count() > 0 and c.name in ["Items", "Helpers"]:
			continue
		_standing.append([c, c.position, c.get_meta("wall_line", NAN), 0.0])


func _dim_standing(delta: float) -> void:
	if not _collected:
		_collect_standing()
	var segs := _new.segs
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
			hidden = _eye.y < item[2] - _half_wall or not _sees(Vector2(item[1].x + map.TILE * 0.5, item[2] + 4), segs)
		item[3] = move_toward(item[3], 1.0 if hidden else 0.0, step)
		node.modulate = Color.WHITE.lerp(DIM, item[3])
	for drop in get_tree().get_nodes_in_group("drops"):
		var amount: float = move_toward(drop.get_meta("dim", 0.0), 0.0 if _sees(drop.global_position + Vector2(0, -4), segs) else 1.0, step)
		drop.set_meta("dim", amount)
		drop.modulate = Color.WHITE.lerp(DIM, amount)
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
	for seg in m.segs:
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
