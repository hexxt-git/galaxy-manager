extends SceneTree

## Headless check of the main scene wiring: godot --headless --path . -s res://tests/test_main_scene.gd

var failures := 0


func _check(cond: bool, what: String) -> void:
	if cond:
		print("ok: ", what)
	else:
		failures += 1
		printerr("FAIL: ", what)


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var player: CharacterBody2D = main.get_node("World/Player")
	var det: InteractionDetector = player.get_node("InteractionDetector")
	await _frames(1)
	var stations := main.get_node("World/Map").get_children().filter(func(n): return n.get("title") != null)
	var a: Node2D = stations.filter(func(n): return n.title == "Navigation")[0]
	var b: Node2D = stations.filter(func(n): return n.title == "Life Support")[0]
	var use: UseButton = main.get_node("HUD/UseButton")
	var panel: TaskPanel = main.get_node("HUD/TaskPanel")
	await _frames(4)
	_check(det.focus == null and use.disabled, "nothing in reach at spawn, button disabled")

	player.global_position = a.global_position + Vector2(0, 60)
	await _frames(4)
	var mat_a := (a.get_node("Sprite") as Sprite2D).material as ShaderMaterial
	var mat_b := (b.get_node("Sprite") as Sprite2D).material as ShaderMaterial
	_check(det.focus == a.get_node("Interactable"), "walking up to A focuses A")
	_check(mat_a.get_shader_parameter("enabled") and not mat_b.get_shader_parameter("enabled"), "only A is outlined")
	_check(not use.disabled, "use button enabled")

	use.pressed.emit()
	await _frames(2)
	_check(panel.visible and panel.title_label.text == "Navigation", "use opens A's panel")
	_check(det.locked and not mat_a.get_shader_parameter("enabled"), "panel open: focus frozen, outline off")
	panel.close()
	await _frames(4)
	_check(not panel.visible and not det.locked and det.focus == a.get_node("Interactable"), "closing restores focus")

	use.pressed.emit()
	await _frames(2)
	_check(panel.get_node("Window").mouse_filter == Control.MOUSE_FILTER_STOP, "taps inside the window don't reach the dim backdrop")
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	panel.get_node("Dim").gui_input.emit(tap)
	await _frames(2)
	_check(not panel.visible, "tapping outside the window closes the panel")

	player.global_position = b.global_position + Vector2(0, 60)
	await _frames(4)
	_check(det.focus == b.get_node("Interactable") and mat_b.get_shader_parameter("enabled") and not mat_a.get_shader_parameter("enabled"), "moving to B switches outline to B")

	print("FAILURES: ", failures)
	quit(1 if failures else 0)
