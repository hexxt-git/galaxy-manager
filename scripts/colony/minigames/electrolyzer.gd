extends "res://scripts/colony/minigames/skin.gd"

## Electrolyzer: a water tank with two electrodes under inverted glass tubes. Closing the knife switch runs current
## round the wires; bubbles stream off both rods, and gas collects at the top of each tube, twice as much H2 as O2
## (2 H2O -> 2 H2 + O2). The O2 is piped to the AIR gauge, which is the progress.
## Scene coordinates below are art pixels in mg_electrolyzer_tank.png (see art-src/props/mg_electrolyzer_tank.js).

const K := HUD.UI_SCALE
const SCENE_AT := Vector2(24, 20)
const TUBES := [86.0, 166.0]  # H2 (−) tube, O2 (+) tube
const GAS_TOP := 51.0
const O2_FULL := 50.0  # O2 column at full progress; H2 is twice that
const ROD_TOP := 160.0
const WIRES := [
	[Vector2(100, 20), Vector2(36, 20), Vector2(36, 212), Vector2(86, 212), Vector2(86, 200)],
	[Vector2(166, 200), Vector2(166, 212), Vector2(216, 212), Vector2(216, 20), Vector2(152, 20)],
]
const SLOT := Rect2(231, 62, 6, 138)
const SWITCH_PIVOT := Vector2(48, 40)
const PLATE := Rect2(20, 50, 56, 15)
const INK := Color("0d0d12")
const GAS := Color("d8eef2")
const GAS_DARK := Color("a9cbd3")
const SURFACE := Color("8fd0e6")
const BOLT := Color("f2c84b")
const O2 := Color("6fd0d8")
const O2_LIT := Color("b5eef2")

var _tex := {}


func setup(mg: Minigame) -> void:
	super.setup(mg)
	for part in ["tank", "bubble", "spark", "switch", "switch_on", "switch_done"]:
		_tex[part] = ColonyMap.texture(ColonyMap.PROPS + "mg_electrolyzer_%s.png" % part)


func button_center(mg: Minigame) -> Vector2:
	return Vector2(mg.size.x * 0.5, 544)


func button_radius() -> float:
	return 80.0


func draw(mg: Minigame) -> void:
	var on := mg._holding and not mg._done
	mg.draw_set_transform(SCENE_AT, 0.0, Vector2(K, K))
	mg.draw_texture(_tex["tank"], Vector2.ZERO)
	for i in 2:
		_gas(mg, TUBES[i], O2_FULL * (2 - i) * mg._progress)
	if on:
		_current(mg)
		for i in 2:
			_bubbles(mg, TUBES[i], 6 if i == 0 else 3, O2_FULL * (2 - i) * mg._progress)
	_lamp(mg, on)
	var f := roundf(SLOT.size.y * mg._progress)
	mg.draw_rect(Rect2(SLOT.position.x, SLOT.end.y - f, SLOT.size.x, f), O2)
	mg.draw_rect(Rect2(SLOT.position.x, SLOT.end.y - f, 2, f), O2_LIT)
	mg.draw_set_transform(Vector2.ZERO)

	_label(mg, "H2", SCENE_AT + Vector2(56, 76) * K)
	_label(mg, "O2", SCENE_AT + Vector2(196, 76) * K)
	_label(mg, "AIR", SCENE_AT + Vector2(234, 49) * K)
	draw_button(mg)
	draw_flash(mg, Vector2(0, 300))
	draw_fact(mg)


func _gas(mg: Minigame, x: float, depth: float) -> void:
	var d := roundf(depth)
	if d < 1.0:
		return
	mg.draw_rect(Rect2(x - 7, GAS_TOP, 14, d), GAS)
	mg.draw_rect(Rect2(x + 3, GAS_TOP, 4, d), GAS_DARK)
	mg.draw_rect(Rect2(x - 7, GAS_TOP + d, 14, 1), SURFACE)


func _bubbles(mg: Minigame, x: float, count: int, depth: float) -> void:
	var top := GAS_TOP + depth + 2.0
	for k in count:
		var ph := fposmod(mg._t * 1.6 + float(k) / count, 1.0)
		var y := lerpf(ROD_TOP - 2.0, top, ph)
		var dx := roundf(sin(ph * 9.0 + k * 2.0) * 3.0)
		mg.draw_texture(_tex["bubble"], Vector2(x - 3 + dx, y - 3).round())
	if int(mg._t * 14.0) % 2:
		mg.draw_texture(_tex["spark"], Vector2(x - 3, ROD_TOP - 5))


## Pulses of current marching round both wires, out of the − terminal and back into the +.
func _current(mg: Minigame) -> void:
	for wire in WIRES:
		var run := 0.0
		var off := fposmod(mg._t * 60.0, 14.0)
		for j in wire.size() - 1:
			var a: Vector2 = wire[j]
			var b: Vector2 = wire[j + 1]
			var seg := a.distance_to(b)
			var s := fposmod(off - run, 14.0)
			while s < seg:
				var p := a.lerp(b, s / seg).round()
				mg.draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), INK)
				mg.draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), BOLT)
				s += 14.0
			run += seg


func _lamp(mg: Minigame, on: bool) -> void:
	if not (on or mg._done):
		return
	var c := Color("7ed05b") if mg._done else (BOLT if int(mg._t * 10.0) % 3 else Color("fff3b8"))
	mg.draw_rect(Rect2(122, 11, 8, 8), c)
	mg.draw_rect(Rect2(121, 12, 10, 6), c)
	mg.draw_rect(Rect2(123, 12, 2, 2), Color.WHITE)


func _label(mg: Minigame, text: String, centre: Vector2) -> void:
	var at := Vector2(centre.x - 50, centre.y)
	mg.draw_string_outline(ColonyMap.FONT, at, text, HORIZONTAL_ALIGNMENT_CENTER, 100, 18, 6, INK)
	mg.draw_string(ColonyMap.FONT, at, text, HORIZONTAL_ALIGNMENT_CENTER, 100, 18, Color.WHITE)


func draw_button(mg: Minigame) -> void:
	var face := "switch_done" if mg._done else ("switch_on" if pressed(mg) else "switch")
	var tl := button_center(mg) - SWITCH_PIVOT * K
	mg.draw_set_transform(tl, 0.0, Vector2(K, K))
	mg.draw_texture(_tex[face], Vector2.ZERO)
	mg.draw_set_transform(Vector2.ZERO)
	var text := "DONE" if mg._done else "HOLD"
	var col := Color("7ed957") if mg._done else (Color("ffd27a") if pressed(mg) else Color.WHITE)
	mg.draw_string(ColonyMap.FONT, tl + Vector2(PLATE.position.x, PLATE.end.y - 3) * K, text, HORIZONTAL_ALIGNMENT_CENTER, PLATE.size.x * K, 22, col)
