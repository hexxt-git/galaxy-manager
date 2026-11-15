extends SceneTree

## Balance sim: a ghost commander (a helper that always does the most-needed task) plays the colony while cards are
## picked at random. Prints stocks every game minute and the arrival times. Needs --fixed-fps to run faster than real time:
## godot --headless --fixed-fps 60 --path . -s res://tests/sim_balance.gd

var main: Node
var colony: Colony
var pending := []

func _initialize() -> void:
	_run.call_deferred()

func _offer(kind: String, cards: Array) -> void:
	pending = [kind, cards.pick_random(), colony.time + 4.0]

func _run() -> void:
	main = load("res://scenes/colony.tscn").instantiate()
	root.add_child(main)
	for i in 6:
		await physics_frame
	colony = main.colony
	colony.offer.disconnect(main._on_offer)
	colony.offer.connect(_offer)
	var ghost: Node = main.BOT.instantiate()
	ghost.set_script(main.HELPER)
	ghost.colour = "white" if Colony.CREWMATE.COLOURS.has("white") else Colony.CREWMATE.COLOURS.keys()[0]
	ghost.role = "rocks"
	ghost.perk = "steady"
	ghost.crew_name = "YOU"
	ghost.nav = main.nav
	ghost.colony = colony
	ghost.position = main.map.spawn
	main.helpers.add_child(ghost)
	var arrivals := []
	var next_print := 0.0
	var call_at := -1.0
	var won_at := -1.0
	while colony.time < 2400.0 and colony.crew.size() < Colony.MAX_CREW:
		if colony.finished and won_at < 0.0:
			won_at = colony.time
			paused = false
		await physics_frame
		ghost.speed_scale = Colony.WALK * colony.work_speed()
		var best := "rocks"
		for t in Colony.TASKS:
			if colony.wants(t) > colony.wants(best):
				best = t
		ghost.role = best
		if pending and colony.time >= pending[2]:
			var p := pending
			pending = []
			if p[0] == "crew":
				main._offer_kind = "crew"
				main._on_chosen(p[1])
				arrivals.append("%d:%02d" % [int(colony.time) / 60, int(colony.time) % 60])
			else:
				colony.choose("upgrade", p[1])
		if colony.can_call() and not pending and not colony._offering:
			if call_at < 0.0:
				call_at = colony.time + 15.0
			elif colony.time >= call_at:
				call_at = -1.0
				colony.call_crew()
		if colony.time >= next_print:
			next_print += 60.0
			var r := colony.res
			print("%2d min crew %2d  o2 %5.0f w %5.0f f %5.0f r %5.0f sh %3.0f/%3.0f  next %d/%d  pw %.1f/%.1f  beds %d  ups %s" % [
				int(colony.time / 60), colony.crew.size(), r.o2, r.water, r.food, r.research, r.shield, colony.shield_need(),
				colony.crew_cost(), colony.upgrade_cost(), colony.power.x, colony.power.y, colony.stations_of("bed").size(), colony.levels])
	print("arrivals ", arrivals)
	print("won at %.0f s, ended %.0f s" % [won_at, colony.time], " stats ", colony.stats)
	quit()
