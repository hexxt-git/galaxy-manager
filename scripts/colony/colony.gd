class_name Colony
extends Node

## Resources, the repeating tasks, card offers, unlocks and the win. Nothing ends the run and nothing waits on a timer:
## every task gives its output the moment someone does it, so every extra pair of hands means more output.
##   ice     — drill ice in the crater, carry it to the ice melter: water
##   air     — split water into oxygen at the electrolyzer
##   harvest — tend a potato bed: 1 water becomes food on the spot. Beds also grow food on their own from water and power.
##   solar   — wipe moondust off the solar panels: power
##   rocks   — dig rocks at an outcrop, carry them to the lab: research
##   shield  — (from SHIELD_AT crew) dig regolith bags, stack them in the shield wall against solar flares
## Food buys crewmates, called in at the Comms dish; research buys buildings (beds, panels, reactor) and doubling upgrades, Cookie Clicker style.

signal message(text: String)
signal popup(at: Vector2, text: String)
signal offer(kind: String, cards: Array)
signal station_added(s: Station)
signal crew_changed
signal did(s: Station, actor: Node, result: String)
signal won
signal flare(hit: bool)

const CREWMATE := preload("res://scripts/crewmate.gd")

# per crew member per minute
const BREATHE := 0.5
const DRINK := 0.3
const EAT := 0.4
const ICE_PER_DRILL := 2
const WATER_PER_ICE := 1.6
const SCAN_PERFECT := 1.5  # research multiplier for a scan with no misses
const SPLIT_WATER := 2.0  # water used by one run of the electrolyzer
const SPLIT_O2 := 2.0  # air it makes at full power
const TEND_FOOD := 1.5
const TEND_WATER := 1.0
const BED_RATE := 0.5  # food per bed per minute, on its own
const BED_WATER := 0.25  # water per bed per minute while it grows
const DUST_RATE := 1.0 / 120.0
const PANEL_POWER := 1.5
const REACTOR_POWER := 6.0
const REACTOR_WATER := 0.5  # cooling water per minute; a dry reactor runs at half power
const BASE_DEMAND := 0.5
const CREW_DEMAND := 0.25
const BED_DEMAND := 0.75
const ROCKS_PER_DIG := 3
const LAB_WATER := 1.0  # water used to prep each rock
const LAB_POWER := 3.0  # extra power the lab draws while it works
const SPLIT_POWER := 3.0  # extra power the electrolyzer draws while it works
const LAB_BUSY := 10.0  # seconds the lab keeps drawing power after an analysis
const SCAN_HITS := 3  # the player's scan is this many hits, whatever the rock count
const BAGS_PER_DIG := 2
const OVEN_O2 := 3.0  # per rock, against 1 per ice
const SHIELD_PER_CREW := 3.0
const ARRIVAL_FOOD := 5.0
const CREW_GROWTH := 1.35
const UPGRADE_COST := 3.0
const UPGRADE_GROWTH := 1.35
const WIN_CREW := 12
const MAX_CREW := 20  # the base keeps growing after the win, up to this
const REACTOR_AT := 3
const SHIELD_AT := 5
const OVEN_AT := 7
const FLARE_EVERY := 75.0
const FLARE_WEAR := 1.0  # bags each flare wears away per crewmate
const FLARE_WARN := 15.0
const FATIGUE := 30.0
const FATIGUE_SLOW := 0.6
const PERFECT := 2.0  # output multiplier for a flawless minigame
const SLOW := 0.6
const WALK := 1.5  # everyone walks faster to cover the roomier map
const CARDS := 3
const OFFER_GAP := 15.0  # seconds between two card pickers
const ICE_ENOUGH := 2.0  # minutes of water and air in the tanks before crew stop drilling

