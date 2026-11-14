extends Control

enum { BREAD, O2, TECH, PEOPLE }
enum { FROM_TAP, FROM_WORKERS, FROM_OTHER }

const NAMES := ["bread", "O2", "tech", "people"]
const SOURCES := ["Wheat", "Oxygen", "Tech", "People"]
const COLORS: Array[Color] = [
	Color(1.0, 0.7, 0.22), Color(0.3, 0.75, 1.0), Color(0.62, 0.45, 0.98), Color(1.0, 0.45, 0.55)]
const ICONS := [CircleButton.Icon.WHEAT, CircleButton.Icon.O2, CircleButton.Icon.GEAR, CircleButton.Icon.PERSON]
const UPGRADES := ["Greenhouse", "Electrolyzer", "Lab"]
const HOME_COLOR := Color(0.42, 0.8, 0.3)
const HOME_SHIRT := Color(0.86, 0.89, 0.96)
const OUTLINE := Color(0.05, 0.11, 0.27)
const PANEL := Color(0.12, 0.24, 0.52)
const DENY := Color(1, 0.55, 0.55)

const SUFFIXES := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

const TAP_BASE := 1.0
## Output per second of one colonist assigned to bread, O2 or tech, before upgrades.
const WORKER_BASE := 5.0
## Each upgrade level multiplies taps by TAP_GROWTH but workers only by WORKER_GROWTH, and adds
## TAP_SHARE of the workers' per-second output to every tap, so tapping keeps up as the colony grows.
const TAP_GROWTH := 2.0
const WORKER_GROWTH := 1.5
const TAP_SHARE := 0.05
## Bread for the first colonist; each one after costs PERSON_GROWTH times more.
const PERSON_BASE := 50.0
const PERSON_GROWTH := 1.15
const START_O2 := 100.0
## New colonists per second from one colonist assigned to People (each still costs bread).
const BREEDER_RATE := 0.2
## O2 each colonist breathes per second; the colony is lost when O2 runs out.
const BREATHE := 2.0
const UPGRADE_BASE := 100.0
const UPGRADE_GROWTH := 4.0
## The per-second readouts measure what actually changed (taps, workers, breathing) over this
## many seconds, so mashing shows up in them. Spending on colonists and upgrades isn't counted.
const RATE_WINDOW := 3.0
const RATE_BUCKETS := 12
## Screen edges start glowing red when O2 would run out within this many seconds.
const LOW_O2_SECONDS := 15.0

var stock := [0.0, START_O2, 0.0]
var people := 0
var jobs := [0, 0, 0, 0]
var levels := [0, 0, 0]

var _shown := [0.0, START_O2, 0.0]
var _rate := [0.0, 0.0, 0.0]
var _tap_share := [-1.0, -1.0, -1.0]
## [source][resource][bucket]: income over the last RATE_WINDOW seconds, split by where it came from.
var _buckets := []
var _bucket := 0
var _bucket_time := 0.0
var _breed := 0.0
var _time := 0.0
var _peak := 0
var _over := false

var _nodes: Array[CircleButton] = []
var _captions: Array[Label] = []
var _home: CircleButton
var _chips: Array[Dictionary] = []
var _hint: Label
var _hud: GridContainer
var _vignette: Control

var _sheet: Control
var _sheet_panel: PanelContainer
var _sheet_sub: Label
var _jobs_page: VBoxContainer
var _upgrades_page: VBoxContainer
var _tab_jobs: CircleButton
var _tab_upgrades: CircleButton
var _home_crew: Crew
var _job_cards: Array[Dictionary] = []
var _upgrade_rows: Array[Dictionary] = []

@onready var _stars: Control = $Starfield
@onready var _links: Control = $Links


