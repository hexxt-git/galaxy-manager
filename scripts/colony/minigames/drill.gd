extends "res://scripts/colony/minigames/skin.gd"

## Ice drill: a cut-away of the crater floor. Holding the lever drives the auger down through icy regolith (depth is
## progress), ice rides up into the hopper, the bit glows as it heats and vents vapour near the red zone.
## Scene coordinates below are art pixels in mg_drill_scene.png (see art-src/props/mg_drill_scene.js).

const K := HUD.UI_SCALE
const SCENE_AT := Vector2(24, 20)
const CX := 126.0
const SURFACE := 70.0
const TIP := Vector2(80, 198)  # bit tip depth at progress 0 and 1
const DEPTH_SLOT := Rect2(13, 87, 6, 112)
const HEAT_SLOT := Rect2(233, 87, 6, 99)
const LEVER_SIZE := Vector2(96, 74)
const LEVER_PIVOT := Vector2(48, 40)  # where the lever sprite sits on button_center
const PLATE := Rect2(20, 50, 56, 15)
## Hopper heap, back to front; the last four only show for a perfect (double) run.
const PILE := [Vector2(170, 38), Vector2(181, 38), Vector2(192, 38), Vector2(203, 38), Vector2(175, 30), Vector2(186, 30),
	Vector2(197, 30), Vector2(181, 22), Vector2(192, 22), Vector2(186, 14), Vector2(160, 41), Vector2(210, 40),
	Vector2(165, 33), Vector2(206, 31)]
const INK := Color("0d0d12")
const HOLE := Color("262833")
const ROD := Color("8a909c")
const ROD_DARK := Color("555a68")

var _tex := {}
var _spin := 0.0
var _last_t := 0.0


func setup(mg: Minigame) -> void:
	super.setup(mg)
	for part in ["scene", "bit", "bit_warm", "bit_hot", "chunk", "puff", "lever", "lever_down", "lever_done"]:
		_tex[part] = ColonyMap.texture(ColonyMap.PROPS + "mg_drill_%s.png" % part)


func button_center(mg: Minigame) -> Vector2:
	return Vector2(mg.size.x * 0.5, 540)


func button_radius() -> float:
	return 80.0


func draw(mg: Minigame) -> void:
	var dt := clampf(mg._t - _last_t, 0.0, 0.1)
	_last_t = mg._t
	var drilling := mg._holding and not mg._done
	if drilling:
		_spin += dt * 40.0
	var tip := lerpf(TIP.x, TIP.y, mg._progress)
	var shake := Vector2(1, 0) * float(int(mg._t * 30.0) % 2) if drilling else Vector2.ZERO

	mg.draw_set_transform(SCENE_AT, 0.0, Vector2(K, K))
	mg.draw_texture(_tex["scene"], Vector2.ZERO)
	mg.draw_rect(Rect2(CX - 8, SURFACE + 1, 16, tip - SURFACE - 8), INK)
	mg.draw_rect(Rect2(CX - 7, SURFACE + 1, 14, tip - SURFACE - 8), HOLE)
	if mg._heat > 0.4:
		var g := maxf(SURFACE + 1.0, tip - 36.0)
		mg.draw_rect(Rect2(CX - 7, g, 14, tip - 7.0 - g), Color("7a3524") if mg._heat > 0.75 else Color("4f2f33"))
	var top := 36.0
	var bit_top := tip - 25.0
	mg.draw_rect(Rect2(Vector2(CX - 4, top) + shake, Vector2(8, bit_top - top + 2)), INK)
	mg.draw_rect(Rect2(Vector2(CX - 3, top) + shake, Vector2(6, bit_top - top + 2)), ROD)
	mg.draw_rect(Rect2(Vector2(CX + 1, top) + shake, Vector2(2, bit_top - top + 2)), ROD_DARK)
	var y := top + fposmod(_spin, 6.0)
	while y < bit_top:
		mg.draw_rect(Rect2(Vector2(CX - 3, y) + shake, Vector2(6, 1)), INK)
		y += 6.0
	mg.draw_texture(_tex[_bit(mg)], Vector2(CX - 8, bit_top) + shake)

	if drilling:
		for i in 3:
			var ph := fposmod(mg._t * 1.1 + i / 3.0, 1.0)
			mg.draw_texture(_tex["chunk"], Vector2(CX - 7, lerpf(tip - 18.0, SURFACE - 10.0, ph)).round())
	var heap := PILE.size() if mg._done and mg.flawless else mini(int(mg._progress * 10.0 + 0.001), 10)
	var order := range(10, heap) + range(mini(heap, 10))
	for i in order:
		mg.draw_texture(_tex["chunk"], PILE[i])
	_draw_vapour(mg)
	_draw_gauges(mg)
	mg.draw_set_transform(Vector2.ZERO)

	_label(mg, "ICE", SCENE_AT + Vector2(16, 76) * K)
	_label(mg, "HEAT", SCENE_AT + Vector2(236, 76) * K)
	draw_button(mg)
	draw_flash(mg, Vector2(0, 300))
	draw_fact(mg)


