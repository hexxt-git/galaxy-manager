extends "res://scripts/colony/minigames/skin.gd"

## Lab spectrometer: a scan line sweeps a rock's spectrum; the green band is the mineral's absorption line.
## Each hit lights one of the goal lamps on the scanner base.

const K := 2  # HUD.UI_SCALE
const SCREEN_AT := Vector2(12, 12)
const GRAPH := Rect2(44, 44, 464, 108)  # inside the screen sprite's display hole
const PITCH := 8
const BAR_W := 6
const SCANNER_AT := Vector2(106, 198)
const LAMP_Y := 65  # art px, on the scanner's front band
const BEAM := Vector2(306, 244)  # lens bottom, screen px
const BEAM_LEN := 20

const GRID := Color("34525c")
const TEAL := Color("71c8cf")
const BAND_BG := Color("2f5e45")
const GREEN := Color("7ed957")
const MISS := Color("ff8a7a")
const INK := Color("0d0d12")

var _screen := ColonyMap.texture(ColonyMap.PROPS + "mg_lab_screen.png")
var _scanner := ColonyMap.texture(ColonyMap.PROPS + "mg_lab_scanner.png")
var _lamp_off := ColonyMap.texture(ColonyMap.PROPS + "mg_lab_lamp_off.png")
var _lamp_on := ColonyMap.texture(ColonyMap.PROPS + "mg_lab_lamp_on.png")


func draw(mg: Minigame) -> void:
	_tex(mg, _screen, SCREEN_AT)
	_spectrum(mg)
	_tex(mg, _scanner, SCANNER_AT)
	_beam(mg)
	_lamps(mg)
	draw_button(mg)
	if mg._done:
		_text(mg, "MATCH!", GREEN)
	draw_flash(mg, Vector2(0, 112))
	draw_fact(mg)


func _tex(mg: Minigame, t: Texture2D, at: Vector2) -> void:
	if t:
		mg.draw_texture_rect(t, Rect2(at, t.get_size() * K), false)


func _spectrum(mg: Minigame) -> void:
	for y in [GRAPH.position.y + 26, GRAPH.position.y + 54, GRAPH.position.y + 80]:
		mg.draw_rect(Rect2(GRAPH.position.x, y, GRAPH.size.x, 2), GRID)
	var b0 := _snap(GRAPH.position.x + GRAPH.size.x * mg._band.x)
	var b1 := _snap(GRAPH.position.x + GRAPH.size.x * mg._band.y)
	mg.draw_rect(Rect2(b0, GRAPH.position.y, b1 - b0, GRAPH.size.y), BAND_BG)
	var centre := (mg._band.x + mg._band.y) * 0.5
	var scan := _snap(GRAPH.position.x + GRAPH.size.x * mg._needle())
	var n := int(GRAPH.size.x / PITCH)
	for i in n:
		var u := (i + 0.5) / n
		# smooth continuum with a dip at the band: the absorption line moves with each new band
		var h := 0.6 + 0.2 * sin(i * 0.37 + 1.0) + 0.1 * sin(i * 1.3 + 0.4)
		h *= 1.0 - 0.75 * exp(-pow((u - centre) / 0.06, 2.0))
		var bh := _snap(GRAPH.size.y * clampf(h, 0.08, 0.95))
		var x := GRAPH.position.x + i * PITCH + 1
		var c := GREEN if x + BAR_W > b0 and x < b1 else TEAL
		if absf(x + BAR_W * 0.5 - scan) < PITCH:
			c = Color.WHITE
		mg.draw_rect(Rect2(x, GRAPH.end.y - bh, BAR_W, bh), c)
	for x in [b0, b1 - 2]:
		mg.draw_rect(Rect2(x, GRAPH.position.y, 2, GRAPH.size.y), GREEN)
	mg.draw_rect(Rect2(scan - 4, GRAPH.position.y - 2, 8, GRAPH.size.y + 4), INK)
	mg.draw_rect(Rect2(scan - 2, GRAPH.position.y, 4, GRAPH.size.y), MISS if mg._lock > 0.0 else Color.WHITE)


func _beam(mg: Minigame) -> void:
	var c := MISS if mg._lock > 0.0 else (Color.WHITE if mg._pop > 0.0 or mg._done else TEAL)
	var sweep := int(mg._t * 20.0) % (BEAM_LEN / 2)
	for r in BEAM_LEN / 2:
		var w := 12 + r * 4
		var row := c if r != sweep or c != TEAL else Color.WHITE
		mg.draw_rect(Rect2(BEAM.x - w / 2, BEAM.y + r * 2, w, 2), row)


func _lamps(mg: Minigame) -> void:
	var hits := roundi(mg._progress * mg.goal)
	for i in mg.goal:
		var ax := 85.0 + (i - (mg.goal - 1) * 0.5) * 22.0 - 8.0
		_tex(mg, _lamp_on if i < hits else _lamp_off, SCANNER_AT + Vector2(ax, LAMP_Y) * K)


func _text(mg: Minigame, s: String, c: Color) -> void:
	var at := Vector2(0, 110)
	mg.draw_string_outline(ColonyMap.FONT, at, s, HORIZONTAL_ALIGNMENT_CENTER, mg.size.x, 40, 8, INK)
	mg.draw_string(ColonyMap.FONT, at, s, HORIZONTAL_ALIGNMENT_CENTER, mg.size.x, 40, c)


func _snap(v: float) -> float:
	return floorf(v / K) * K


func button_center(mg: Minigame) -> Vector2:
	return Vector2(mg.size.x * 0.5, 478)
