extends Node

## X quits from any screen, paused or not, before any other node can take the key. Desktop only.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(OS.get_name() not in ["Android", "iOS", "Web"])


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()