func _ready() -> void:
	for source in 3:
		var per_resource := []
		for i in 3:
			var b := []
			b.resize(RATE_BUCKETS)
			b.fill(0.0)
			per_resource.append(b)
		_buckets.append(per_resource)

	_build_hud()
	for i in 4:
		var b := _circle(ICONS[i], COLORS[i], SOURCES[i])
		b.tapped.connect(_on_resource_tapped.bind(i))
		if i == PEOPLE:
			b.denied.connect(func(): _deny("Need %s bread" % _fmt(_person_cost()), b))
		add_child(b)
		_nodes.append(b)
		var cap := _label("", 24, 6)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.size = Vector2(340, 70)
		add_child(cap)
		_captions.append(cap)
	_home = _circle(CircleButton.Icon.HOUSE, HOME_COLOR, "Home")
	_home.tapped.connect(_open_sheet)
	add_child(_home)

	_hint = _label("", 28)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)

	_links.colors = COLORS
	_vignette = preload("res://scripts/vignette.gd").new()
	_vignette.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_vignette)
	_build_sheet()
	resized.connect(_layout)
	_layout()
	_refresh()


func _process(delta: float) -> void:
	for i in 3:
		_shown[i] = lerpf(_shown[i], stock[i], 1.0 - exp(-14.0 * delta))
	_measure_rates(delta)
	if _over:
		_refresh()
		return
	if people > 0:
		_time += delta
	for i in 3:
		_gain(i, _worker_rate(i) * jobs[i] * delta, FROM_WORKERS)

	_breed += jobs[PEOPLE] * BREEDER_RATE * delta
	while _breed >= 1.0 and _can_afford_person():
		_breed -= 1.0
		_add_person(_nodes[PEOPLE])
	_breed = minf(_breed, 1.0)

	_gain(O2, -minf(people * BREATHE * delta, stock[O2]), FROM_OTHER)
	_refresh()
	if people > 0 and stock[O2] <= 0.0:
		_game_over()


# --- rules --------------------------------------------------------------------------------------

func _tap_mult(i: int) -> float:
	return pow(TAP_GROWTH, levels[i])


func _worker_mult(i: int) -> float:
	return pow(WORKER_GROWTH, levels[i])


func _worker_rate(i: int) -> float:
	return WORKER_BASE * _worker_mult(i)


func _tap_bonus_share(i: int) -> float:
	return TAP_SHARE * levels[i]


func _tap_gain(i: int) -> float:
	return TAP_BASE * _tap_mult(i) + _tap_bonus_share(i) * _worker_rate(i) * jobs[i]


func _person_cost() -> float:
	return roundf(PERSON_BASE * pow(PERSON_GROWTH, people))


func _upgrade_cost(i: int) -> float:
	return roundf(UPGRADE_BASE * pow(UPGRADE_GROWTH, levels[i]))


func _can_afford_person() -> bool:
	return stock[BREAD] >= _person_cost()


func _idle() -> int:
	return people - jobs[BREAD] - jobs[O2] - jobs[TECH] - jobs[PEOPLE]


func _gain(i: int, amount: float, source: int) -> void:
	stock[i] += amount
	_buckets[source][i][_bucket] += amount


func _measure_rates(delta: float) -> void:
	_bucket_time += delta
	var step := RATE_WINDOW / RATE_BUCKETS
	while _bucket_time >= step:
		_bucket_time -= step
		_bucket = (_bucket + 1) % RATE_BUCKETS
		for per_resource in _buckets:
			for b in per_resource:
				b[_bucket] = 0.0
	var k := 1.0 - exp(-3.0 * delta)
	for i in 3:
		var sums := [0.0, 0.0, 0.0]
		for source in 3:
			for v: float in _buckets[source][i]:
				sums[source] += v
		_rate[i] = lerpf(_rate[i], (sums[0] + sums[1] + sums[2]) / RATE_WINDOW, k)
		var income: float = sums[FROM_TAP] + sums[FROM_WORKERS]
		if income <= 0.01:
			_tap_share[i] = -1.0
		elif _tap_share[i] < 0.0:
			_tap_share[i] = sums[FROM_TAP] / income
		else:
			_tap_share[i] = lerpf(_tap_share[i], sums[FROM_TAP] / income, k)


