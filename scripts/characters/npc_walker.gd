extends RefCounted
## Walks a character tile by tile along a list of cells. Awaitable:
##   await NpcWalker.walk(edrin, edrin_sprite, [Vector2i(20, 23), Vector2i(20, 22)])
## `actor` is the node that moves (its origin is the character's feet); `sprite` is the
## character_sprite.gd node that animates (may be null). Each cell is stepped into in order.

const SPEED := 72.0


static func walk(actor: Node2D, sprite: Node, cells: Array, speed := SPEED) -> void:
	for c in cells:
		if not is_instance_valid(actor) or not actor.is_inside_tree():
			return
		var target := NavGrid.center_of(c)
		while is_instance_valid(actor) and actor.is_inside_tree() and actor.global_position != target:
			var to := target - actor.global_position
			var step := minf(speed / float(Engine.physics_ticks_per_second), to.length())
			actor.global_position += to.normalized() * step
			if sprite != null:
				sprite.update_motion(to.normalized() * speed, false)
			await actor.get_tree().physics_frame
	if is_instance_valid(sprite):
		sprite.update_motion(Vector2.ZERO, false)


## Turn a standing character to face a direction name ("up", "down", "left", "right").
static func face(sprite: Node, dir: String) -> void:
	sprite.facing = dir
	sprite.update_motion(Vector2.ZERO, false)
