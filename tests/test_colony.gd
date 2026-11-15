extends SceneTree

## Headless check of the colony prototype: godot --headless --path . -s res://tests/test_colony.gd

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
	var main: Node = load("res://scenes/colony.tscn").instantiate()
	root.add_child(main)
	await _frames(4)
	var colony: Colony = main.colony
	var map: ColonyMap = main.map
	var player: CharacterBody2D = main.player
	var hands: Hands = main.hands
	var kinds := {}
	for s in map.stations:
		kinds[s.kind] = kinds.get(s.kind, 0) + 1
	print(kinds)
	_check(kinds.get("solar") == 2 and kinds.get("bed") == 2 and kinds.get("drill") == 1 and kinds.get("note") == 9 and kinds.get("outcrop") == 2 and kinds.get("pit") == 1 and kinds.get("shield") == 1 and kinds.get("oven") == 1 and kinds.get("comms") == 1 and kinds.get("electrolyzer") == 1 and kinds.get("decor", 0) > 3, "small starting base built from the layout")
	_check(map.free_slots("G") == 4 and map.free_slots("S") == 4 and map.free_slots("N") == 1, "empty slots left to build into")
	_check(map.char_at(player.global_position) == ".", "player spawns on indoor floor")
	_check(main.nav != null and main.nav.targets.size() > 1000, "nav grid built")

	# items: bounce and settle, merge, pick up, swap
	var at := player.global_position + Vector2(0, 120)
	var a := ItemDrop.spawn(main.items, at, "ice", 2)
	a.h = 40.0
	a.toss(Vector2(60, 0), 200.0)
	var b := ItemDrop.spawn(main.items, at + Vector2(80, 0), "ice", 3)
	var bounces := 0
	var last_vh := 0.0
	for i in 240:
		await physics_frame
		if is_instance_valid(a) and last_vh < 0.0 and a.vh > 0.0:
			bounces += 1
		if is_instance_valid(a):
			last_vh = a.vh
	_check(bounces >= 1, "tossed drop bounces (%d)" % bounces)
	var merged := not is_instance_valid(a) or not is_instance_valid(b)
	var stack: ItemDrop = b if is_instance_valid(b) else a
	_check(merged and stack.count == 5 and stack.resting, "drops settle within 4 s and merge into one stack of 5")
	hands.pick(stack)
	await _frames(2)
	_check(hands.holds("ice") and hands.count == 5, "picking up takes the whole stack")
	var rock := ItemDrop.spawn(main.items, at, "sample", 1)
	hands.pick(rock)
	await _frames(2)
	var ice_left: Array = main.items.get_children().filter(func(d): return d.type == "ice" and not d.is_queued_for_deletion())
	_check(hands.holds("sample") and hands.count == 1 and ice_left.size() == 1 and ice_left[0].count == 5, "a different item swaps: old stack tossed out")
	hands.toss(Vector2.RIGHT)
	await _frames(2)
	hands.add("sample", 2)
	main._on_station_used(colony.stations_of("drill")[0], player)
	_check(hands.is_empty() and main.panel.visible, "using the drill while carrying rocks drops them and starts drilling")
	main.panel.close()
	await _frames(2)

	# station rules
	var ls: Station = colony.stations_of("melter")[0]
	_check(colony.blocked_reason(ls, player) != "", "the ice melter refuses empty hands")
	for panel in colony.stations_of("solar"):
		panel.state.dust = 0.0
	colony.tick(0.1)
	hands.add("ice", 2)
	var water: float = colony.res.water
	var o2: float = colony.res.o2
	_check(colony.blocked_reason(ls, player) == "", "the ice melter takes ice")
	colony.finish(ls, player)
	_check(is_equal_approx(colony.res.water, water + 2.0 * Colony.WATER_PER_ICE) and is_equal_approx(colony.res.o2, o2) and hands.is_empty(), "2 ice -> water, no air")
	var ely: Station = colony.stations_of("electrolyzer")[0]
	colony.finish(ely, player)
	_check(is_equal_approx(colony.res.water, water + 2.0 * Colony.WATER_PER_ICE - Colony.SPLIT_WATER) and colony.res.o2 > o2, "the electrolyzer turns water into air")
	_check(colony.current_objective()[1] == "solar", "first objective is the solar panels, not a note")
	hands.add("ice", 1)
	_check(colony.destinations("ice") == colony.stations_of("melter") and main._caption() == "Ice -> Ice melter", "carried ice says where it goes")
	hands.take()
	_check(colony.destinations("bag").is_empty(), "locked stations aren't destinations")

	# research offers upgrade cards; picking one builds into a slot
	var picker: Control = main.picker
	var lab: Station = colony.stations_of("lab")[0]
	hands.add("sample", 3)
	colony.res.water = 10.0
	colony.finish(lab, player)
	_check(is_equal_approx(colony.res.water, 10.0 - 3.0 * Colony.LAB_WATER) and colony.lab_busy > 0.0, "analysing rocks uses water and draws power")
	await process_frame
	await process_frame
	_check(picker.visible and paused, "enough research opens the upgrade picker and pauses")
	var cards: Array = picker._row.get_children().filter(func(c): return not c.is_queued_for_deletion())
	_check(cards.size() == Colony.CARDS, "picker shows %d cards" % Colony.CARDS)
	colony.choose("upgrade", {"id": "bed", "title": "Grow bed"})
	picker.hide()
	paused = false
	await _frames(2)
	_check(colony.stations_of("bed").size() == 3 and map.free_slots("G") == 3, "the grow bed upgrade builds a new bed")

	# no lose condition
	for k in colony.res:
		colony.res[k] = 0.0
	colony.tick(30.0)
	_check(not colony.finished and player.speed_scale < 1.0, "empty stocks only slow the crew down")
	colony.res.o2 = 20.0
	colony.res.water = 20.0

	# tending a bed turns water into food on the spot; doubling upgrades double it
	var bed: Station = colony.stations_of("bed")[0]
	colony.res.water = 10.0
	var food: float = colony.res.food
	colony.finish(bed, player)
	_check(is_equal_approx(colony.res.food, food + Colony.TEND_FOOD) and is_equal_approx(colony.res.water, 9.0), "tending: 1 water -> 1 food")
	colony.levels.bed_x = 1
	food = colony.res.food
	colony.finish(bed, player)
	_check(is_equal_approx(colony.res.food, food + Colony.TEND_FOOD), "tending stays flat: upgrades only multiply the beds")
	colony.levels.bed_x = 0
	food = colony.res.food
	colony.tick(60.0)
	_check(colony.res.food > food - Colony.EAT, "beds grow food on their own (%.2f/min)" % colony.food_rate())

	# stocking food offers crewmate cards; a farmer tends beds on their own
	colony.res.food = colony.crew_cost() + 1.0
	await process_frame
	await process_frame
	_check(not picker.visible, "food alone doesn't summon crew")
	var comms: Station = colony.stations_of("comms")[0]
	colony.finish(comms, player)
	await process_frame
	_check(picker.visible, "the Comms dish with enough food opens the crew picker")
	var farmer := {"name": "Ada", "colour": "blue", "role": "harvest", "perk": "quick", "title": "Ada the Farmer", "text": ""}
	picker.hide()
	paused = false
	main._on_chosen(farmer)
	await _frames(30)
	var helper: Node = main.helpers.get_child(0) if main.helpers.get_child_count() else null
	_check(helper != null and colony.crew.size() == 2 and helper.role == "harvest", "picking a card lands that crewmate")
	if helper:
		colony.res.water = 20.0
		var tended: int = colony.count("harvested")
		for i in 60 * 40:
			await physics_frame
			if colony.count("harvested") > tended:
				break
		_check(colony.count("harvested") > tended, "the farmer tended a bed (stuck recoveries %d)" % helper.recoveries)

	# a technician with clean panels pitches in elsewhere instead of idling
	for p in colony.stations_of("solar"):
		p.state.dust = 0.0
	colony.levels.coating = 1
	main._on_chosen({"name": "Yuri", "colour": "red", "role": "solar", "perk": "steady", "title": "Yuri", "text": ""})
	await _frames(60)
	var tech: Node = main.helpers.get_child(1)
	_check(tech.busy_with != "idle", "an off-duty technician helps out: %s" % tech.busy_with)
	var taken: Array = colony.crew.map(func(c): return str(c.get("crew_name")))
	_check(colony._crew_cards().all(func(c): return c.name not in taken), "crew cards never repeat a crewmate's name")

	# growing the crew unlocks the reactor and then flares + shielding
	main._on_chosen({"name": "Mae", "colour": "green", "role": "ice", "perk": "hardy", "title": "Mae", "text": ""})
	_check(colony.unlocked.has("reactor") and colony._can_take("reactor"), "3 crew unlocks the reactor card")
	for n in ["Neil", "Sally"]:
		main._on_chosen({"name": n, "colour": "yellow", "role": "rocks", "perk": "quick", "title": n, "text": ""})
	_check(colony.unlocked.has("shield") and colony.flare_in < INF, "5 crew unlocks shielding and starts flares")
	colony.res.shield = 0.0
	colony.flare_in = 0.01
	colony.tick(0.05)
	_check(colony.fatigue > 0.0 and colony.work_speed() < 1.0, "a flare on an unshielded base slows the crew")
	colony.fatigue = 0.0
	colony.res.shield = colony.shield_need()
	colony.flare_in = 0.01
	colony.tick(0.05)
	_check(colony.fatigue == 0.0, "enough regolith blocks the flare")


	print("FAILURES: ", failures)
	quit(1 if failures else 0)