const TASKS := ["ice", "air", "harvest", "solar", "rocks", "shield"]
const CREW_ROLES := ["ice", "harvest", "solar", "rocks", "shield"]
const ROLES := {
	"air": ["Chemist", "Splits water into air."],
	"ice": ["Miner", "Likes drilling ice and melting it into water."],
	"harvest": ["Farmer", "Likes tending the potato beds."],
	"solar": ["Technician", "Likes keeping the solar panels clean."],
	"rocks": ["Geologist", "Likes digging rocks for the lab."],
	"shield": ["Builder", "Likes stacking regolith shielding."],
}
const PERKS := {
	"quick": ["Quick", "Walks 30% faster."],
	"steady": ["Steady", "Works twice as fast at machines."],
	"hardy": ["Hardy", "Needs half the air, water and food."],
}
const NAMES := ["Ada", "Yuri", "Mae", "Neil", "Sally", "Buzz", "Kalpana", "Chris", "Valentina", "Koichi", "Peggy", "Thomas",
	"Samantha", "Ilan", "Wally", "Jessica", "Guion", "Helen", "Rakesh", "Eileen"]
# id -> [title, text, rule]. Rules: slot (builds into a free slot of that letter), crew (needs that many crew),
# own [station kind, counts] / stat [stat, counts]: one more level each time the count is reached, max: plain limit.
const UPGRADES := {
	"bed": ["Grow bed", "Another potato bed: grows food on its own and gives crew one more place to tend.", {"slot": "G"}],
	"panel": ["Solar panel", "Another solar panel on the field: +%.1f power when clean." % PANEL_POWER, {"slot": "S"}],
	"reactor": ["Kilopower reactor", "+%d steady power, day or night. Drinks %.1f cooling water a minute." % [REACTOR_POWER, REACTOR_WATER], {"slot": "N", "crew": REACTOR_AT}],
	"bed_x": ["Hydroponic roots", "Beds grow twice as much food on their own. Roots in nutrient water grow faster than in soil.", {"own": ["bed", [3, 5, 6]]}],
	"panel_x": ["Multi-junction cells", "Double the power of every panel. Stacked cell layers catch more colours of sunlight.", {"own": ["solar", [4, 6]]}],
	"bit": ["Diamond drill bit", "Double the ice from every drill run.", {"stat": ["ice", [8, 30]]}],
	"lab_x": ["Mass spectrometer", "Double the research from every rock.", {"stat": ["rocks", [15, 60]]}],
	"coating": ["Dust-repellent coating", "Solar panels gather dust half as fast.", {"max": 1}],
	"recycler": ["Water recycler", "Crew need half the water. The ISS recycles about 98% of its water.", {"max": 1}],
	"boots": ["Better suits", "Crew walk and work 25% faster.", {"max": 2}],
	"training": ["Crew training", "Crew walk and work 15% faster. Can be taken again and again.", {"endless": true, "crew": 6}],
	"automation": ["Greenhouse automation", "Beds grow 50% more food on their own. Can be taken again and again.", {"endless": true, "crew": 6}],
}
# crew count -> [what unlocks, message]
const UNLOCKS := {
	REACTOR_AT: ["reactor", "Unlocked: the Kilopower reactor. Look for it in the upgrade cards."],
	SHIELD_AT: ["shield", "Unlocked: radiation shielding. Solar flares will start hitting the base: dig regolith in the pit north of the hab and stack the bags in the hab's shield wall."],
	OVEN_AT: ["oven", "Unlocked: the ISRU oven in the life support room. It bakes oxygen out of moon rocks, if you can spare them from the lab."],
}
const NOTES := {
	1: "WELCOME, COMMANDER\nYou're alone at Shackleton Base, on the Moon's south pole.\nKeep four things going: ice, potatoes, solar power and research.\nStock food to recruit crewmates, spend research on buildings and upgrades.\nUSE picks things up, DROP (G) throws them, M shows the map.",
	2: "POWER\nSolar is free, but moondust keeps cutting what the panels make.\nA small fission reactor (NASA's Kilopower) gives steady power no matter what, and a lunar night lasts about 14 Earth days.",
	3: "GREENHOUSE\nPlants grow under red and blue LEDs, the colours chlorophyll absorbs best.\nPotatoes are a top space crop: lots of calories in little space. They need water and power.",
	4: "LIFE SUPPORT\nIce is melted and filtered into water. The electrolyzer then splits water with electricity:\n2 H2O -> 2 H2 + O2\nThat's the oxygen you breathe. Every drop you split is a drop nobody drinks or grows food with.",
	5: "LAB\nMoon rocks tell us what's here and how to use it. Ilmenite holds oxygen and titanium; dark crater floors hold ice.\nResearch buys buildings and upgrades: pick the one your base needs most.",
	6: "SOLAR FIELD\nNear the south pole the Sun skims the horizon, so high ground is lit most of the time.\nMoondust is sharp and clings to everything. Dusty panels make less power.",
	7: "SHACKLETON CRATER\nIts floor hasn't seen sunlight in billions of years: about -230 C.\nThat cold trapped water ice, the most precious thing on the Moon.",
	8: "RADIATION\nThe Moon has no air and no magnetic field to stop solar flares.\nAbout half a metre of packed regolith (moon dirt) blocks most of a flare. Every crewmate needs %d bags of it." % SHIELD_PER_CREW,
	9: "ISRU OVEN\nIn-situ resource use: making what you need from what's there.\nMoon rock is about 40% oxygen by mass, locked in minerals like ilmenite. Heat it with hydrogen and out comes water.",
}
# kind -> what using it does, shown on the station and in the USE prompt
const RECIPES := {
	"solar": "wipe dust = more power",
	"drill": "makes ice",
	"melter": "ice -> water",
	"electrolyzer": "water -> air (uses lots of power)",
	"bed": "water -> food",
	"lab": "rocks + water -> research (uses lots of power)",
	"outcrop": "makes rocks",
	"pit": "makes regolith bags",
	"shield": "bags -> flare shield",
	"oven": "rocks -> air",
	"reactor": "water -> power",
	"comms": "food -> new crewmate",
}
const MAKES := {"drill": "ice", "outcrop": "sample", "pit": "bag"}
# carried item -> station kinds it goes to
const DESTINATIONS := {"ice": ["melter"], "sample": ["lab", "oven"], "bag": ["shield"]}
# kind -> [minigame mode, fact shown during it]
const MINIGAMES := {
	"solar": ["taps", "Wipe the dust! Moondust is electrostatic: it clings to everything."],
	"drill": ["hold", "Hold to drill. Let go before the bit overheats: warm ice turns straight to vapour in vacuum. Finish without overheating for double ice."],
	"bed": ["taps", "Tend the potatoes. One plant can feed a person for a day."],
	"lab": ["timing", "Stop the scan on the green band to identify the mineral's spectral line. No misses and the last hit earns 50% more."],
	"outcrop": ["taps", "Chip off a sample. Most moon rock is basalt or anorthosite, the bright rock of the highlands."],
	"electrolyzer": ["hold", "Hold to run current through the water. Bubbles of hydrogen and oxygen come off the two electrodes."],
	"pit": ["taps", "Shovel regolith into bags. It's fine as flour and sharp as glass."],
}

