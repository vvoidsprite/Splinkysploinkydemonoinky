@tool
extends TileMapLayer
## Paints from `rows`. Each character maps to Rect2i(col, row, w, h) in `atlas` tile units;
## cell (x, y) uses atlas (col + x % w, row + y % h), so w/h > 1 repeats a seamless block.
## Paints only when the layer has no saved cells: once the scene is saved from the editor,
## the editor's tiles win and `rows` is ignored.

@export var atlas: Texture2D
@export var legend: Dictionary = {}
@export var rows: PackedStringArray = []


func _ready() -> void:
	if get_used_cells().is_empty():
		paint()


func paint() -> void:
	if atlas == null:
		return
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	var src := TileSetAtlasSource.new()
	src.texture = atlas
	src.texture_region_size = Vector2i(32, 32)
	ts.add_source(src, 0)
	tile_set = ts
	clear()
	for y in rows.size():
		var row := rows[y]
		for x in row.length():
			var ch := row[x]
			if not legend.has(ch):
				continue
			var r: Rect2i = legend[ch]
			var coords := Vector2i(r.position.x + x % maxi(r.size.x, 1), r.position.y + y % maxi(r.size.y, 1))
			if src.get_tile_at_coords(coords) == Vector2i(-1, -1):
				src.create_tile(coords)
			set_cell(Vector2i(x, y), 0, coords)
