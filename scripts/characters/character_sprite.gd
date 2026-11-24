extends Sprite2D
## Memao character sheet animator (8 cols x 41 rows of 48x48, frames row-major).
## Shared by Maren and Edrin. Call update_motion() each physics frame.

const ANIMS := {
	"idle_down": [0, 4], "idle_up": [4, 4], "idle_left": [8, 4], "idle_right": [12, 4],
	"walk_down": [16, 6], "walk_up": [22, 6], "walk_left": [28, 6], "walk_right": [34, 6],
	"run_down": [40, 6], "run_up": [46, 6], "run_left": [52, 6], "run_right": [58, 6],
}
const FPS_IDLE := 5.0
## Walk and run cycles advance by distance travelled, so the feet match the ground
## and every frame of the cycle shows, even when steps are short or Maren pauses.
const PX_PER_FRAME_WALK := 6.4
const PX_PER_FRAME_RUN := 10.0

@export var facing := "down"

var mode := "idle"
var _time := 0.0
var _anim := ""
var _dist := 0.0
var _speed := 0.0


func _ready() -> void:
	_apply()


func update_motion(v: Vector2, running: bool) -> void:
	_speed = v.length()
	if _speed < 1.0:
		mode = "idle"
	else:
		mode = "run" if running else "walk"
		var ax := absf(v.x)
		var ay := absf(v.y)
		var horizontal := "right" if v.x > 0.0 else "left"
		var vertical := "down" if v.y > 0.0 else "up"
		if is_equal_approx(ax, ay):
			if facing != horizontal and facing != vertical:
				facing = vertical
		elif ax > ay:
			facing = horizontal
		else:
			facing = vertical
	_apply()


func _process(delta: float) -> void:
	_time += delta
	if mode != "idle":
		_dist += _speed * delta
	_apply()


func _apply() -> void:
	var key := "%s_%s" % [mode, facing]
	if key != _anim:
		_anim = key
		if mode == "idle":
			_time = 0.0
	var info: Array = ANIMS[key]
	if mode == "idle":
		frame = info[0] + int(_time * FPS_IDLE) % info[1]
	else:
		var per := PX_PER_FRAME_RUN if mode == "run" else PX_PER_FRAME_WALK
		frame = info[0] + int(_dist / per) % info[1]
