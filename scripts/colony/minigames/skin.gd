extends RefCounted

## How a minigame looks. Minigame owns the rules and input; a skin only draws, and says where the button is.
## Each station kind can have its own skin in scripts/colony/minigames/<kind>.gd: extends "res://scripts/colony/minigames/skin.gd".
## Read the game's state straight off `mg`:
##   mode ("hold" | "taps" | "timing"), heat (drill overheating on), goal (timing hits needed), fact, flawless
##   _progress 0..1, _heat 0..1, _holding, _t (seconds open), _band (timing target, Vector2 0..1),
##   _needle() 0..1, _done, _lock > 0 after a miss, _pop > 0 just after a good input, _flash / _flash_t (last message)
## mg.size is the drawing area (about 552 x 772 px). Draw with mg.draw_*; art should be pixel art at HUD.UI_SCALE.

const HUD := preload("res://scripts/colony/hud.gd")
const MODES := {"hold": "mg_hold", "taps": "mg_tap", "timing": "mg_stop"}

var _bar_bg := HUD.nine("mg_bar_bg", 6, Vector4.ZERO)
var _bar_fill := HUD.nine("mg_bar_fill", 6, Vector4.ZERO)
var _heat_fill := HUD.nine("mg_heat_fill", 6, Vector4.ZERO)
var _track := HUD.nine("mg_track", 8, Vector4.ZERO)
var _band_box := HUD.nine("mg_band", 3, Vector4.ZERO)
var _needle_tex := ColonyMap.texture(HUD.UI + "mg_needle.png")
var _buttons := {}


func setup(_mg: Minigame) -> void:
	for m in MODES:
		_buttons[m] = HUD.ui_tex(MODES[m])
		_buttons[m + "_pressed"] = HUD.ui_tex(MODES[m] + "_pressed")
	_buttons["done"] = HUD.ui_tex("mg_done")
	_buttons["wait"] = HUD.ui_tex("mg_wait")


func button_center(mg: Minigame) -> Vector2:
	return Vector2(mg.size.x * 0.5, mg.size.y * 0.62)


func button_radius() -> float:
	return 110.0


## Whether the big button looks pressed right now.
func pressed(mg: Minigame) -> bool:
	return not mg._done and mg._lock <= 0.0 and (mg._holding or mg._pop > 0.0)


func draw(mg: Minigame) -> void:
	var font := ColonyMap.FONT
	var w := mg.size.x
	bar(mg, Rect2(40, 60, w - 80, 28), mg._progress, _bar_fill)
	if mg.mode == "hold" and mg.heat:
		var hb := Rect2(40, 110, w - 80, 28)
		bar(mg, hb, mg._heat, _heat_fill)
		mg.draw_string(font, hb.position + Vector2(0, 56), "heat", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	if mg.mode == "timing":
		mg.draw_string(font, Vector2(0, 136), "%d / %d" % [roundi(mg._progress * mg.goal), mg.goal], HORIZONTAL_ALIGNMENT_CENTER, w, 26, Color.WHITE)
		var track := Rect2(40, 150, w - 80, 52)
		mg.draw_style_box(_track, track)
		var inner := track.grow(-6)
		mg.draw_style_box(_band_box, Rect2(inner.position.x + inner.size.x * mg._band.x, inner.position.y, inner.size.x * (mg._band.y - mg._band.x), inner.size.y))
		var nx := inner.position.x + inner.size.x * mg._needle()
		mg.draw_set_transform(Vector2(nx, track.get_center().y), 0.0, Vector2(HUD.UI_SCALE, HUD.UI_SCALE))
		mg.draw_texture(_needle_tex, -Vector2(3, 16))
		mg.draw_set_transform(Vector2.ZERO)
	draw_button(mg)
	draw_flash(mg, Vector2(0, 260))
	draw_fact(mg)


func bar(mg: Minigame, r: Rect2, amount: float, fill: StyleBox) -> void:
	mg.draw_style_box(_bar_bg, r)
	var fw := r.size.x * clampf(amount, 0.0, 1.0)
	if fw >= 14.0 * HUD.UI_SCALE:
		mg.draw_style_box(fill, Rect2(r.position, Vector2(fw, r.size.y)))


func draw_button(mg: Minigame) -> void:
	var face: Texture2D = _buttons["done"] if mg._done else (_buttons["wait"] if mg._lock > 0.0 else _buttons[mg.mode + ("_pressed" if pressed(mg) else "")])
	mg.draw_texture(face, button_center(mg) - Vector2(57, 54) * HUD.UI_SCALE)


func draw_flash(mg: Minigame, at: Vector2) -> void:
	if mg._flash_t > 0.0 and not mg._done:
		var good: bool = mg._flash in ["Done!", "Perfect!"]
		mg.draw_string_outline(ColonyMap.FONT, at, mg._flash, HORIZONTAL_ALIGNMENT_CENTER, mg.size.x, 34, 8, Color("0d0d12"))
		mg.draw_string(ColonyMap.FONT, at, mg._flash, HORIZONTAL_ALIGNMENT_CENTER, mg.size.x, 34, Color("7ed957") if good else Color("ff8a7a"))


func draw_fact(mg: Minigame) -> void:
	mg.draw_multiline_string(ColonyMap.FONT, Vector2(30, mg.size.y - 150), mg.fact, HORIZONTAL_ALIGNMENT_LEFT, mg.size.x - 60, 22, -1, Color.WHITE)
