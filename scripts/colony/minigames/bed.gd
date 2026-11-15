extends "res://scripts/colony/minigames/skin.gd"

## Potato bed: a cross-section of a hydroponic grow bed under a red/blue LED grow light. Each tap tips the watering
## can, the plant grows a stage and the potatoes under the soil line swell; when done, the potatoes hop out.
## Geometry mirrors MGB in art-src/props/mg_bed_scene.js (art px, drawn at HUD.UI_SCALE).

const K := HUD.UI_SCALE
const SCENE_AT := Vector2(36, 16)
const PLANT := Vector2(120, 92)  # plant origin in the scene: soil line under the stem
const CAN := Vector2(58, 54)
const SPOUT := Vector2(27, 1)  # rose tip of the tilted can, from the can's origin
const PIP_Y := 133
const PIP_STEP := 18
const POUR := 0.35
const FALL := 0.18
const GROW_AT := 0.16  # the new stage shows once the first drop lands
const HOP := 0.22
const TUBERS := [Vector2(-22, 15), Vector2(19, 19), Vector2(-3, 29)]
const LANDS := [Vector2(-46, 0), Vector2(28, 0), Vector2(60, 0)]

var _tex := {}
var _seen := 0
var _pour_t := -10.0
var _done_t := -1.0


func setup(mg: Minigame) -> void:
	super.setup(mg)
	var names := ["scene", "plant_picked", "potato", "can", "can_pour", "drop", "pip_off", "pip_on", "button", "button_pressed"]
	for s in Minigame.TAPS + 1:
		names.append("plant_%d" % s)
	for n in names:
		_tex[n] = ColonyMap.texture(ColonyMap.PROPS + "mg_bed_" + n + ".png")


func button_center(mg: Minigame) -> Vector2:
	return Vector2(mg.size.x * 0.5, 470)


func draw(mg: Minigame) -> void:
	var stage := roundi(mg._progress * Minigame.TAPS)
	if stage > _seen:
		_seen = stage
		_pour_t = mg._t
	if mg._done and _done_t < 0.0:
		_done_t = mg._t
	var since: float = mg._t - _pour_t

	_put(mg, "scene", Vector2.ZERO)
	var shown := stage - 1 if since < GROW_AT else stage
	if mg._done:
		_put(mg, "plant_picked", PLANT - Vector2(60, 76))
		_hop(mg)
	else:
		_put(mg, "plant_%d" % maxi(shown, 0), PLANT - Vector2(60, 76))
	for i in Minigame.TAPS:
		_put(mg, "pip_on" if i < shown or mg._done else "pip_off", Vector2(PLANT.x - 7 + (i - 2.5) * PIP_STEP, PIP_Y))

	if since < POUR:
		_put(mg, "can_pour", CAN - Vector2(20, 28))
		for d in 3:
			var p: float = (since - d * 0.08) / FALL
			if p >= 0.0 and p < 1.0:
				var from := CAN + SPOUT + Vector2([0, 3, -2][d], 0)
				_put(mg, "drop", from.lerp(Vector2(from.x - 2, PLANT.y - 6), p * p))
	else:
		var bob := 0.0 if mg._done else float(int(mg._t * 3.0) % 2)
		_put(mg, "can", CAN - Vector2(20, 28 + bob))

	draw_button(mg)
	draw_flash(mg, Vector2(0, 350))
	draw_fact(mg)


## Potatoes pop out of the soil and land beside the plant.
func _hop(mg: Minigame) -> void:
	var p := clampf((mg._t - _done_t) / HOP, 0.0, 1.0)
	for i in TUBERS.size():
		var at: Vector2 = TUBERS[i].lerp(LANDS[i], p) + Vector2(0, -22 * sin(PI * p))
		_put(mg, "potato", PLANT + at - Vector2(15, 19))


## Draws a sprite with its top-left at `at` art px inside the scene.
func _put(mg: Minigame, n: String, at: Vector2) -> void:
	var t: Texture2D = _tex[n]
	if t:
		mg.draw_texture_rect(t, Rect2(SCENE_AT + at.floor() * K, t.get_size() * K), false)


func draw_button(mg: Minigame) -> void:
	if mg._done or mg._lock > 0.0:
		super.draw_button(mg)
		return
	var face: Texture2D = _tex["button_pressed" if pressed(mg) else "button"]
	mg.draw_texture_rect(face, Rect2(button_center(mg) - Vector2(57, 54) * K, face.get_size() * K), false)
