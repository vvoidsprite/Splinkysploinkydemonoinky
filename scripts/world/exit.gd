extends Area2D
## Area transition trigger. Asks the "area_manager" group node to go_to(target_area, target_spawn).

@export var target_area := ""
@export var target_spawn := ""
@export var enabled := true:
	set(value):
		var was := enabled
		enabled = value
		if enabled and not was and is_inside_tree():
			_check_overlap.call_deferred()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	if enabled:
		_check_overlap.call_deferred()


func _check_overlap() -> void:
	if not enabled or not is_inside_tree():
		return
	for b in get_overlapping_bodies():
		_on_body_entered(b)


func _on_body_entered(body: Node2D) -> void:
	if not enabled or not body.is_in_group("player") or body.get("frozen") == true:
		return
	var mgr := get_tree().get_first_node_in_group("area_manager")
	if mgr != null:
		mgr.go_to(target_area, target_spawn)