func _bit(mg: Minigame) -> String:
	if mg._heat > 0.75:
		return "bit_hot" if int(mg._t * 12.0) % 3 else "bit_warm"
	return "bit_warm" if mg._heat > 0.4 else "bit"


## Ice flashing to vapour: a thin wisp out of the hole once the bit runs hot, a burst after an overheat.
func _draw_vapour(mg: Minigame) -> void:
	var burst: bool = mg._flash == "Overheated!" and mg._flash_t > 0.0
	var streams := 3 if burst else (1 if mg._heat > 0.55 and not mg._done else 0)
	for i in streams * 2:
		var ph := fposmod(mg._t * 1.4 + i * 0.37, 1.0)
		var x := CX - 13.0 + (i % 3 - 1) * 10.0 * ph
		mg.draw_texture(_tex["puff"], Vector2(x, SURFACE - 16.0 - ph * 34.0).round(), Color(1, 1, 1, 1.0 - ph * ph))


func _draw_gauges(mg: Minigame) -> void:
	var d := roundf(DEPTH_SLOT.size.y * mg._progress)
	mg.draw_rect(Rect2(DEPTH_SLOT.position, Vector2(6, d)), Color("7ed05b"))
	mg.draw_rect(Rect2(DEPTH_SLOT.position, Vector2(2, d)), Color("b2e58d"))
	if mg._heat <= 0.01:
		return
	var red := mg._heat > 0.75
	var hot := Color("e0503c") if red else Color("de8641")
	var h := roundf(HEAT_SLOT.size.y * minf(mg._heat, 1.0))
	if red and int(mg._t * 8.0) % 2:
		hot = Color("ff8a7a")
	mg.draw_rect(Rect2(HEAT_SLOT.end.x - 6, HEAT_SLOT.end.y - h, 6, h + 3), hot)
	mg.draw_rect(Rect2(HEAT_SLOT.end.x - 6, HEAT_SLOT.end.y - h, 2, h + 3), Color("e9ae70"))
	mg.draw_rect(Rect2(232, 189, 8, 10), hot)
	mg.draw_rect(Rect2(231, 191, 10, 6), hot)


func _label(mg: Minigame, text: String, centre: Vector2) -> void:
	var at := Vector2(centre.x - 50, centre.y)
	mg.draw_string_outline(ColonyMap.FONT, at, text, HORIZONTAL_ALIGNMENT_CENTER, 100, 18, 6, INK)
	mg.draw_string(ColonyMap.FONT, at, text, HORIZONTAL_ALIGNMENT_CENTER, 100, 18, Color.WHITE)


func draw_button(mg: Minigame) -> void:
	var face := "lever_done" if mg._done else ("lever_down" if pressed(mg) else "lever")
	var tl := button_center(mg) - LEVER_PIVOT * K
	mg.draw_set_transform(tl, 0.0, Vector2(K, K))
	mg.draw_texture(_tex[face], Vector2.ZERO)
	mg.draw_set_transform(Vector2.ZERO)
	var text := "DONE" if mg._done else "HOLD"
	var col := Color("7ed957") if mg._done else (Color("ffd27a") if pressed(mg) else Color.WHITE)
	mg.draw_string(ColonyMap.FONT, tl + Vector2(PLATE.position.x, PLATE.end.y - 3) * K, text, HORIZONTAL_ALIGNMENT_CENTER, PLATE.size.x * K, 22, col)