## 0 when O2 is safe, rising to 1 as it is about to run out at the measured rate.
func _o2_danger() -> float:
	var net: float = _rate[O2]
	if people == 0 or net >= 0.0:
		return 0.0
	return clampf(1.0 - stock[O2] / -net / LOW_O2_SECONDS, 0.0, 1.0)


func _on_resource_tapped(i: int) -> void:
	if _over:
		return
	if i == PEOPLE:
		if _can_afford_person():
			_add_person(_nodes[PEOPLE])
		return
	var gain := _tap_gain(i)
	_gain(i, gain, FROM_TAP)
	_pop(_chips[i].count)
	_float("+" + _fmt(gain), _nodes[i], COLORS[i].lightened(0.4))


func _add_person(from: Control) -> void:
	stock[BREAD] -= _person_cost()
	people += 1
	_peak = maxi(_peak, people)
	_pop(_chips[PEOPLE].count)
	_float("+1", from, COLORS[PEOPLE].lightened(0.4))


func _assign(i: int) -> void:
	var card: Dictionary = _job_cards[i]
	if _idle() <= 0:
		_deny("No one at home", card.crew)
		return
	var from := _slot(_home_crew, _idle() - 1)
	jobs[i] += 1
	_fly(from, _slot(card.crew, jobs[i] - 1), COLORS[i])
	_refresh()


func _unassign(i: int) -> void:
	if jobs[i] <= 0:
		return
	var from := _slot(_job_cards[i].crew, jobs[i] - 1)
	jobs[i] -= 1
	_fly(from, _slot(_home_crew, _idle() - 1), HOME_SHIRT)
	_refresh()


func _buy_upgrade(i: int) -> void:
	var cost := _upgrade_cost(i)
	if stock[TECH] < cost:
		return
	stock[TECH] -= cost
	levels[i] += 1
	_float("Tap x%s!" % _fmt(_tap_mult(i)), _upgrade_rows[i].buy, COLORS[i].lightened(0.4), 40)
	_refresh()


# --- view ---------------------------------------------------------------------------------------

func _layout() -> void:
	var w := size.x
	var h := size.y
	var top := _safe_top() + 16.0
	_hud.position = Vector2(12, top)
	_hud.size = Vector2(w - 24, 0)
	var hud_bottom := top + _hud.get_combined_minimum_size().y
	var field_top := hud_bottom + 64.0
	var center := Vector2(w * 0.5, field_top + (h - field_top - 110.0) * 0.5)
	var dx := w * 0.28
	var dy := minf((h - field_top) * 0.3, dx * 1.5)
	var d := minf(minf(w * 0.32, dy * 0.95), 250.0)
	var offsets := [Vector2(-dx, -dy), Vector2(dx, -dy), Vector2(dx, dy), Vector2(-dx, dy)]
	var ends: Array[Vector2] = []
	for i in 4:
		var p: Vector2 = center + offsets[i]
		_nodes[i].size = Vector2(d, d)
		_nodes[i].position = p - _nodes[i].size * 0.5
		_captions[i].position = Vector2(p.x - _captions[i].size.x * 0.5, p.y + d * 0.5 + 4.0)
		ends.append(p)
	var hd := d * 1.15
	_home.size = Vector2(hd, hd)
	_home.position = center - _home.size * 0.5
	_links.hub = center
	_links.ends = ends
	_stars.burst_center = center / size
	_hint.size = Vector2(w, 40)
	_hint.position = Vector2(0, hud_bottom + 14.0)
	if _sheet.visible:
		_fit_sheet()


func _safe_top() -> float:
	var safe := DisplayServer.get_display_safe_area()
	var window := DisplayServer.window_get_size()
	if window.y <= 0:
		return 24.0
	return clampf(safe.position.y * size.y / window.y, 24.0, 140.0)