var res := {"o2": 4.0, "water": 8.0, "food": 3.0, "research": 0.0, "shield": 0.0}
var crew: Array[Node] = []
var time := 0.0
var power := Vector2.ZERO  # supply, demand
var stats := {}
var levels := {}  # upgrade id -> times taken
var unlocked := {}  # UNLOCKS id -> true
var finished := false
var paused := false
var step := 0
var lab_busy := 0.0
var split_busy := 0.0
var fatigue := 0.0  # seconds of flare fatigue left
var flare_in := INF
var map: ColonyMap
var items: Node

var _offering := false
var _last_offer := -INF
var _warned := false


func setup(m: ColonyMap, item_layer: Node) -> void:
	map = m
	items = item_layer
	for s in map.stations:
		_init_station(s)


func _init_station(s: Station) -> void:
	if s.kind == "solar":
		s.state.dust = 0.6


func stations_of(kind: String) -> Array:
	return map.stations.filter(func(s: Station) -> bool: return s.kind == kind)


func count(stat: String) -> int:
	return stats.get(stat, 0)


func bump(stat: String, n := 1) -> void:
	stats[stat] = count(stat) + n


func level(id: String) -> int:
	return levels.get(id, 0)


func mult(id: String) -> float:
	return pow(2.0, level(id))


