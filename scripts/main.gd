extends Control

var points := 0.0
var per_tap := 1
var per_sec := 0
var tap_cost := 10
var auto_cost := 25

@onready var counter: Label = %Counter
@onready var rate: Label = %Rate
@onready var tap_button: Button = %TapButton
@onready var tap_upgrade: Button = %TapUpgrade
@onready var auto_upgrade: Button = %AutoUpgrade


func _ready() -> void:
	tap_button.pivot_offset = tap_button.size / 2
	tap_button.resized.connect(func(): tap_button.pivot_offset = tap_button.size / 2)
	_refresh()


func _process(delta: float) -> void:
	if per_sec > 0:
		points += per_sec * delta
		_refresh()


func _on_tap_button_pressed() -> void:
	points += per_tap
	_refresh()
	_punch(tap_button)
	_float_text("+%d" % per_tap, tap_button.get_global_rect().get_center())


func _on_tap_upgrade_pressed() -> void:
	if points < tap_cost:
		return
	points -= tap_cost
	per_tap += 1
	tap_cost = int(tap_cost * 1.6)
	_refresh()


func _on_auto_upgrade_pressed() -> void:
	if points < auto_cost:
		return
	points -= auto_cost
	per_sec += 1
	auto_cost = int(auto_cost * 1.5)
	_refresh()


func _refresh() -> void:
	counter.text = str(int(points))
	rate.text = "%d / tap   ·   %d / sec" % [per_tap, per_sec]
	tap_upgrade.text = "+1 per tap\n%d" % tap_cost
	auto_upgrade.text = "+1 per sec\n%d" % auto_cost
	tap_upgrade.disabled = points < tap_cost
	auto_upgrade.disabled = points < auto_cost


func _punch(node: Control) -> void:
	var t := create_tween()
	node.scale = Vector2(0.9, 0.9)
	t.tween_property(node, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _float_text(text: String, at: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 40)
	label.position = at + Vector2(randf_range(-80, 80), -60)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var t := create_tween().set_parallel()
	t.tween_property(label, "position:y", label.position.y - 120, 0.7)
	t.tween_property(label, "modulate:a", 0.0, 0.7)
	t.chain().tween_callback(label.queue_free)
