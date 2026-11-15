class_name Minigame
extends Control

## Placeholder task minigame with three one-thumb modes:
##   hold   — hold the button to fill the bar; with `heat`, holding too long overheats and costs progress
##   taps   — tap the button TAPS times
##   timing — stop the sweeping needle inside the green band `goal` times

signal finished
signal scored  # each successful timing hit
signal logged(what: String, data: Dictionary)  # every input and outcome, for the playtest log

const TAPS := 6
const HITS := 3
const HOLD_TIME := 2.0
const MISS_LOCK := 0.45  # after a missed stop the button is out for this long
const DONE_DELAY := 0.25
const HEAT_TIME := 1.4
const INK := Color("0d0d12")
const BUTTON_R := 110.0

var mode := "taps"
var fact := ""
var heat := false
var goal := HITS
var flawless := true  # no overheat and no missed stop so far

var _progress := 0.0
var _heat := 0.0
var _holding := false
var _t := 0.0
var _band := Vector2(0.4, 0.6)
var _flash := ""
var _flash_t := 0.0
var _done := false
var _lock := 0.0
var _pop := 0.0  # brief press bounce after a successful input


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_new_band()


func _button() -> Vector2:
	return Vector2(size.x * 0.5, size.y * 0.62)


func _gui_input(event: InputEvent) -> void:
	if _done or not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed and _lock > 0.0:
		accept_event()
		return
	if not event.pressed:
		if _holding:
			logged.emit("release", {"progress": _progress, "heat": _heat})
		_holding = false
		return
	if event.position.distance_to(_button()) > BUTTON_R * 1.3:
		logged.emit("missed_button", {"at": event.position})
		return
	accept_event()
	match mode:
		"hold":
			_holding = true
			logged.emit("press", {"progress": _progress, "heat": _heat})
		"taps":
			_advance(1.0 / TAPS)
			_pop = 0.12
			logged.emit("tap", {"progress": _progress})
		"timing":
			var x := _needle()
			logged.emit("stop", {"needle": x, "band": [_band.x, _band.y], "hit": x >= _band.x and x <= _band.y, "progress": _progress})
			if x >= _band.x and x <= _band.y:
				scored.emit()
				_pop = 0.12
				_advance(1.0 / goal)
				_new_band()
			else:
				_lock = MISS_LOCK
				flawless = false
				_say("Missed!")


func _process(delta: float) -> void:
	_t += delta
	_flash_t -= delta
	_lock -= delta
	_pop -= delta
	if mode == "hold" and not _done:
		if _holding:
			_advance(delta / HOLD_TIME)
			if heat:
				_heat += delta / HEAT_TIME
				if _heat >= 1.0:
					_heat = 0.0
					_holding = false
					_progress = maxf(0.0, _progress - 0.3)
					_say("Overheated!")
					logged.emit("overheat", {"progress": _progress})
		else:
			_heat = maxf(0.0, _heat - delta / HEAT_TIME * 1.5)
	queue_redraw()


func _advance(by: float) -> void:
	_progress = minf(1.0, _progress + by)
	if _progress >= 1.0 and not _done:
		_done = true
		_say("Perfect!" if flawless and mode != "taps" else "Done!")
		logged.emit("complete", {"seconds": _t, "flawless": flawless})
		get_tree().create_timer(DONE_DELAY).timeout.connect(finished.emit)


func _say(text: String) -> void:
	_flash = text
	_flash_t = 0.8


func _needle() -> float:
	return (sin(_t * 2.4) + 1.0) * 0.5


func _new_band() -> void:
	var c := randf_range(0.2, 0.8)
	_band = Vector2(c - 0.09, c + 0.09)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := size.x
	var bar := Rect2(40, 60, w - 80, 36)
	draw_rect(bar, Color("2b2f3a"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _progress, bar.size.y)), Color("7ed957"))
	draw_rect(bar, INK, false, 4.0)
	if mode == "hold" and heat:
		var hb := Rect2(40, 110, w - 80, 20)
		draw_rect(hb, Color("2b2f3a"))
		draw_rect(Rect2(hb.position, Vector2(hb.size.x * _heat, hb.size.y)), Color("c8453f").lerp(Color("f2c230"), 1.0 - _heat))
		draw_rect(hb, INK, false, 3.0)
		draw_string(font, hb.position + Vector2(0, 46), "heat", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	if mode == "timing":
		draw_string(font, Vector2(0, 136), "%d / %d" % [roundi(_progress * goal), goal], HORIZONTAL_ALIGNMENT_CENTER, w, 26, Color.WHITE)
		var track := Rect2(40, 150, w - 80, 50)
		draw_rect(track, Color("2b2f3a"))
		draw_rect(Rect2(track.position.x + track.size.x * _band.x, track.position.y, track.size.x * (_band.y - _band.x), track.size.y), Color("7ed957"))
		var nx := track.position.x + track.size.x * _needle()
		draw_line(Vector2(nx, track.position.y - 10), Vector2(nx, track.end.y + 10), Color.WHITE, 6.0)
		draw_rect(track, INK, false, 4.0)
	var b := _button()
	var pressed := not _done and _lock <= 0.0 and (_holding or _pop > 0.0)
	var face := Color("7ed957") if _done else (Color("8a909c") if _lock > 0.0 else Color("dfe7e4"))
	draw_circle(b + Vector2(0, 10), BUTTON_R, INK)
	draw_circle(b + (Vector2(0, 8) if pressed else Vector2.ZERO), BUTTON_R, face)
	var label: String = "DONE" if _done else {"hold": "HOLD", "taps": "TAP", "timing": "STOP"}[mode]
	draw_string(font, b + Vector2(-BUTTON_R, 14) + (Vector2(0, 8) if pressed else Vector2.ZERO), label, HORIZONTAL_ALIGNMENT_CENTER, BUTTON_R * 2, 40, INK)
	if _flash_t > 0.0 and not _done:
		draw_string(font, Vector2(0, 260), _flash, HORIZONTAL_ALIGNMENT_CENTER, w, 34, Color("ff8a7a") if _flash not in ["Done!", "Perfect!"] else Color("7ed957"))
	draw_multiline_string(font, Vector2(30, size.y - 150), fact, HORIZONTAL_ALIGNMENT_LEFT, w - 60, 22, -1, Color.WHITE)
