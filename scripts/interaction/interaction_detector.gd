class_name InteractionDetector
extends Area2D

## Tracks every Interactable in range and focuses exactly one: the nearest usable one.
## Focus is re-evaluated every physics frame, so freed, disabled or overlapping
## interactables can't leave a stale highlight or a dead button behind.

signal focus_changed(target: Interactable)

## A challenger must be this much closer before focus switches, so two equidistant targets don't flicker.
@export var switch_margin := 12.0

var focus: Interactable = null
## While locked (e.g. a task panel is open) focus is frozen and nothing new can be used.
var locked := false:
	set(value):
		locked = value
		if locked:
			_set_focus(null)

var _candidates: Array[Interactable] = []


func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area2D) -> void:
	if area is Interactable and area not in _candidates:
		_candidates.append(area)


func _on_area_exited(area: Area2D) -> void:
	_candidates.erase(area)


func _physics_process(_delta: float) -> void:
	for i in range(_candidates.size() - 1, -1, -1):
		if not is_instance_valid(_candidates[i]) or not _candidates[i].is_inside_tree():
			_candidates.remove_at(i)
	if locked:
		return
	var best: Interactable = null
	var best_d := INF
	for c in _candidates:
		if not c.can_interact():
			continue
		var d := global_position.distance_to(c.global_position)
		if c == focus:
			d -= switch_margin
		if d < best_d:
			best_d = d
			best = c
	_set_focus(best)


func _set_focus(target: Interactable) -> void:
	if target == focus:
		return
	if is_instance_valid(focus):
		focus.set_highlighted(false)
	focus = target
	if focus:
		focus.set_highlighted(true)
	focus_changed.emit(focus)


func try_interact() -> bool:
	if locked or not is_instance_valid(focus) or not focus.can_interact():
		return false
	focus.interact(owner if owner else get_parent())
	return true