func crew_cost() -> float:
	return roundf(ARRIVAL_FOOD * pow(CREW_GROWTH, count("arrivals")))


func upgrade_cost() -> float:
	return roundf(UPGRADE_COST * pow(UPGRADE_GROWTH, count("upgrades")))


func shield_need() -> float:
	return SHIELD_PER_CREW * crew.size()


## How fast crew walk and work, from suits and flare fatigue.
func work_speed() -> float:
	return pow(1.25, level("boots")) * pow(1.15, level("training")) * (FATIGUE_SLOW if fatigue > 0.0 else 1.0)


## Stations a carried `item` can be used at right now.
func destinations(item: String) -> Array:
	var out := []
	for kind in DESTINATIONS.get(item, []):
		if not is_locked(kind):
			out += stations_of(kind)
	return out


func power_ratio() -> float:
	return clampf(power.x / power.y, 0.0, 1.0) if power.y > 0.0 else 1.0


func food_rate() -> float:
	return stations_of("bed").size() * BED_RATE * mult("bed_x") * pow(1.5, level("automation")) * power_ratio() if res.water > 0.0 else 0.0


func tick(delta: float) -> void:
	if paused:
		return
	time += delta
	var m := delta / 60.0
	for c in crew:
		var need := 0.5 if c.get_meta("perk", "") == "hardy" else 1.0
		for k in [["o2", BREATHE], ["water", DRINK * (0.5 if level("recycler") else 1.0)], ["food", EAT]]:
			res[k[0]] = maxf(0.0, res[k[0]] - need * k[1] * m)

	var reactors := stations_of("reactor").size()
	var supply := 0.0
	if reactors:
		supply += REACTOR_POWER * reactors * (1.0 if res.water > 0.0 else 0.5)
		res.water = maxf(0.0, res.water - REACTOR_WATER * reactors * m)
	for s in stations_of("solar"):
		s.state.dust = minf(1.0, s.state.dust + DUST_RATE * pow(0.5, level("coating")) * delta)
		supply += PANEL_POWER * mult("panel_x") * (1.0 - s.state.dust)
	var beds := stations_of("bed").size()
	power = Vector2(supply, BASE_DEMAND + CREW_DEMAND * crew.size() + BED_DEMAND * beds + (LAB_POWER if lab_busy > 0.0 else 0.0) + (SPLIT_POWER if split_busy > 0.0 else 0.0))
	res.food += food_rate() * m
	if res.water > 0.0:
		res.water = maxf(0.0, res.water - BED_WATER * beds * m)

	lab_busy = maxf(0.0, lab_busy - delta)
	split_busy = maxf(0.0, split_busy - delta)
	fatigue = maxf(0.0, fatigue - delta)
	_tick_flare(delta)
	for c in crew:
		if is_instance_valid(c):
			var perk := 1.3 if c.get_meta("perk", "") == "quick" else 1.0
			var suit := work_speed() if c.is_in_group("helpers") else 1.0
			c.speed_scale = perk * c.get_meta("base_speed", 1.0) * suit * (SLOW if res.o2 <= 0.0 else 1.0)
	_check_offers()
	_update_labels()


