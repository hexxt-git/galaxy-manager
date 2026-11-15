extends "res://scripts/colony/minigames/skin.gd"

## Rock outcrop: a close-up of the outcrop rock. Each tap swings the rock hammer down on the sample chunk, chips fly
## and the cracks spread round it; the last tap breaks the chunk free, leaving a socket with a fresh teal glint.
## STRIKE and BOX mirror MGO.strike and MGO.box in art-src/props/mg_outcrop_rock.js (art px, drawn at HUD.UI_SCALE).

const K := HUD.UI_SCALE
const ROCK_AT := Vector2(36, 62)
const STRIKE := Vector2(126, 50)
const BOX := Vector2(100, 40)
const HAMMER_ORIGIN := Vector2(45, 150)
const CHIP_TIME := 0.5
const GRAVITY := 1400.0
const CHIPS := [Vector2(-170, -300), Vector2(150, -340), Vector2(-60, -420), Vector2(240, -230)]  # screen px/s
const BURST := 0.1
const HOP := 0.25  # chunk's hop out; Minigame closes DONE_DELAY after the last tap
const GREEN := Color("7ed957")
const INK := Color("0d0d12")

var _tex := {}
var _seen := 0
var _hit_t := -10.0
var _done_t := -1.0


func setup(mg: Minigame) -> void:
	super.setup(mg)
	var parts := ["rock", "sample", "socket", "hammer", "hammer_up", "chip_a", "chip_b", "burst", "button", "button_pressed"]
	for i in range(1, Minigame.TAPS):
		parts.append("crack_%d" % i)
	for n in parts:
		var t := ColonyMap.texture(ColonyMap.PROPS + "mg_outcrop_" + n + ".png")
		var img := t.get_image()
		img.resize(img.get_width() * K, img.get_height() * K, Image.INTERPOLATE_NEAREST)
		_tex[n] = ImageTexture.create_from_image(img)


func button_center(mg: Minigame) -> Vector2:
	return Vector2(mg.size.x * 0.5, 470)


func draw(mg: Minigame) -> void:
	var hits := roundi(mg._progress * Minigame.TAPS)
	if hits > _seen:
		_seen = hits
		_hit_t = mg._t
	if mg._done and _done_t < 0.0:
		_done_t = mg._t
	var since: float = mg._t - _hit_t
	var shake := Vector2(K * (1 if int(since * 40.0) % 2 == 0 else -1), 0) if since < 0.12 and not mg._done else Vector2.ZERO
	var rock := ROCK_AT + shake

	mg.draw_texture(_tex["rock"], rock)
	var cracks := mini(hits, Minigame.TAPS - 1)
	if mg._done:
		mg.draw_texture(_tex["crack_%d" % cracks], rock)
		mg.draw_texture(_tex["socket"], rock + BOX * K)
	elif cracks > 0:
		mg.draw_texture(_tex["crack_%d" % cracks], rock)

	var strike := rock + STRIKE * K
	if since < BURST:
		mg.draw_texture(_tex["burst"], strike - Vector2(9, 9) * K)
	var hammer: Texture2D = _tex["hammer" if since < 0.12 and not mg._done else "hammer_up"]
	var bob := Vector2(0, -K * float(int(mg._t * 3.0) % 2)) if hammer == _tex["hammer_up"] else Vector2.ZERO
	mg.draw_texture(hammer, strike - HAMMER_ORIGIN * K + bob)

	if since < CHIP_TIME and hits > 0:
		for i in CHIPS.size():
			var v: Vector2 = CHIPS[i] * Vector2(-1 if hits % 2 == 0 else 1, 1)
			var at := strike + v * since + Vector2(0, 0.5 * GRAVITY * since * since)
			mg.draw_texture(_tex["chip_b" if i == 2 else "chip_a"], (at - Vector2(5, 5) * K).snapped(Vector2(K, K)))

	if mg._done:
		var p := clampf((mg._t - _done_t) / HOP, 0.0, 1.0)
		var hop := Vector2(-130 * p, -90 * sin(PI * p) + 110 * p)
		mg.draw_texture(_tex["sample"], (ROCK_AT + BOX * K + hop).snapped(Vector2(K, K)))
		mg.draw_string_outline(ColonyMap.FONT, Vector2(0, 46), "SAMPLE!", HORIZONTAL_ALIGNMENT_CENTER, mg.size.x, 40, 8, INK)
		mg.draw_string(ColonyMap.FONT, Vector2(0, 46), "SAMPLE!", HORIZONTAL_ALIGNMENT_CENTER, mg.size.x, 40, GREEN)

	draw_button(mg)
	draw_flash(mg, Vector2(0, 46))
	draw_fact(mg)


func draw_button(mg: Minigame) -> void:
	var face: Texture2D = _buttons["done"] if mg._done else (_buttons["wait"] if mg._lock > 0.0 else _tex["button_pressed" if pressed(mg) else "button"])
	mg.draw_texture(face, button_center(mg) - Vector2(57, 54) * K)
