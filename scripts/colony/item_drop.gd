class_name ItemDrop
extends Node2D

## A stack of one item type lying on the ground. Tossed drops arc and bounce under lunar gravity,
## then hover, bob and spin. Resting drops of the same type merge into one stack.

const SHADOW := preload("res://assets/art/character/shadow.png")
const GRAVITY := 380.0
const BOUNCE := 0.5
const MIN_BOUNCE := 60.0
const AIR_DRAG := 0.4
const GROUND_FRICTION := 6.0
const MERGE_RADIUS := 48.0
const HOVER := 10.0
const WALLS := 1

var type := "ice"
var count := 1
var h := 0.0  # height above the ground, px
var vh := 0.0
var vel := Vector2.ZERO
var resting := true

var _t := randf() * TAU
var _area := Interactable.new()


static func spawn(parent: Node, at: Vector2, item: String, n: int) -> ItemDrop:
	var d := ItemDrop.new()
	d.type = item
	d.count = n
	d.position = at
	parent.add_child(d)
	return d


func _ready() -> void:
	add_to_group("drops")
	_area.collision_layer = 4
	_area.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 36.0
	shape.shape = circle
	shape.position = Vector2(0, -12)
	_area.add_child(shape)
	add_child(_area)
	_area.interacted.connect(_on_interacted)
	_refresh_prompt()


func toss(v: Vector2, up: float) -> void:
	vel = v
	vh = up
	h = maxf(h, 1.0)
	resting = false


func _on_interacted(by: Node) -> void:
	var hands := by.get_node_or_null("Hands") as Hands
	if hands:
		hands.pick(self)


func _refresh_prompt() -> void:
	_area.prompt = "Pick up " + Items.label(type, count)


func _physics_process(delta: float) -> void:
	_t += delta
	if not resting:
		_fly(delta)
	queue_redraw()


func _fly(delta: float) -> void:
	vh -= GRAVITY * delta
	h += vh * delta
	if h <= 0.0:
		h = 0.0
		if absf(vh) < MIN_BOUNCE:
			vh = 0.0
		else:
			vh = -vh * BOUNCE
			vel *= 0.7
	vel *= exp(-(AIR_DRAG if h > 0.0 else GROUND_FRICTION) * delta)
	var step := vel * delta
	if step != Vector2.ZERO:
		var q := PhysicsRayQueryParameters2D.create(global_position, global_position + step * 1.5, WALLS)
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		if hit:
			vel = vel.bounce(hit.normal) * 0.5
		else:
			position += step
	if h == 0.0 and vh == 0.0 and vel.length() < 8.0:
		resting = true
		vel = Vector2.ZERO
		_merge()


func _merge() -> void:
	for other in get_tree().get_nodes_in_group("drops"):
		if other != self and other.resting and other.type == type and not other.is_queued_for_deletion() \
				and other.global_position.distance_to(global_position) < MERGE_RADIUS:
			count += other.count
			other.queue_free()
	_refresh_prompt()


func _draw() -> void:
	var lift := h + (HOVER + sin(_t * 3.0) * 3.0 if resting else 6.0)
	var shadow := clampf(1.0 - h / 160.0, 0.4, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(ColonyMap.PX, ColonyMap.PX) * shadow)
	draw_texture(SHADOW, -SHADOW.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO)
	Items.draw_icon(self, Vector2(0, -lift - 17), type, count)