func _tick_flare(delta: float) -> void:
	if not unlocked.has("shield"):
		return
	flare_in -= delta
	if flare_in <= FLARE_WARN and not _warned:
		_warned = true
		message.emit("Solar flare in %d s! Shielding: %d / %d bags." % [FLARE_WARN, res.shield, shield_need()])
	if flare_in <= 0.0:
		flare_in = FLARE_EVERY
		_warned = false
		bump("flares")
		var wear := minf(res.shield, FLARE_WEAR * crew.size())
		if res.shield >= shield_need():
			bump("flares_blocked")
			res.shield -= wear
			message.emit("Solar flare! The regolith shield stopped it, but %d bags crumbled." % wear)
			flare.emit(false)
		else:
			fatigue = FATIGUE
			res.shield -= wear
			message.emit("Solar flare hit an unshielded base: crew work slowly for %d s. Stack more regolith bags." % FATIGUE)
			flare.emit(true)


func _check_offers() -> void:
	if _offering or time - _last_offer < OFFER_GAP:
		return
	if res.research >= upgrade_cost():
		var cards := _upgrade_cards()
		if not cards.is_empty():
			_offering = true
			offer.emit("upgrade", cards)


func can_call() -> bool:
	return res.food >= crew_cost() and crew.size() < MAX_CREW


## The Comms dish: with enough food stocked, ask Earth for a crewmate.
func call_crew() -> void:
	if _offering or not can_call():
		return
	_offering = true
	offer.emit("crew", _crew_cards())


func _crew_cards() -> Array:
	var used_colours := crew.map(func(c: Node) -> String: return c.colour)
	var colours: Array = CREWMATE.COLOURS.keys().filter(func(c: String) -> bool: return c not in used_colours)
	if colours.is_empty():
		colours = CREWMATE.COLOURS.keys()
	colours.shuffle()
	var roles: Array = CREW_ROLES.filter(func(t: String) -> bool: return t != "shield" or unlocked.has("shield"))
	roles.shuffle()
	var taken := crew.map(func(c: Node) -> String: return str(c.get("crew_name")))
	var names: Array = NAMES.filter(func(n: String) -> bool: return n not in taken)
	names.shuffle()
	var cards := []
	for i in CARDS:
		var role: String = roles[i % roles.size()]
		var perk: String = PERKS.keys().pick_random()
		cards.append({"name": names[i], "colour": colours[i % colours.size()], "role": role, "perk": perk,
			"title": "%s the %s" % [names[i], ROLES[role][0]],
			"text": "%s Helps wherever needed otherwise.\n\n%s: %s" % [ROLES[role][1], PERKS[perk][0], PERKS[perk][1]]})
	return cards


func _can_take(id: String) -> bool:
	var rule: Dictionary = UPGRADES[id][2]
	if crew.size() < rule.get("crew", 0):
		return false
	if rule.has("endless"):
		return true
	if rule.has("slot"):
		return map.free_slots(rule.slot) > 0
	if rule.has("max"):
		return level(id) < rule.max
	var need: Array = rule.get("own", rule.get("stat"))
	var steps: Array = need[1]
	if level(id) >= steps.size():
		return false
	var have := stations_of(need[0]).size() if rule.has("own") else count(need[0])
	return have >= steps[level(id)]


func _card_text(id: String) -> String:
	var rule: Dictionary = UPGRADES[id][2]
	var text: String = UPGRADES[id][1]
	if rule.has("own") or rule.has("stat"):
		text += "\n\nNow x%d -> x%d" % [mult(id), mult(id) * 2]
	elif rule.has("endless"):
		text += "\n\nLevel %d -> %d" % [level(id), level(id) + 1]
	elif rule.has("slot"):
		var kind: String = Station.KINDS[rule.slot][0]
		text += "\n\nYou have %d." % stations_of(kind).size()
	return text


func _upgrade_cards() -> Array:
	var open: Array = UPGRADES.keys().filter(_can_take)
	open.shuffle()
	# what the base is short of goes first, so a needed upgrade is always on offer
	var urgent := []
	if power.x < power.y * 1.1:
		urgent += ["panel", "reactor", "panel_x"]
	elif res.water >= 5.0:
		urgent += ["bed", "bed_x"]
	for id in urgent:
		if id in open:
			open.erase(id)
			open.push_front(id)
	open = open.slice(0, CARDS)
	open.shuffle()
	return open.map(func(id: String) -> Dictionary:
		return {"id": id, "title": UPGRADES[id][0], "text": _card_text(id)})


