class_name NavGrid
extends RefCounted
## 4-direction tile grid (16px tiles) for one area. Tile (x,y) covers [16x,16x+16) x [16y,16y+16);
## characters stand on tile centres. A tile is blocked when a 12x12 probe at its centre overlaps a
## static collider (so a collider must reach more than 2px into the tile to block it).

const TILE := 16
const PROBE := 12.0
const INVALID := Vector2i(-1, -1)

static var _cache := {}

var bounds := Rect2()
var mask := 1

var _astar := AStarGrid2D.new()
var _region := Rect2i()


static func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


static func center_of(c: Vector2i) -> Vector2:
	return Vector2(c) * TILE + Vector2(TILE / 2.0, TILE / 2.0)


static func snap(p: Vector2) -> Vector2:
	return center_of(cell_of(p))


## True when a static collider (body, never a character or an area) reaches into the tile.
static func tile_blocked(space: PhysicsDirectSpaceState2D, c: Vector2i, mask := 1, exclude: Array[RID] = []) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(PROBE, PROBE)
	q.shape = rs
	q.transform = Transform2D(0.0, center_of(c))
	q.margin = 0.0
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.exclude = exclude
	q.collision_mask = mask
	for hit in space.intersect_shape(q, 16):
		var col: Object = hit.get("collider")
		if col is StaticBody2D or col is AnimatableBody2D or col is TileMapLayer:
			return true
	return false


## The (cached) grid for the area the node lives in. rebuild=true rescans the obstacles.
static func for_area(node: Node, rebuild := false, mask := 1) -> NavGrid:
	var area: Node2D = node as Node2D if node.has_meta("area_size") else find_area_root(node)
	var key := "%d|%d" % [area.get_instance_id() if area != null else 0, mask]
	if not rebuild and _cache.has(key):
		return _cache[key]
	var grid := NavGrid.new()
	var space: PhysicsDirectSpaceState2D
	if node is CanvasItem:
		space = (node as CanvasItem).get_world_2d().direct_space_state
	else:
		space = node.get_viewport().world_2d.direct_space_state
	grid.build(space, area_bounds(area, node), mask)
	_cache[key] = grid
	return grid


static func for_body(body: CollisionObject2D, rebuild := false) -> NavGrid:
	return for_area(body, rebuild, body.collision_mask)


## Forgets every cached grid of that area (call after moving or adding obstacles).
static func invalidate(area: Node) -> void:
	var prefix := str(area.get_instance_id() if area != null else 0) + "|"
	for k in _cache.keys():
		if (k as String).begins_with(prefix):
			_cache.erase(k)


static func find_area_root(node: Node) -> Node2D:
	var n := node.get_parent()
	while n != null:
		if n.has_meta("area_size"):
			return n as Node2D
		n = n.get_parent()
	return null


## The area's rectangle: its "area_size" meta, else every static collision rect plus 32px.
static func area_bounds(area: Node2D, body: Node) -> Rect2:
	if area != null:
		return Rect2(area.global_position, Vector2(area.get_meta("area_size")))
	var scope: Node = body.get_tree().current_scene if body.get_tree().current_scene != null else body.get_parent()
	var rect := Rect2()
	var first := true
	for cs in scope.find_children("*", "CollisionShape2D", true, false):
		var node := cs as CollisionShape2D
		if node.shape == null or not (node.get_parent() is StaticBody2D or node.get_parent() is AnimatableBody2D):
			continue
		var r := node.global_transform * node.shape.get_rect()
		rect = r if first else rect.merge(r)
		first = false
	if first:
		var p: Vector2 = (body as Node2D).global_position if body is Node2D else Vector2.ZERO
		return Rect2(p - Vector2(128, 128), Vector2(256, 256))
	return rect.grow(32.0)


func build(space: PhysicsDirectSpaceState2D, area_rect: Rect2, collision_mask: int) -> void:
	bounds = area_rect
	mask = collision_mask
	var origin := cell_of(bounds.position)
	var sz := Vector2i(ceili(bounds.size.x / TILE), ceili(bounds.size.y / TILE))
	_region = Rect2i(origin, sz)
	_astar = AStarGrid2D.new()
	_astar.region = _region
	_astar.cell_size = Vector2(TILE, TILE)
	_astar.offset = Vector2(TILE / 2.0, TILE / 2.0)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.update()
	for y in range(_region.position.y, _region.end.y):
		for x in range(_region.position.x, _region.end.x):
			refresh_cell(space, Vector2i(x, y))


## Re-reads the obstacles inside a world rectangle (for things that moved after the build).
func refresh_rect(space: PhysicsDirectSpaceState2D, rect: Rect2) -> void:
	var a := cell_of(rect.position)
	var b := cell_of(rect.end)
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			refresh_cell(space, Vector2i(x, y))


func refresh_cell(space: PhysicsDirectSpaceState2D, c: Vector2i) -> void:
	if not _region.has_point(c):
		return
	_astar.set_point_solid(c, tile_blocked(space, c, mask))


func is_free(c: Vector2i) -> bool:
	return _region.has_point(c) and not _astar.is_point_solid(c)


## The closest free cell to c (c itself if free), or INVALID when none within max_radius cells.
func nearest_free_cell(c: Vector2i, max_radius := 8) -> Vector2i:
	if is_free(c):
		return c
	for r in range(1, max_radius + 1):
		var best := INVALID
		var best_d := INF
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var n := c + Vector2i(dx, dy)
				if not is_free(n):
					continue
				var d := float(dx * dx + dy * dy)
				if d < best_d:
					best_d = d
					best = n
		if best != INVALID:
			return best
	return INVALID


## Shortest 4-direction route, start cell included. When the goal cannot be reached the route ends
## at the reachable cell nearest to it. Returns just [from] when from is not a free cell.
func find_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = [from]
	if not is_free(from):
		return out
	var goal := Vector2i(clampi(to.x, _region.position.x, _region.end.x - 1),
			clampi(to.y, _region.position.y, _region.end.y - 1))
	var ids := _astar.get_id_path(from, goal, true)
	if ids.size() < 2:
		return out
	out.clear()
	for id in ids:
		out.append(id)
	return out


## Same route as tile centres.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var a := nearest_free_cell(cell_of(from))
	if a == INVALID:
		return out
	for c in find_cells(a, cell_of(to)):
		out.append(center_of(c))
	return out
