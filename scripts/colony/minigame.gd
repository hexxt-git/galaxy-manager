class_name Minigame
extends Control

## Task minigame with three one-thumb modes; how it looks is up to its skin (minigames/skin.gd):
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
const SKIN := preload("res://scripts/colony/minigames/skin.gd")

var skin: SKIN
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
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if skin == null:
		skin = SKIN.new()
	skin.setup(self)
	mouse_filter = MOUSE_FILTER_STOP
	_new_band()


func _button() -> Vector2:
	return skin.button_center(self)


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
	if event.position.distance_to(_button()) > skin.button_radius() * 1.3:
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
	skin.draw(self)