## Called with the picked card.
func choose(kind: String, card: Dictionary) -> void:
	_offering = false
	_last_offer = time
	if kind == "crew":
		res.food -= crew_cost()
		bump("arrivals")
		message.emit("%s lands and gets to work." % card.title)
	else:
		res.research -= upgrade_cost()
		bump("upgrades")
		levels[card.id] = level(card.id) + 1
		var rule: Dictionary = UPGRADES[card.id][2]
		if rule.has("slot"):
			var s := map.build_slot(rule.slot)
			_init_station(s)
			station_added.emit(s)
		message.emit("Upgrade: %s" % card.title)
	_update_labels()


func add_crew(c: Node) -> void:
	crew.append(c)
	crew_changed.emit()
	for at in UNLOCKS:
		var id: String = UNLOCKS[at][0]
		if crew.size() >= at and not unlocked.has(id):
			unlocked[id] = true
			message.emit(UNLOCKS[at][1])
			if id == "shield":
				flare_in = FLARE_EVERY
	if crew.size() >= WIN_CREW and not finished:
		finished = true
		won.emit()


func is_locked(kind: String) -> int:
	match kind:
		"shield", "pit": return 0 if unlocked.has("shield") else SHIELD_AT
		"oven": return 0 if unlocked.has("oven") else OVEN_AT
	return 0


## Whether `s` takes `item` from your hands (or makes more of it); anything else is dropped when you use it.
func accepts(s: Station, item: String) -> bool:
	return s.kind in DESTINATIONS.get(item, []) or MAKES.get(s.kind, "") == item


## Why `actor` can't use `s` right now, or "" if it can.
func blocked_reason(s: Station, actor: Node) -> String:
	var hands: Hands = actor.get_node("Hands")
	if is_locked(s.kind):
		return "Unlocks at %d crew." % is_locked(s.kind)
	match s.kind:
		"bed":
			if res.water < TEND_WATER:
				return "Needs water: melt some ice."
		"electrolyzer":
			if res.water < SPLIT_WATER:
				return "Needs %d water: melt some ice." % SPLIT_WATER
		"melter":
			if not hands.holds("ice"):
				return "Bring ice from the crater drill."
		"lab":
			if not hands.holds("sample"):
				return "Bring moon rocks from an outcrop."
			if hands.holds("sample") and res.water < LAB_WATER:
				return "Needs water to prep the rocks: melt some ice."
		"oven":
			if not hands.holds("sample"):
				return "Bring moon rocks to bake into oxygen."
		"shield":
			if not hands.holds("bag"):
				return "Bring regolith bags from the pit."
		"reactor":
			return "Running: %d steady power." % REACTOR_POWER
		"comms":
			if crew.size() >= MAX_CREW:
				return "The base is full."
			if res.food < crew_cost():
				return "Stock %d food to feed a new crewmate (%d now)." % [crew_cost(), res.food]
	return ""


## The minigame mode the player plays before `finish`, or "" to finish right away.
func minigame(s: Station, actor: Node) -> String:
	return MINIGAMES[s.kind][0] if MINIGAMES.has(s.kind) else ""


