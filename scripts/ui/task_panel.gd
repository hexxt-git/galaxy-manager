class_name TaskPanel
extends Control

## Modal task window. While open, the player can't move and interaction focus is frozen.

signal closed

@onready var title_label: Label = %Title
@onready var close_button: BaseButton = %Close

var source: Node = null


func _ready() -> void:
	add_to_group("task_panel")
	hide()
	close_button.pressed.connect(close)
	$Dim.gui_input.connect(_on_dim_input)


func open(from: Node, title: String) -> void:
	source = from
	title_label.text = title
	show()
	_set_player_busy(true)


func close() -> void:
	if not visible:
		return
	hide()
	source = null
	_set_player_busy(false)
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("close_panel") or event.is_action_pressed("ui_cancel")):
		close()
		get_viewport().set_input_as_handled()


func _on_dim_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		close()
		accept_event()


func _set_player_busy(busy: bool) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		player.set_busy(busy)
