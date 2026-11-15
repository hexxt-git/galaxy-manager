extends SceneTree

## Runs one station's minigame skin through every state headlessly and reports script errors.
## Usage: Godot --headless --path . -s res://tests/minigame_smoke.gd -- <kind> <mode> [heat]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var kind: String = args[0] if args.size() > 0 else "solar"
	var mode: String = args[1] if args.size() > 1 else "taps"
	var game := Minigame.new()
	var path := "res://scripts/colony/minigames/%s.gd" % kind
	if ResourceLoader.exists(path):
		game.skin = load(path).new()
	game.mode = mode
	game.heat = "heat" in args
	game.fact = "A fact about this task, shown at the bottom."
	game.size = Vector2(552, 772)
	root.add_child(game)
	for i in 30:
		await process_frame
	var press := func(down: bool) -> void:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = game._button()
		game._gui_input(e)
	for i in 12:
		press.call(true)
		for f in 20:
			await process_frame
		press.call(false)
		for f in 5:
			await process_frame
	print("progress %.2f done %s flawless %s" % [game._progress, game._done, game.flawless])
	quit()
