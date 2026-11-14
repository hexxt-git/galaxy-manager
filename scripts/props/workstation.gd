extends Node2D

@export var title := "Workstation"


func _ready() -> void:
	$Interactable.interacted.connect(_on_interacted)


func _on_interacted(_by: Node) -> void:
	var panel := get_tree().get_first_node_in_group("task_panel") as TaskPanel
	if panel:
		panel.open(self, title)