## Applies the result of using `s`, by the player after its minigame or by a helper after working.
## `bonus` multiplies what it makes (a flawless minigame).
func finish(s: Station, actor: Node, bonus := 1.0) -> void:
	var hands: Hands = actor.get_node("Hands")
	var top := s.global_position - Vector2(0, s.size.y)
	var tag := "  PERFECT x%d" % bonus if bonus > 1.0 else ""
	match s.kind:
		"solar":
			s.state.dust = 0.0
			bump("cleaned")
			popup.emit(top, "panel clean")
		"drill":
			var n := roundi(ICE_PER_DRILL * mult("bit") * bonus)
			hands.add("ice", n)
			bump("ice")
			popup.emit(top, "+%d ice%s" % [n, tag])
		"bed":
			res.water -= TEND_WATER
			var f := TEND_FOOD * bonus
			res.food += f
			bump("harvested")
			popup.emit(top, "+%s food%s" % [_num(f), tag])
		"outcrop":
			var n := roundi(ROCKS_PER_DIG * bonus)
			hands.add("sample", n)
			bump("dug")
			popup.emit(top, "+%d rocks%s" % [n, tag])
		"pit":
			var n := roundi(BAGS_PER_DIG * bonus)
			hands.add("bag", n)
			bump("bags")
			popup.emit(top, "+%d bags%s" % [n, tag])
		"shield":
			var n := hands.take()
			res.shield += n
			bump("shielded", n)
			popup.emit(top, "shield %d / %d" % [res.shield, shield_need()])
		"melter":
			var w := hands.take() * WATER_PER_ICE
			res.water += w
			bump("melted")
			popup.emit(top, "+%s water" % _num(w))
		"electrolyzer":
			var split := power_ratio()
			var o := SPLIT_O2 * split * bonus
			res.water -= SPLIT_WATER
			split_busy = LAB_BUSY
			res.o2 += o
			bump("split")
			popup.emit(top, "-%d water  +%s air%s" % [SPLIT_WATER, _num(o), tag])
			if split < 1.0:
				message.emit("Low power: the electrolyzer ran at %d%%. Clean or build solar panels." % int(split * 100))
		"oven":
			var n := hands.take()
			var o := n * OVEN_O2 * power_ratio()
			res.o2 += o
			bump("baked", n)
			popup.emit(top, "+%s O2" % _num(o))
		"comms":
			call_crew()
		"lab":
			analyze(s, actor, hands.count if hands.holds("sample") else 0)
	did.emit(s, actor, _result_text(s))
	_update_labels()


## Analyses up to `n` carried rocks, as far as the water lasts; returns how many. Each uses LAB_WATER, and the research
## it gives scales with how much power there is. The player's scan calls this once per hit.
func analyze(s: Station, actor: Node, n: int, bonus := 1.0) -> int:
	var hands: Hands = actor.get_node("Hands")
	if not hands.holds("sample"):
		return 0
	n = mini(n, mini(hands.count, floori(res.water / LAB_WATER)))
	if n <= 0:
		return 0
	hands.take(n)
	res.water -= n * LAB_WATER
	lab_busy = LAB_BUSY
	var r := n * mult("lab_x") * power_ratio() * bonus
	res.research += r
	bump("rocks", n)
	popup.emit(s.global_position - Vector2(0, s.size.y), "+%s research  -%d water" % [_num(r), n * LAB_WATER])
	did.emit(s, actor, _result_text(s))
	_update_labels()
	return n


func _num(v: float) -> String:
	return "%d" % v if is_equal_approx(v, roundf(v)) else "%.1f" % v


func _result_text(_s: Station) -> String:
	return "o2=%.1f water=%.1f food=%.1f research=%d shield=%d power=%.1f/%.1f" % [res.o2, res.water, res.food, res.research, res.shield, power.x, power.y]


## How much each task is wanted right now (0 = not at all), for crew choosing what to do.
func wants(task: String) -> float:
	match task:
		"ice":
			var enough := 6.0 + ICE_ENOUGH * crew.size() * (BREATHE + DRINK) + ICE_ENOUGH * stations_of("bed").size() * BED_WATER
			return 0.0 if res.water >= enough else 0.1 + (1.0 - res.water / enough)
		"air":
			if res.water < SPLIT_WATER + 1.0:
				return 0.0
			var enough := 4.0 + ICE_ENOUGH * crew.size() * BREATHE
			return 0.0 if res.o2 >= enough else 0.2 + (1.0 - res.o2 / enough)
		"harvest":
			if res.water < TEND_WATER + 2.0:
				return 0.0
			return 0.3 + 0.3 * clampf(1.0 - res.food / crew_cost(), 0.0, 1.0)
		"solar":
			var dust: Array = stations_of("solar").map(func(s: Station) -> float: return s.state.dust)
			return dust.max() if not dust.is_empty() and dust.max() > 0.3 else 0.0
		"rocks":
			if res.water < 6.0:
				return 0.0
			return 0.45 if res.research < upgrade_cost() else 0.1
		"shield":
			return 1.0 if unlocked.has("shield") and res.shield < shield_need() else 0.0
	return 0.0