func _refresh() -> void:
	var idle := _idle()
	for i in 4:
		_nodes[i].badge = str(jobs[i]) if jobs[i] > 0 else ""
	for i in 3:
		var text := "+%s / tap" % _fmt(_tap_gain(i))
		if jobs[i] > 0:
			text += "\n+%s/s workers" % _fmt(_worker_rate(i) * jobs[i])
		_captions[i].text = text
	_captions[PEOPLE].text = "+1 person\n-%s bread" % _fmt(_person_cost())
	_home.badge = str(idle) if idle > 0 else ""
	_nodes[PEOPLE].disabled = not _can_afford_person()
	_links.flows = jobs

	var danger := _o2_danger()
	_vignette.intensity = danger
	for i in 3:
		var rate: float = _rate[i]
		_chips[i].count.text = _fmt(floorf(_shown[i] + 0.01))
		_chips[i].rate.text = ("+" if rate >= 0.0 else "-") + _fmt(absf(rate)) + "/s"
		_chips[i].count.add_theme_color_override("font_color",
			Color.WHITE.lerp(Color(1, 0.35, 0.35), danger) if i == O2 else Color.WHITE)
		_chips[i].rate.add_theme_color_override("font_color",
			Color(1, 0.6, 0.6) if rate < -0.05 else Color(0.7, 1, 0.7) if rate > 0.05 else Color(0.75, 0.8, 0.95))
		_chips[i].bar.tap_share = _tap_share[i]
	_chips[PEOPLE].count.text = _fmt(people)
	_chips[PEOPLE].rate.text = "%s at home" % _fmt(idle)

	if _over:
		_hint.text = ""
	elif people == 0:
		_hint.text = "Bake %s bread, then make a colonist!" % _fmt(_person_cost())
	elif danger > 0.0:
		_hint.text = "Oxygen running out! Tap Oxygen!"
	elif idle > 0:
		_hint.text = "Tap Home to give colonists jobs"
	else:
		_hint.text = ""

	if not _sheet.visible:
		return
	_sheet_sub.text = "%s colonist%s · %s at home" % [_fmt(people), "" if people == 1 else "s", _fmt(idle)]
	_home_crew.count = idle
	for i in 4:
		var card: Dictionary = _job_cards[i]
		card.crew.count = jobs[i]
		card.detail.text = _job_detail(i)
		card.minus.disabled = jobs[i] <= 0
	for i in 3:
		var row: Dictionary = _upgrade_rows[i]
		var cost := _upgrade_cost(i)
		row.title.text = "%s  Lv %d" % [UPGRADES[i], levels[i]]
		row.tap.text = "Tap  x%s → x%s   +%d%% → +%d%% of workers" % [
			_fmt(_tap_mult(i)), _fmt(_tap_mult(i) * TAP_GROWTH),
			roundi(_tap_bonus_share(i) * 100.0), roundi((_tap_bonus_share(i) + TAP_SHARE) * 100.0)]
		row.workers.text = "Workers  x%s → x%s" % [_fmt(_worker_mult(i)), _fmt(_worker_mult(i) * WORKER_GROWTH)]
		row.buy.text = _fmt(cost)
		row.buy.disabled = stock[TECH] < cost


func _job_detail(i: int) -> String:
	if i == PEOPLE:
		return "+1 colonist / %ds each" % roundi(1.0 / BREEDER_RATE)
	return "+%s %s/s each" % [_fmt(_worker_rate(i)), NAMES[i]]


## Idle-game style: 1.25K, 34.5M, 789B.
func _fmt(v: float) -> String:
	var a := absf(v)
	if a < 1000.0:
		return str(int(v)) if a >= 10.0 or v == floorf(v) else "%.1f" % v
	var tier := mini(int(floor(log(a) / log(1000.0) + 1e-9)), SUFFIXES.size() - 1)
	var x := v / pow(1000.0, tier)
	var pattern := "%.2f" if absf(x) < 10.0 else "%.1f" if absf(x) < 100.0 else "%.0f"
	return (pattern % x) + SUFFIXES[tier]


