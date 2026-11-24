@tool
extends Node2D
## A dense dark forest ringing an outdoor map (the area's "border" metadata is "trees").
## Place one node named TreeBorder under the area root. It reads the root's "area_size", draws a
## dark backing over the band [-depth, size+depth] minus the map, and scatters mixed trees (pines,
## oaks, birches, the odd dead tree) in clumps over a jittered grid in that band. A fringe of ferns,
## grass tufts and stumps (child node "Undergrowth") runs along the inner edge. Trees below the map
## are kept clear of the bottom rows. The layout is deterministic (same seed, same forest). Visual
## only: no colliders; the area's own walls keep Maren inside. Nodes are built at runtime, never saved.

const SHEET := "res://assets/RPGFW_Set1_v1.0/_PNG/veg_decoratives.png"
## Dark set: pines (0-2), oaks, birches, one dead tree. Mostly pines, mixed in clumps.
const DEFAULT_TREES: Array[Rect2] = [
	Rect2(587, 20, 65, 168),   # 0 pine, large
	Rect2(682, 32, 79, 156),   # 1 pine, medium
	Rect2(778, 97, 44, 91),    # 2 pine, small
	Rect2(177, 80, 92, 172),   # 3 oak, medium
	Rect2(387, 26, 85, 194),   # 4 birch, tall
	Rect2(481, 77, 60, 143),   # 5 birch, medium
	Rect2(313, 167, 48, 85),   # 6 oak, small round
	Rect2(837, 32, 56, 155),   # 7 dead tree
]
const DEFAULT_WEIGHTS: Array[float] = [24.0, 22.0, 14.0, 10.0, 8.0, 7.0, 8.0, 7.0]
## Ferns, small ferns, grass tuft, tall grass, golden bush, stumps (no rocks).
const DEFAULT_UNDERGROWTH: Array[Rect2] = [
	Rect2(295, 715, 48, 38), Rect2(366, 706, 39, 28),
	Rect2(357, 736, 27, 32), Rect2(389, 740, 24, 27),
	Rect2(6, 643, 20, 22),
	Rect2(742, 704, 17, 32), Rect2(678, 706, 17, 30), Rect2(710, 710, 16, 26),
	Rect2(2, 673, 27, 29),
	Rect2(600, 409, 37, 34), Rect2(707, 417, 29, 23), Rect2(788, 422, 26, 21),
]
const DEFAULT_UNDERGROWTH_WEIGHTS: Array[float] = [10.0, 8.0, 7.0, 6.0, 14.0, 8.0, 8.0, 8.0, 5.0, 3.0, 3.0, 3.0]
## Trees below the map may reach at most this far into it, so canopies never hide Maren.
const SOUTH_REACH := 24

@export var texture: Texture2D
@export var trees: Array[Rect2] = []
@export var weights: Array[float] = []
@export var undergrowth: Array[Rect2] = []
@export var undergrowth_weights: Array[float] = []
@export var undergrowth_spacing := 18
@export var depth := 160
@export var inset := 12
@export var spacing := 40
@export var seed := 1
@export var backing_color := Color(0.05, 0.08, 0.06)

var backing: Node2D
var undergrowth_node: Node2D


func _ready() -> void:
	y_sort_enabled = true
	build()


## The map size from the parent area (zero if it has none).
func map_size() -> Vector2:
	var p := get_parent()
	if p != null and p.has_meta("area_size"):
		return Vector2(Vector2i(p.get_meta("area_size")))
	return Vector2.ZERO


## Tree feet positions and region indices, in order. Pure function of the exports and the map size.
## Trees gather round a few clump centres, a few cells are left empty, and trees below the map are
## pushed down so their tops stay within SOUTH_REACH of the map's bottom edge.
func layout() -> Array:
	var size := map_size()
	var out: Array = []
	if size == Vector2.ZERO or spacing <= 0:
		return out
	var regions := _regions()
	var w := _weights(regions.size())
	var total := _sum(w)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var map_rect := Rect2(Vector2.ZERO, size).grow(-float(inset))
	var band := Rect2(Vector2.ZERO, size).grow(float(depth))
	var clumps := _clumps(rng, size, w, total)
	var skipped := {}
	var row := 0
	var y := band.position.y
	while y <= band.end.y:
		var col := 0
		var x := band.position.x
		while x <= band.end.x:
			var jit := Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4)) * spacing
			var pick := rng.randf() * total
			var flip := rng.randf() < 0.5
			var gap := rng.randf() < 0.1
			var fav := rng.randf() < 0.4
			var drop := rng.randf_range(0.0, 12.0)
			var p := Vector2(x, y) + jit
			# pull toward the nearest clump centre
			var best := -1
			var best_d := 1.0e9
			for i in clumps.size():
				var d: float = p.distance_to(clumps[i]["pos"])
				if d < best_d:
					best_d = d
					best = i
			var in_clump: bool = best >= 0 and best_d < clumps[best]["radius"]
			if in_clump:
				p = p.lerp(clumps[best]["pos"], 0.3)
			p = p.round()
			# a gap never touches the previous cell in its row or the cell above it
			if gap and (skipped.has(Vector2i(col - 1, row)) or skipped.has(Vector2i(col, row - 1))):
				gap = false
			if gap:
				skipped[Vector2i(col, row)] = true
			elif not map_rect.has_point(p) and band.has_point(p):
				var idx := _pick(w, pick)
				if in_clump and fav:
					idx = clumps[best]["region"]
				var h: float = regions[idx].size.y
				if p.y > size.y - float(inset):
					p.y = roundf(maxf(p.y, size.y - float(SOUTH_REACH) + h + drop))
				out.append({"feet": p, "region": idx, "flip": flip})
			x += spacing
			col += 1
		y += spacing
		row += 1
	return out