# --- objectives ---------------------------------------------------------------------------------

## [text, station kind to point at, done?]
func objectives() -> Array:
	return [
		["Wipe the dusty solar panels north of the base", "solar", count("cleaned") >= 1],
		["Drill ice in the dark crater south of the base", "drill", count("ice") >= 1],
		["Carry the ice to the Ice melter", "melter", count("melted") >= 1],
		["Split water into air at the Electrolyzer", "electrolyzer", count("split") >= 1],
		["Tend a potato bed in the Greenhouse", "bed", count("harvested") >= 1],
		["Stock %d food in the Greenhouse" % ARRIVAL_FOOD, "bed", res.food >= ARRIVAL_FOOD or crew.size() >= 2],
		["Call your first crewmate at the Comms dish in the hab", "comms", crew.size() >= 2],
		["Dig rocks at a rock outcrop outside, carry them to the Lab", "outcrop", res.research >= 1 or count("upgrades") >= 1],
		["Get %d research to pick your first upgrade" % UPGRADE_COST, "lab", count("upgrades") >= 1],
		["Grow to %d crew. Next crewmate: %d food" % [WIN_CREW, crew_cost()], "", finished],
		["Bonus: keep growing to %d crew. Next crewmate: %d food" % [MAX_CREW, crew_cost()], "", crew.size() >= MAX_CREW],
	]


func current_objective() -> Array:
	var all := objectives()
	while step < all.size() - 1 and all[step][2]:
		step += 1
	if step >= all.size() - 2 and crew.size() < MAX_CREW:
		if can_call():
			return ["Food ready! Call a crewmate at the Comms dish", "comms", false]
		if unlocked.has("shield") and res.shield < shield_need():
			return ["Flares! Fill bags at the Regolith pit, stack them at the Shield wall: %d / %d" % [res.shield, shield_need()], "pit", false]
		var next := ""
		for at in UNLOCKS:
			if crew.size() < at:
				next = "  ·  %s at %d crew" % [UNLOCKS[at][0], at]
				break
		return [all[step][0] + next, all[step][1], false]
	return all[step]


func _update_labels() -> void:
	for s in map.stations:
		if s.interact == null:
			continue
		var text := ""
		var prompt := s.title
		match s.kind:
			"solar": text = "dust %d%%" % int(s.state.dust * 100)
			"bed": text = "%.1f food/min" % (BED_RATE * mult("bed_x") * pow(1.5, level("automation")) * power_ratio()) if res.water > 0.0 else "no water"
			"reactor": text = "ON"
			"lab": text = "research %d/%d" % [res.research, upgrade_cost()]
			"shield": text = "%d / %d" % [res.shield, shield_need()] if not is_locked("shield") else "locked"
			"pit", "oven": text = "" if not is_locked(s.kind) else "locked"
			"comms": text = "READY" if can_call() else "%d / %d food" % [res.food, crew_cost()]
			"note": prompt = "Read note"
		match s.kind:
			"melter": prompt = "Melt ice"
			"lab", "oven": prompt = "Insert into " + s.title.to_lower()
			"bed": prompt = "Tend"
			"solar": prompt = "Wipe panel"
			"drill": prompt = "Drill ice"
			"outcrop": prompt = "Dig rocks"
			"pit": prompt = "Fill bags"
			"shield": prompt = "Stack bags"
			"comms": prompt = "Call a crewmate"
			"electrolyzer": prompt = "Split water"
		if RECIPES.has(s.kind) and s.kind != "reactor":
			prompt += "  (%s)" % RECIPES[s.kind]
		s.set_status(text, prompt)
