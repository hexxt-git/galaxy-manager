extends "res://scripts/colony/minigames/skin.gd"

## Solar panel: a close-up of a panel caked in moondust; each tap drags the squeegee across the next dusty row.
## Row geometry mirrors MGS in art-src/props/mg_solar_panel.js (art px, drawn at HUD.UI_SCALE).

const K := HUD.UI_SCALE
const PANEL_AT := Vector2(36, 46)
const ROW_Y0 := 9
const ROW_STEP := 21
const DUST_X := 8  # dust left edge, art px from the panel's left
const DUST_DY := -2
const LIP_DY := -5
const WIPE := 0.2  # seconds for one squeegee pass
const PUFF := 0.35
const SPARKS := [[0.18, 0.0, 0], [0.52, 0.45, 2], [0.84, 0.2, 1]]  # x across the row, blink phase, y jitter

var _tex := {}
var _seen := 0
var _wipe_row := -1
var _wipe_t := -10.0


func setup(mg: Minigame) -> void:
	super.setup(mg)
	for n in ["panel", "dust_a", "dust_b", "dust_lip", "squeegee", "puff", "sparkle", "button", "button_pressed"]:
		var t := ColonyMap.texture(ColonyMap.PROPS + "mg_solar_" + n + ".png")
		var img := t.get_image()
		img.resize(img.get_width() * K, img.get_height() * K, Image.INTERPOLATE_NEAREST)
		_tex[n] = ImageTexture.create_from_image(img)


func button_center(mg: Minigame) -> Vector2:
	return Vector2(mg.size.x * 0.5, 466)


func draw(mg: Minigame) -> void:
	var cleared := roundi(mg._progress * Minigame.TAPS)
	if cleared > _seen:
		_seen = cleared
		_wipe_row = cleared - 1
		_wipe_t = mg._t
	var since: float = mg._t - _wipe_t
	var sweep := clampf(since / WIPE, 0.0, 1.0)
	var wiping := since < WIPE

	mg.draw_texture(_tex["panel"], PANEL_AT)
	var dust_w: int = _tex["dust_a"].get_width()
	var cut := float(snappedi(dust_w * sweep, K)) if wiping else 0.0
	for j in Minigame.TAPS:
		var tex: Texture2D = _tex["dust_a" if j % 2 == 0 else "dust_b"]
		if j >= cleared:
			mg.draw_texture(tex, _dust_at(j, DUST_DY))
		elif j == _wipe_row and wiping:
			_strip(mg, tex, _dust_at(j, DUST_DY), cut, dust_w)
		else:
			_sparkle(mg, j, mg._done)
	if wiping:
		_strip(mg, _tex["dust_lip"], _dust_at(_wipe_row, LIP_DY), cut, dust_w)
		if cleared < Minigame.TAPS:
			_strip(mg, _tex["dust_lip"], _dust_at(cleared, LIP_DY), 0.0, cut)
	elif cleared < Minigame.TAPS:
		mg.draw_texture(_tex["dust_lip"], _dust_at(cleared, LIP_DY))

	if since < WIPE + PUFF and _wipe_row >= 0:
		var p := clampf((since - WIPE * 0.6) / PUFF, 0.0, 1.0)
		if since >= WIPE * 0.6:
			var at := _row(_wipe_row) + Vector2(DUST_X * K + dust_w - 30, -8 - 40 * p)
			mg.draw_texture(_tex["puff"], at.snapped(Vector2(K, K)), Color(1, 1, 1, 1.0 - p))

	if wiping:
		_squeegee(mg, _row(_wipe_row) + Vector2(DUST_X * K + dust_w * sweep, 0))
	elif not mg._done and cleared < Minigame.TAPS:
		var bob := K * float(int(mg._t * 3.0) % 2)
		_squeegee(mg, _row(cleared) + Vector2(DUST_X * K - 2 * K, -bob))

	draw_button(mg)
	draw_flash(mg, Vector2(0, PANEL_AT.y + 160))
	draw_fact(mg)


func _dust_at(j: int, dy: int) -> Vector2:
	return _row(j) + Vector2(DUST_X, dy) * K


## Draws the columns from..to of a dust strip whose left edge is at `at`.
func _strip(mg: Minigame, tex: Texture2D, at: Vector2, from: float, to: float) -> void:
	if to > from:
		mg.draw_texture_rect_region(tex, Rect2(at + Vector2(from, 0), Vector2(to - from, tex.get_height())), Rect2(from, 0, to - from, tex.get_height()))


## Top-left of row j's cells, in screen px.
func _row(j: int) -> Vector2:
	return PANEL_AT + Vector2(0, ROW_Y0 + j * ROW_STEP) * K


## The squeegee with its blade's middle at the row's vertical centre and x.
func _squeegee(mg: Minigame, row_left: Vector2) -> void:
	var at := row_left + Vector2(0, 9 * K) - Vector2(12, 38) * K
	mg.draw_texture(_tex["squeegee"], at.snapped(Vector2(K, K)))


func _sparkle(mg: Minigame, j: int, all_on: bool) -> void:
	var w: int = _tex["dust_a"].get_width()
	for s in SPARKS:
		var phase: float = s[1] + j * 0.37
		var dy: int = (s[2] + j) % 3
		if all_on or fmod(mg._t * 1.2 + phase, 1.0) < 0.3:
			var at := _row(j) + Vector2(DUST_X * K + w * s[0] + (j % 2) * 12 * K, dy * K)
			mg.draw_texture(_tex["sparkle"], at.snapped(Vector2(K, K)))


func draw_button(mg: Minigame) -> void:
	var face: Texture2D = _buttons["done"] if mg._done else (_buttons["wait"] if mg._lock > 0.0 else _tex["button_pressed" if pressed(mg) else "button"])
	mg.draw_texture(face, button_center(mg) - Vector2(57, 54) * K)
