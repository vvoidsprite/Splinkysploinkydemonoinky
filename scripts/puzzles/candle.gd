extends "res://scripts/interaction/interactable.gd"
## One candle of the candle row. Reading its plaque is the interaction; the row decides what
## lighting it means (see candle_row.gd). Placeholder art: a wax stub and a flame polygon.

@export var word := ""

var lit := false


func interact(_player) -> void:
	Dialogue.play(conversation_id)
	await Dialogue.finished
	var row := get_parent()
	if row != null and row.has_method("try_light"):
		await row.try_light(self)


func set_lit(value: bool) -> void:
	lit = value
	var flame := get_node_or_null("Flame") as Node2D
	if flame != null:
		flame.visible = value
		flame.rotation = 0.0


## The flame bends toward the door (south) just before it dies.
func lean() -> void:
	var flame := get_node_or_null("Flame") as Node2D
	if flame != null and lit:
		create_tween().tween_property(flame, "rotation", 0.9, 0.4)
