class_name UseButton
extends TextureButton

## HUD action button: enabled only while the detector has a focus, uses it on press.

@export var detector: InteractionDetector


func _ready() -> void:
	_set_enabled(false)
	pressed.connect(_on_pressed)
	if detector:
		detector.focus_changed.connect(_on_focus_changed)


func _on_focus_changed(target: Interactable) -> void:
	_set_enabled(target != null)


func _set_enabled(enabled: bool) -> void:
	disabled = not enabled


func _on_pressed() -> void:
	if detector:
		detector.try_interact()
