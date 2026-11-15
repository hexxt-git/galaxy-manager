class_name Hands
extends Node2D

## One carry slot holding any number of a single item type, shown above the carrier's head.

signal changed

const HOLD_Y := -165.0
const TOSS_SPEED := 220.0
const TOSS_UP := 200.0

var caption := ""  # shown under the held item, e.g. where it goes
var type := ""
var count := 0
var _t := 0.0


func is_empty() -> bool:
	return count == 0


func holds(item: String) -> bool:
	return count > 0 and type == item


## Takes the whole stack. Holding a different type tosses that stack aside first.
func pick(drop: ItemDrop) -> void:
	if not is_instance_valid(drop) or drop.is_queued_for_deletion():
		return
	if not is_empty() and type != drop.type:
		toss(Vector2.from_angle(randf() * TAU))
	add(drop.type, drop.count)
	drop.queue_free()


func add(item: String, n: int) -> void:
	if n <= 0:
		return
	if not is_empty() and type != item:
		toss(Vector2.from_angle(randf() * TAU))
	type = item
	count += n
	_changed()


## Removes up to `n` (all when negative) and returns how many were removed.
func take(n := -1) -> int:
	var got := count if n < 0 else mini(n, count)
	count -= got
	_changed()
	return got


func toss(dir: Vector2) -> ItemDrop:
	if is_empty():
		return null
	var layer := get_tree().get_first_node_in_group("item_layer")
	var d := ItemDrop.spawn(layer, get_parent().global_position + dir * 24.0, type, count)
	d.h = 60.0
	d.toss(dir.normalized() * TOSS_SPEED, TOSS_UP)
	count = 0
	_changed()
	return d


func _changed() -> void:
	if count == 0:
		type = ""
	changed.emit()
	queue_redraw()


func _process(delta: float) -> void:
	if count > 0:
		_t += delta
		queue_redraw()


func _draw() -> void:
	if count > 0:
		Items.draw_icon(self, Vector2(0, HOLD_Y + sin(_t * 6.0) * 2.0), type, count)
		if caption != "":
			var font := ThemeDB.fallback_font
			var at := Vector2(-150, HOLD_Y - 30)
			draw_string_outline(font, at, caption, HORIZONTAL_ALIGNMENT_CENTER, 300, 20, 6, Items.INK)
			draw_string(font, at, caption, HORIZONTAL_ALIGNMENT_CENTER, 300, 20, Color("f2c230"))