## Undergrowth (ferns, tufts, stumps) along the inner fringe, 2 to 30 px outside the map edge.
## Entries are {"feet", "region", "flip"}; regions index into the undergrowth list.
func undergrowth_layout() -> Array:
	var size := map_size()
	var out: Array = []
	if size == Vector2.ZERO or undergrowth_spacing <= 0:
		return out
	var regions := _undergrowth_regions()
	var w := _undergrowth_weights(regions.size())
	var total := _sum(w)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 1000
	var step := float(undergrowth_spacing)
	for side in 4:
		var length := size.x if side < 2 else size.y
		var t := -20.0
		while t <= length + 20.0:
			var pos := t + rng.randf_range(-0.35, 0.35) * step
			var out_d := rng.randf_range(2.0, 30.0)
			var pick := rng.randf() * total
			var flip := rng.randf() < 0.5
			var keep := rng.randf() < 0.85
			if keep:
				var p: Vector2
				match side:
					0: p = Vector2(pos, -out_d)
					1: p = Vector2(pos, size.y + out_d)
					2: p = Vector2(-out_d, pos)
					_: p = Vector2(size.x + out_d, pos)
				out.append({"feet": p.round(), "region": _pick(w, pick), "flip": flip})
			t += step
	return out


func build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	backing = null
	undergrowth_node = null
	var size := map_size()
	if size == Vector2.ZERO:
		return
	var tex := texture if texture != null else load(SHEET) as Texture2D
	var regions := _regions()
	backing = Node2D.new()
	backing.name = "Backing"
	backing.z_index = -3
	add_child(backing)
	var d := float(depth)
	_add_rect(Rect2(-d, -d, size.x + 2.0 * d, d))                  # top
	_add_rect(Rect2(-d, size.y, size.x + 2.0 * d, d + 40.0))       # bottom (south trees sit lower)
	_add_rect(Rect2(-d, 0.0, d, size.y))                           # left
	_add_rect(Rect2(size.x, 0.0, d, size.y))                       # right
	for t in layout():
		_add_sprite(self, tex, regions[t["region"]], t)
	undergrowth_node = Node2D.new()
	undergrowth_node.name = "Undergrowth"
	undergrowth_node.y_sort_enabled = true
	add_child(undergrowth_node)
	var ug := _undergrowth_regions()
	for t in undergrowth_layout():
		_add_sprite(undergrowth_node, tex, ug[t["region"]], t)


func _add_sprite(parent: Node, tex: Texture2D, r: Rect2, t: Dictionary) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = r
	s.centered = false
	s.offset = Vector2(-r.size.x / 2.0, -r.size.y)
	s.flip_h = t["flip"]
	s.position = t["feet"]
	parent.add_child(s)


## A few clump centres per side; each has a radius and a favoured kind of tree.
func _clumps(rng: RandomNumberGenerator, size: Vector2, w: Array[float], total: float) -> Array:
	var clumps: Array = []
	var per_side := 4
	for side in 4:
		var length := size.x if side < 2 else size.y
		for i in per_side:
			var along := (float(i) + rng.randf_range(0.15, 0.85)) / float(per_side) * (length + 2.0 * depth) - depth
			var out_d := rng.randf_range(20.0, float(depth) * 0.8)
			var pos: Vector2
			match side:
				0: pos = Vector2(along, -out_d)
				1: pos = Vector2(along, size.y + out_d)
				2: pos = Vector2(-out_d, along)
				_: pos = Vector2(size.x + out_d, along)
			var fav := _pick(w, rng.randf() * total)
			var pine_roll := rng.randi_range(0, 2)
			if fav > 2 and rng.randf() < 0.4:
				fav = pine_roll
			clumps.append({"pos": pos, "radius": rng.randf_range(60.0, 100.0), "region": fav})
	return clumps


func _pick(w: Array[float], pick: float) -> int:
	var acc := 0.0
	for i in w.size():
		acc += w[i]
		if pick <= acc:
			return i
	return 0


func _sum(w: Array[float]) -> float:
	var total := 0.0
	for x in w:
		total += x
	return total


func _regions() -> Array[Rect2]:
	return trees if not trees.is_empty() else DEFAULT_TREES


func _undergrowth_regions() -> Array[Rect2]:
	return undergrowth if not undergrowth.is_empty() else DEFAULT_UNDERGROWTH


func _undergrowth_weights(n: int) -> Array[float]:
	var w: Array[float] = []
	var src: Array[float] = undergrowth_weights if not undergrowth_weights.is_empty() else (DEFAULT_UNDERGROWTH_WEIGHTS if undergrowth.is_empty() else [])
	for i in n:
		w.append(src[i] if i < src.size() else 1.0)
	return w


func _weights(n: int) -> Array[float]:
	var w: Array[float] = []
	var src: Array[float] = weights if not weights.is_empty() else (DEFAULT_WEIGHTS if trees.is_empty() else [])
	for i in n:
		w.append(src[i] if i < src.size() else 1.0)
	return w


func _add_rect(r: Rect2) -> void:
	var cr := ColorRect.new()
	cr.color = backing_color
	cr.position = r.position
	cr.size = r.size
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.add_child(cr)
