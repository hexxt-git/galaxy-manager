extends SceneTree

## Headless walk through the tutorial, mistakes included: godot --headless --path . -s res://tests/test_tutorial.gd

var failures := 0
var tut: Node
var lines_read := 0


func _check(cond: bool, what: String) -> void:
	if cond:
		print("ok: ", what)
	else:
		failures += 1
		printerr("FAIL: ", what)


func _initialize() -> void:
	_run.call_deferred()


## Waits, tapping through any dialog that comes up.
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
		if tut and tut.dialog.visible:
			lines_read += 1
			tut.dialog._advance()


## Waits out the pause before a brief and taps through it.
func _settle() -> void:
	await _frames(10)
	var n := 0
	while tut and (tut._briefed != tut.step or tut.dialog.visible) and n < 600:
		await _frames(1)
		n += 1


func _shown(hud: Control) -> Array:
	return hud._chips.keys().filter(func(id: String) -> bool: return hud._chips[id].box.visible)


func _run() -> void:
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await _settle()
	_check(menu.get_child_count() > 0, "main menu builds")
	menu.free()

	Colony.start_tutorial = true
	var main: Node = load("res://scenes/colony.tscn").instantiate()
	root.add_child(main)
	await _frames(6)
	var colony: Colony = main.colony
	var player: CharacterBody2D = main.player
	var hands: Hands = main.hands
	var hud: Control = main.hud
	var guide: Node2D = main.guide
	var tutorial: Node = main.get_children().filter(func(c): return c.get_script() == main.TUTORIAL)[0]
	await _settle()
	_check(tutorial.dialog.visible and paused and tutorial.dialog._bust.texture != null, "opens with the commander talking, game paused")
	tut = tutorial
	await _frames(12)
	_check(not paused and not tut.dialog.visible and lines_read >= 6, "tapping through the intro resumes the game")
	_check(_shown(hud) == ["power"], "only power shows at the start (%s)" % [_shown(hud)])
	_check(guide.lead and guide.target is Station and guide.target.kind == "solar", "points at a solar panel")
	_check(guide.trail.size() > 1, "a trail leads there")

	var box: Control = tut.dialog
	var too_long := []
	for note in Colony.NOTES.values():
		for page in note[1]:
			box._text.text = page
			if box._text.get_line_count() > 2:
				too_long.append(page)
	for lines in tut.BRIEF.values() + [tut.OUTRO]:
		for line in lines:
			box._text.text = line
			if box._text.get_line_count() > 3:
				too_long.append(line)
	_check(too_long.is_empty(), "every note and line fits the box %s" % [too_long])
	tut.dialog.hide()
	var sign: Station = colony.stations_of("note")[0]
	main._on_station_used(sign, player)
	_check(box.visible and box._title.visible and not box._bust.visible and paused, "a note opens in the dialog box, titled, no portrait")
	await _frames(8)
	_check(not box.visible and not paused, "tapping closes the note")

	var drill: Station = colony.stations_of("drill")[0]
	_check(colony.blocked_reason(drill, player) != "", "later stations are locked")
	hands.add("sample", 1)
	main._on_station_used(drill, player)
	_check(hands.holds("sample") and not main.panel.visible, "using a locked station does nothing, not even drop what you carry")
	hands.take()

	var o2: float = colony.res.o2
	colony.tick(120.0)
	_check(colony.res.o2 == o2 and colony.stations_of("solar")[0].state.dust == 0.7, "nothing drains or gathers dust")

	for s in colony.stations_of("solar"):
		colony.finish(s, player)
	await _settle()
	_check("water" in _shown(hud) and tut.step == 1, "clean panels reveal water")
	_check(colony.power.x >= colony.power.y, "clean panels cover the base's power")

	colony.finish(drill, player)
	main._on_station_used(drill, player)  # straight back into the drill minigame during the pause
	await _frames(200)
	_check(main.panel.visible and tut._briefed != tut.step, "no brief over an open minigame")
	main.panel.close()
	await _settle()
	_check(tut.step == 2 and guide.target.kind == "melter" and guide.target_tag, "carrying ice points at the melter")
	hands.toss(Vector2.RIGHT)
	await _settle()
	_check(guide.target is ItemDrop, "dropped ice: points back at it")
	await _frames(120)
	hands.pick(get_nodes_in_group("drops").filter(func(d): return d.type == "ice")[0])
	colony.finish(colony.stations_of("melter")[0], player)
	await _settle()
	_check("o2" in _shown(hud) and colony.res.water >= tut.WATER_GIFT, "melting reveals air and gives plenty of water (%.1f)" % colony.res.water)

	var ely: Station = colony.stations_of("electrolyzer")[0]
	for i in 6:  # spam it: water must still be there for the beds
		colony.finish(ely, player)
	await _settle()
	_check("food" in _shown(hud) and tut.step == 4 and colony.res.water >= Colony.TEND_WATER, "air reveals food; water kept topped up")

	var bed: Station = colony.stations_of("bed")[0]
	_check(colony.blocked_reason(bed, player) == "", "the bed can be used")
	colony.finish(bed, player)
	await _settle()
	_check(tut.step == 5 and hands.count >= colony.crew_cost(), "one tend gives enough potatoes for a crewmate (%d)" % hands.count)
	hands.toss(Vector2.LEFT)
	await _frames(120)
	for d in get_nodes_in_group("drops"):
		if d.type == "potato":
			d.queue_free()
	await _settle()
	_check(bed.state.grown >= colony.crew_cost(), "lost the potatoes: the bed refills")
	colony.finish(bed, player)
	colony.finish(colony.stations_of("kitchen")[0], player)
	await _settle()
	_check("crew" in _shown(hud) and tut.step == 6 and colony.can_call(), "stocking food reveals crew and comms is ready")

	main._on_station_used(colony.stations_of("comms")[0], player)
	await process_frame
	_check(main.picker.visible, "comms opens the crewmate cards")
	main.picker.hide()
	paused = false
	var cards: Array = colony._crew_cards()
	main._offer_kind = "crew"
	main._on_chosen(cards[0])
	await _settle()
	_check(colony.crew.size() == 2 and "research" in _shown(hud) and tut.step == 7 and colony.hold, "crewmate lands: research shows, tutorial goes on")
	_check(guide.target is Station and guide.target.kind == "outcrop", "points at a rock outcrop")
	_check(not main.picker.visible, "no upgrade cards yet")

	colony.finish(colony.stations_of("outcrop")[0], player)
	await _settle()
	_check(tut.step == 8 and guide.target.kind == "lab", "carrying rocks points at the Lab")
	colony.finish(colony.stations_of("lab")[0], player)
	await _settle()
	_check(colony.res.research >= colony.upgrade_cost(), "research covers an upgrade (%.1f)" % colony.res.research)
	await _frames(10)
	_check(tut.step == 9 and main.picker.visible, "after the brief the upgrade cards open")
	main.picker.hide()
	paused = false
	main._offer_kind = "upgrade"
	main._on_chosen(colony._upgrade_cards()[0])
	await _settle()
	await _frames(200)
	_check(colony.count("upgrades") == 1 and _shown(hud).size() == 6 and not colony.hold and colony.only.is_empty() and not paused, "upgrade picked: tutorial done, everything on")
	_check(not guide.lead and not tut.dialog.visible, "outro read, back to normal hints")
	_check(main.player.get_node("Camera").offset.is_zero_approx(), "camera back on the player (%s)" % main.player.get_node("Camera").offset)

	print("FAILURES: ", failures)
	quit(1 if failures else 0)
