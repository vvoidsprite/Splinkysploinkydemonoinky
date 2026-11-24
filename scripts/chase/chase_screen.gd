extends CanvasLayer
## End-of-chase screen. Press interact to reload the scene.

@onready var _fade: ColorRect = $Fade
@onready var _title: Label = $Title
@onready var _hint: Label = $Hint

var _ready_for_input := false


func _ready() -> void:
	visible = false


func show_message(title: String, hint: String) -> void:
	_title.text = title
	_hint.text = hint
	_fade.color.a = 0.0
	_title.modulate.a = 0.0
	_hint.modulate.a = 0.0
	visible = true
	_ready_for_input = false
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 0.85, 0.6)
	tween.parallel().tween_property(_title, "modulate:a", 1.0, 0.6)
	tween.tween_property(_hint, "modulate:a", 1.0, 0.4)
	tween.tween_callback(func(): _ready_for_input = true)


func _unhandled_input(event: InputEvent) -> void:
	if not _ready_for_input or not InputMap.has_action("interact"):
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()
