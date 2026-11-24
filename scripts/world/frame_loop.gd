extends Sprite2D
## Loops a sprite sheet's frames 0..frame_count-1 at `fps` (wall torches, candelabras).

@export var frame_count := 6
@export var fps := 8.0

var _t := 0.0


func _ready() -> void:
	_t = randf() * frame_count / maxf(fps, 0.01)


func _process(delta: float) -> void:
	_t += delta
	frame = int(_t * fps) % maxi(frame_count, 1)
