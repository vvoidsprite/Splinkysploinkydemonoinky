extends Node2D
## Three candles under OBEY / ENDURE / GIVE. Lighting all three in the Order's prayer order
## (OBEY, ENDURE, GIVE) makes the flames lean and die and the candles reset. The old reading,
## GIVE, ENDURE, OBEY, solves it: sets the story flag "prologue.candles_solved".

const SOLVED_FLAG := "prologue.candles_solved"
const PRAYER_ORDER := ["OBEY", "ENDURE", "GIVE"]
const OLD_ORDER := ["GIVE", "ENDURE", "OBEY"]

var sequence: Array = []
var locked := false


func candles() -> Array:
	var out: Array = []
	for c in get_children():
		if c.has_method("set_lit"):
			out.append(c)
	return out


## Matches the story flag: solved = all lit and locked; otherwise all dark and ready.
func apply_state() -> void:
	var solved: bool = GameState.get_flag(SOLVED_FLAG)
	sequence.clear()
	locked = solved
	for c in candles():
		c.set_lit(solved)


func try_light(candle) -> void:
	if locked or candle.lit:
		return
	candle.set_lit(true)
	sequence.append(candle.word)
	if sequence.size() < candles().size():
		return
	locked = true
	if sequence == OLD_ORDER:
		Dialogue.play("candles_right")
		await Dialogue.finished
		GameState.set_flag(SOLVED_FLAG)
	else:
		for c in candles():
			c.lean()
		Dialogue.play("candles_wrong")
		await Dialogue.finished
		reset()


func reset() -> void:
	sequence.clear()
	for c in candles():
		c.set_lit(false)
	locked = false
