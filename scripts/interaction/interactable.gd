class_name Interactable
extends Area2D

## Something the player can focus and use. Lives on the "interactable" physics layer; an
## InteractionDetector decides which single Interactable is focused at a time.

signal interacted(by: Node)

@export var prompt := "Use"
@export var icon: Texture2D
@export var enabled := true
## CanvasItems whose material uses selection_outline.gdshader; toggled while focused.
@export var highlight_targets: Array[CanvasItem] = []


func _ready() -> void:
	monitoring = false
	monitorable = true
	for target in highlight_targets:
		# Shared materials would light up every copy of the scene at once.
		if target.material:
			target.material = target.material.duplicate()
	set_highlighted(false)


func can_interact() -> bool:
	return enabled and is_inside_tree() and not is_queued_for_deletion()


func set_highlighted(on: bool) -> void:
	for target in highlight_targets:
		if is_instance_valid(target) and target.material is ShaderMaterial:
			(target.material as ShaderMaterial).set_shader_parameter("enabled", on)


func interact(by: Node) -> void:
	if can_interact():
		interacted.emit(by)
