extends SceneTree

## Headless check of the interaction focus rules:
##   godot --headless --path . -s res://tests/test_interaction.gd

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _make_interactable(pos: Vector2) -> Interactable:
	var it := Interactable.new()
	it.collision_layer = 4
	it.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 40.0
	shape.shape = circle
	it.add_child(shape)
	it.position = pos
	root.add_child(it)
	return it


func _check(cond: bool, what: String) -> void:
	if not cond:
		failures += 1
		printerr("FAIL: ", what)
	else:
		print("ok: ", what)


func _settle() -> void:
	for i in 4:
		await physics_frame


func _run() -> void:
	var det := InteractionDetector.new()
	det.collision_layer = 0
	det.collision_mask = 4
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 100.0
	shape.shape = circle
	det.add_child(shape)
	root.add_child(det)

	var changes: Array = []
	det.focus_changed.connect(func(t): changes.append(t))

	var a := _make_interactable(Vector2(60, 0))
	var b := _make_interactable(Vector2(-90, 0))
	var far := _make_interactable(Vector2(600, 0))
	await _settle()
	_check(det.focus == a, "nearest of two overlapping targets gets focus")
	_check(far not in det._candidates, "out-of-range target is ignored")

	det.position = Vector2(-75, 0)
	await _settle()
	_check(det.focus == b, "focus moves to the new nearest target")

	det.position = Vector2(-15, 0)
	await _settle()
	_check(det.focus == b, "near-equidistant targets don't flip focus (hysteresis)")

	b.enabled = false
	await _settle()
	_check(det.focus == a, "disabling the focused target hands focus to the next one")
	b.enabled = true

	det.position = Vector2(-75, 0)
	await _settle()
	var focused := det.focus
	focused.queue_free()
	await _settle()
	_check(det.focus == a, "freeing the focused target doesn't leave a dead focus")

	var used := []
	a.interacted.connect(func(by): used.append(by))
	det.locked = true
	await _settle()
	_check(det.focus == null and not det.try_interact(), "locked detector has no focus and can't interact")
	det.locked = false
	await _settle()
	_check(det.try_interact() and used.size() == 1, "unlocked detector interacts with its focus once")

	a.queue_free()
	await _settle()
	_check(det.focus == null and changes.back() == null, "no targets left -> focus cleared and signalled")

	print("FAILURES: ", failures)
	quit(1 if failures else 0)