func _build_hud() -> void:
	_hud = GridContainer.new()
	_hud.columns = 2
	_hud.add_theme_constant_override("h_separation", 12)
	_hud.add_theme_constant_override("v_separation", 12)
	_hud.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_hud)
	for i in 4:
		var chip := PanelContainer.new()
		chip.size_flags_horizontal = SIZE_EXPAND_FILL
		chip.mouse_filter = MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", _box(Color(OUTLINE, 0.6), 60, 8, Vector2(8, 8)))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		chip.add_child(row)
		var ic := _circle(ICONS[i], COLORS[i], "", 84)
		ic.passive = true
		row.add_child(ic)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", -6)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(col)
		var count := _label("0", 46, 12)
		var rate := _label("", 22, 6)
		col.add_child(count)
		col.add_child(rate)
		var chip_info := { count = count, rate = rate }
		if i != PEOPLE:
			var bar: Control = preload("res://scripts/split_bar.gd").new()
			bar.color = COLORS[i]
			col.add_child(bar)
			chip_info.bar = bar
		_hud.add_child(chip)
		_chips.append(chip_info)


func _build_sheet() -> void:
	_sheet = Control.new()
	_sheet.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_sheet.visible = false
	add_child(_sheet)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.05, 0.55)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventScreenTouch and e.pressed:
			_close_sheet())
	_sheet.add_child(dim)

	_sheet_panel = PanelContainer.new()
	_sheet_panel.mouse_filter = MOUSE_FILTER_STOP
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL
	box.border_color = OUTLINE
	box.border_width_top = 6
	box.border_width_left = 6
	box.border_width_right = 6
	box.corner_radius_top_left = 56
	box.corner_radius_top_right = 56
	box.content_margin_left = 28
	box.content_margin_right = 28
	box.content_margin_top = 28
	box.content_margin_bottom = 56
	_sheet_panel.add_theme_stylebox_override("panel", box)
	_sheet.add_child(_sheet_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	_sheet_panel.add_child(v)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	v.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", -4)
	header.add_child(titles)
	titles.add_child(_label("Colony", 52, 12))
	_sheet_sub = _label("", 22, 6)
	titles.add_child(_sheet_sub)
	_tab_jobs = _circle(CircleButton.Icon.PERSON, COLORS[PEOPLE], "", 84)
	_tab_jobs.tapped.connect(_show_tab.bind(true))
	header.add_child(_tab_jobs)
	_tab_upgrades = _circle(CircleButton.Icon.GEAR, COLORS[TECH], "", 84)
	_tab_upgrades.tapped.connect(_show_tab.bind(false))
	header.add_child(_tab_upgrades)
	var close := _circle(CircleButton.Icon.CLOSE, Color(1, 0.4, 0.42), "", 84)
	close.tapped.connect(_close_sheet)
	header.add_child(close)

	_jobs_page = VBoxContainer.new()
	_jobs_page.add_theme_constant_override("separation", 12)
	v.add_child(_jobs_page)
	_build_jobs_page()

	_upgrades_page = VBoxContainer.new()
	_upgrades_page.add_theme_constant_override("separation", 14)
	v.add_child(_upgrades_page)
	_build_upgrades_page()
	_show_tab(true)


func _build_jobs_page() -> void:
	var home := PanelContainer.new()
	home.mouse_filter = MOUSE_FILTER_IGNORE
	home.add_theme_stylebox_override("panel", _box(Color(HOME_COLOR, 0.22), 32, 3, Vector2(14, 10)))
	_jobs_page.add_child(home)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	home.add_child(row)
	var ic := _circle(CircleButton.Icon.HOUSE, HOME_COLOR, "", 76)
	ic.passive = true
	row.add_child(ic)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	col.add_child(_label("At home", 28))
	_home_crew = Crew.new()
	_home_crew.shirt = HOME_SHIRT
	_home_crew.token = 44.0
	_home_crew.rows = 2
	_home_crew.empty_text = "Everyone is working"
	col.add_child(_home_crew)

	var tip := _label("Tap a job to send someone from home", 22, 6)
	tip.add_theme_color_override("font_color", Color(0.78, 0.85, 1.0))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_jobs_page.add_child(tip)

	for i in 4:
		var card := PanelContainer.new()
		card.mouse_filter = MOUSE_FILTER_STOP
		card.add_theme_stylebox_override("panel", _box(Color(COLORS[i], 0.18), 32, 3, Vector2(14, 10)))
		card.gui_input.connect(func(e: InputEvent):
			if e is InputEventScreenTouch and e.pressed and not _over:
				_assign(i))
		_jobs_page.add_child(card)
		var crow := HBoxContainer.new()
		crow.add_theme_constant_override("separation", 14)
		card.add_child(crow)
		var cic := _circle(ICONS[i], COLORS[i], "", 76)
		cic.passive = true
		crow.add_child(cic)
		var ccol := VBoxContainer.new()
		ccol.size_flags_horizontal = SIZE_EXPAND_FILL
		ccol.add_theme_constant_override("separation", 0)
		crow.add_child(ccol)
		var top := HBoxContainer.new()
		ccol.add_child(top)
		var job_name := _label(SOURCES[i], 28)
		job_name.size_flags_horizontal = SIZE_EXPAND_FILL
		top.add_child(job_name)
		var detail := _label("", 20, 4)
		detail.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
		top.add_child(detail)
		var crew := Crew.new()
		crew.shirt = COLORS[i]
		crew.token = 40.0
		crew.empty_text = "Tap to assign"
		ccol.add_child(crew)
		var minus := _circle(CircleButton.Icon.MINUS, Color(1, 0.4, 0.42), "", 68)
		minus.tapped.connect(_unassign.bind(i))
		crow.add_child(minus)
		_job_cards.append({ crew = crew, detail = detail, minus = minus })


func _build_upgrades_page() -> void:
	var tip := _label("Upgrades boost tapping more than workers", 22, 6)
	tip.add_theme_color_override("font_color", Color(0.78, 0.85, 1.0))
	_upgrades_page.add_child(tip)
	for i in 3:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		_upgrades_page.add_child(row)
		var ic := _circle(ICONS[i], COLORS[i], "", 76)
		ic.passive = true
		row.add_child(ic)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", -2)
		row.add_child(col)
		var title := _label(UPGRADES[i], 30)
		var tap := _label("", 20, 4)
		tap.add_theme_color_override("font_color", Color(1, 0.93, 0.6))
		var workers := _label("", 20, 4)
		workers.add_theme_color_override("font_color", Color(0.78, 0.85, 1.0))
		col.add_child(title)
		col.add_child(tap)
		col.add_child(workers)
		var buy := _circle(CircleButton.Icon.NONE, COLORS[TECH], "", 112)
		buy.tapped.connect(_buy_upgrade.bind(i))
		buy.denied.connect(func(): _deny("Need %s tech" % _fmt(_upgrade_cost(i)), buy))
		row.add_child(buy)
		_upgrade_rows.append({ title = title, tap = tap, workers = workers, buy = buy })


func _show_tab(jobs_tab: bool) -> void:
	_jobs_page.visible = jobs_tab
	_upgrades_page.visible = not jobs_tab
	_tab_jobs.face = COLORS[PEOPLE] if jobs_tab else COLORS[PEOPLE].darkened(0.45)
	_tab_upgrades.face = COLORS[TECH] if not jobs_tab else COLORS[TECH].darkened(0.45)
	if _sheet.visible:
		_refresh()
		_fit_sheet()


func _fit_sheet() -> void:
	var h := _sheet_panel.get_combined_minimum_size().y
	_sheet_panel.size = Vector2(size.x, h)
	_sheet_panel.position = Vector2(0, size.y - h)


func _open_sheet() -> void:
	if _over:
		return
	_sheet.visible = true
	_refresh()
	_fit_sheet()
	var target := _sheet_panel.position.y
	_sheet.modulate.a = 0.0
	_sheet_panel.position.y = size.y
	var t := create_tween().set_parallel()
	t.tween_property(_sheet, "modulate:a", 1.0, 0.15)
	t.tween_property(_sheet_panel, "position:y", target, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close_sheet() -> void:
	var t := create_tween().set_parallel()
	t.tween_property(_sheet, "modulate:a", 0.0, 0.18)
	t.tween_property(_sheet_panel, "position:y", size.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func(): _sheet.visible = false)


## Where person `index` stands in `crew`, in global coordinates.
func _slot(crew: Crew, index: int) -> Vector2:
	return crew.get_global_transform() * crew.slot_center(index)


## A colonist hopping from one crew to another.
func _fly(from: Vector2, to: Vector2, shirt: Color) -> void:
	var token := Crew.new()
	token.count = 1
	token.shirt = shirt
	token.token = 44.0
	token.size = Vector2(44, 44)
	token.pivot_offset = token.size * 0.5
	_sheet.add_child(token)
	token.global_position = from - token.size * 0.5
	var t := create_tween().set_parallel()
	t.tween_property(token, "global_position", to - token.size * 0.5, 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(token, "scale", Vector2(1.4, 1.4), 0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(token, "scale", Vector2.ONE, 0.18).set_delay(0.17)
	t.chain().tween_callback(token.queue_free)


func _deny(text: String, over: Control) -> void:
	if not _over:
		_float(text, over, DENY, 34)


func _game_over() -> void:
	_over = true
	_hint.text = ""
	if _sheet.visible:
		_close_sheet()
	var cover := ColorRect.new()
	cover.color = Color(0, 0, 0.05, 0.75)
	cover.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(cover)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 24)
	v.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	cover.add_child(v)
	var title := _label("Out of oxygen!", 64, 14)
	title.add_theme_color_override("font_color", COLORS[O2].lightened(0.3))
	var stats := _label("Colony survived %d:%02d\nPeak population: %s" % [int(_time) / 60, int(_time) % 60, _fmt(_peak)], 36)
	for l: Label in [title, stats]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var retry := _circle(CircleButton.Icon.HOUSE, HOME_COLOR, "Retry", 220)
	retry.size_flags_horizontal = SIZE_SHRINK_CENTER
	retry.tapped.connect(get_tree().reload_current_scene)
	v.add_child(retry)
	cover.modulate.a = 0.0
	create_tween().tween_property(cover, "modulate:a", 1.0, 0.4)


func _box(bg: Color, radius: int, border: int, margin: Vector2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = Color(OUTLINE, 0.7)
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.content_margin_left = margin.x
	box.content_margin_right = margin.x
	box.content_margin_top = margin.y
	box.content_margin_bottom = margin.y
	return box


func _circle(icon: CircleButton.Icon, color: Color, text: String, d := 0.0) -> CircleButton:
	var b := CircleButton.new()
	b.icon = icon
	b.face = color
	b.text = text
	if d > 0.0:
		b.custom_minimum_size = Vector2(d, d)
		b.size_flags_vertical = SIZE_SHRINK_CENTER
	return b


func _label(text: String, font_size: int, outline := 8) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_outline_color", OUTLINE)
	return l


func _pop(l: Label) -> void:
	l.pivot_offset = Vector2(0, l.size.y * 0.5)
	l.scale = Vector2(1.18, 1.18)
	create_tween().tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _float(text: String, over: Control, color: Color, font_size := 56) -> void:
	var l := _label(text, font_size, 10)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	l.reset_size()
	var c := over.get_global_rect().get_center()
	l.position = c - l.size * 0.5 + Vector2(randf_range(-50, 50), -over.size.y * 0.35)
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(0.6, 0.6)
	var t := create_tween().set_parallel()
	t.tween_property(l, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "position:y", l.position.y - 110.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.45)
	t.chain().tween_callback(l.queue_free)
