extends RefCounted
class_name BoardModel

signal board_initialized(snapshot: Array)
signal tiles_swapped(a: Vector2i, b: Vector2i)
signal swap_reverted(a: Vector2i, b: Vector2i)
signal match_resolved(groups: Array, combo: int, extra_turns_added: int)
signal tiles_dropped(movements: Array)
signal tiles_refilled(spawns: Array)
signal cascade_finished(summary: Dictionary)

const BoardTileScript := preload("res://scripts/board/tile.gd")

const WIDTH := 8
const HEIGHT := 8
const WARMUP_TURNS := 4
const EXTRA_TURN_CAP := 2

var width: int = WIDTH
var height: int = HEIGHT
var total_turns: int = 0
var luck: float = 0.0

var _tiles: Array[Array] = []
var _rng := RandomNumberGenerator.new()


func _init(board_width: int = WIDTH, board_height: int = HEIGHT) -> void:
	width = board_width
	height = board_height
	_rng.randomize()


func new_board() -> void:
	_tiles.clear()
	for y in range(height):
		var row: Array[Variant] = []
		_tiles.append(row)
		for x in range(width):
			row.append(_roll_tile_avoiding_initial_matches(x, y))
	board_initialized.emit(snapshot())


func snapshot() -> Array:
	var result: Array[Array] = []
	for y in range(height):
		var row: Array[Variant] = []
		for x in range(width):
			var tile: Variant = _tiles[y][x]
			row.append(tile.copy())
		result.append(row)
	return result


func tile_at(cell: Vector2i) -> Variant:
	if not is_in_bounds(cell):
		return null
	return _tiles[cell.y][cell.x]


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height


func are_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return abs(a.x - b.x) + abs(a.y - b.y) == 1


func try_swap(a: Vector2i, b: Vector2i) -> bool:
	if not is_in_bounds(a) or not is_in_bounds(b) or not are_adjacent(a, b):
		return false

	_swap_tiles(a, b)
	tiles_swapped.emit(a, b)

	var groups := _find_groups()
	if groups.is_empty():
		_swap_tiles(a, b)
		swap_reverted.emit(a, b)
		cascade_finished.emit({
			&"valid": false,
			&"combo": 0,
			&"extra_turns": 0,
			&"values": {}
		})
		return false

	_resolve_cascades(groups)
	return true


func _resolve_cascades(initial_groups: Array) -> void:
	var combo := 1
	var extra_turns := 0
	var values := _empty_values()
	var groups := initial_groups

	while not groups.is_empty():
		var upgraded_cell := _maybe_upgrade_group(groups)
		var clear_cells := _collect_clear_cells(groups)
		var extra_from_groups := _extra_turns_from_groups(groups)
		var added_extra := mini(extra_from_groups, EXTRA_TURN_CAP - extra_turns)
		extra_turns += added_extra
		_add_group_values(values, groups, combo)

		match_resolved.emit(groups, combo, added_extra)
		_clear_cells(clear_cells)
		if upgraded_cell != Vector2i(-1, -1):
			clear_cells[upgraded_cell] = true

		var movements := _collapse_columns()
		if not movements.is_empty():
			tiles_dropped.emit(movements)

		var spawns := _refill_columns()
		if not spawns.is_empty():
			tiles_refilled.emit(spawns)

		groups = _find_groups()
		combo += 1

	total_turns += 1
	cascade_finished.emit({
		&"valid": true,
		&"combo": combo - 1,
		&"extra_turns": extra_turns,
		&"values": values
	})


func _roll_tile_avoiding_initial_matches(x: int, y: int) -> Variant:
	var attempts := 0
	while attempts < 16:
		var tile: Variant = _roll_tile(false)
		var repeats_left: bool = x >= 2 and _tiles[y][x - 1].type == tile.type and _tiles[y][x - 2].type == tile.type
		var repeats_up: bool = y >= 2 and _tiles[y - 1][x].type == tile.type and _tiles[y - 2][x].type == tile.type
		if not repeats_left and not repeats_up:
			return tile
		attempts += 1
	return _roll_tile(false)


func _roll_tile(allow_enhanced: bool = true) -> Variant:
	var tile_type: int = _rng.randi_range(BoardTileScript.TileType.ATTACK, BoardTileScript.TileType.EXPERIENCE)
	var enhanced := false
	if allow_enhanced and total_turns > WARMUP_TURNS:
		var rate := clampf(0.03 + float(total_turns - WARMUP_TURNS) * 0.006 + luck * 0.01, 0.03, 0.22)
		enhanced = _rng.randf() < rate
	return BoardTileScript.new(tile_type, enhanced)


func _find_groups() -> Array:
	var lines: Array[Dictionary] = []
	_find_horizontal_lines(lines)
	_find_vertical_lines(lines)
	return _merge_intersections(lines)


func _find_horizontal_lines(lines: Array[Dictionary]) -> void:
	for y in range(height):
		var start := 0
		while start < width:
			var tile: Variant = _tiles[y][start]
			var end := start + 1
			while end < width and _tiles[y][end].type == tile.type:
				end += 1
			if end - start >= 3:
				var cells: Array[Vector2i] = []
				for x in range(start, end):
					cells.append(Vector2i(x, y))
				lines.append({
					&"cells": cells,
					&"type": tile.type,
					&"orientation": &"horizontal",
					&"length": cells.size()
				})
			start = end


func _find_vertical_lines(lines: Array[Dictionary]) -> void:
	for x in range(width):
		var start := 0
		while start < height:
			var tile: Variant = _tiles[start][x]
			var end := start + 1
			while end < height and _tiles[end][x].type == tile.type:
				end += 1
			if end - start >= 3:
				var cells: Array[Vector2i] = []
				for y in range(start, end):
					cells.append(Vector2i(x, y))
				lines.append({
					&"cells": cells,
					&"type": tile.type,
					&"orientation": &"vertical",
					&"length": cells.size()
				})
			start = end


func _merge_intersections(lines: Array[Dictionary]) -> Array:
	var used: Array[bool] = []
	used.resize(lines.size())
	var groups: Array[Dictionary] = []
	for index in range(lines.size()):
		if used[index]:
			continue
		var group_cells: Dictionary = {}
		var line_indices: Array[int] = []
		var tile_type: int = lines[index][&"type"]
		_collect_connected_lines(index, lines, used, line_indices, group_cells)
		var cells: Array[Vector2i] = []
		for cell in group_cells.keys():
			cells.append(cell)
		var shape := _classify_group(line_indices, lines, cells)
		groups.append({
			&"cells": cells,
			&"type": tile_type,
			&"shape": shape,
			&"line_count": line_indices.size()
		})
	return groups


func _collect_connected_lines(index: int, lines: Array[Dictionary], used: Array[bool], line_indices: Array[int], group_cells: Dictionary) -> void:
	used[index] = true
	line_indices.append(index)
	for cell in lines[index][&"cells"]:
		group_cells[cell] = true
	for other in range(lines.size()):
		if used[other] or lines[other][&"type"] != lines[index][&"type"]:
			continue
		if _lines_intersect(lines[index][&"cells"], lines[other][&"cells"]):
			_collect_connected_lines(other, lines, used, line_indices, group_cells)


func _lines_intersect(a: Array, b: Array) -> bool:
	for cell in a:
		if cell in b:
			return true
	return false


func _classify_group(line_indices: Array[int], lines: Array[Dictionary], cells: Array[Vector2i]) -> StringName:
	if line_indices.size() >= 2:
		return &"corner"
	var length: int = cells.size()
	if length >= 5:
		return &"line5"
	if length >= 4:
		return &"line4"
	return &"line3"


func _maybe_upgrade_group(groups: Array) -> Vector2i:
	for group in groups:
		if _rng.randf() > clampf(0.04 + luck * 0.01, 0.04, 0.18):
			continue
		var candidates: Array = group[&"cells"]
		if candidates.is_empty():
			continue
		var cell: Vector2i = candidates[_rng.randi_range(0, candidates.size() - 1)]
		_tiles[cell.y][cell.x].enhanced = true
		return cell
	return Vector2i(-1, -1)


func _collect_clear_cells(groups: Array) -> Dictionary:
	var clear_cells: Dictionary = {}
	for group in groups:
		for cell in group[&"cells"]:
			clear_cells[cell] = true
		if group[&"shape"] == &"line5":
			_add_random_targets(clear_cells, group[&"cells"], 3)
		elif group[&"shape"] == &"corner":
			_add_radius_targets(clear_cells, group[&"cells"], 3, 2)
	return clear_cells


func _add_random_targets(clear_cells: Dictionary, source_cells: Array, count: int) -> void:
	var candidates: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			if not clear_cells.has(cell):
				candidates.append(cell)
	candidates.shuffle()
	for index in range(mini(count, candidates.size())):
		clear_cells[candidates[index]] = true


func _add_radius_targets(clear_cells: Dictionary, source_cells: Array, count: int, radius: int) -> void:
	var center: Vector2i = source_cells[0]
	var candidates: Array[Vector2i] = []
	for y in range(maxi(0, center.y - radius), mini(height, center.y + radius + 1)):
		for x in range(maxi(0, center.x - radius), mini(width, center.x + radius + 1)):
			var cell := Vector2i(x, y)
			if not clear_cells.has(cell):
				candidates.append(cell)
	candidates.shuffle()
	for index in range(mini(count, candidates.size())):
		clear_cells[candidates[index]] = true


func _extra_turns_from_groups(groups: Array) -> int:
	var turns := 0
	for group in groups:
		if group[&"shape"] == &"line4" or group[&"shape"] == &"line5":
			turns += 1
	return turns


func _add_group_values(values: Dictionary, groups: Array, combo: int) -> void:
	for group in groups:
		var key: StringName = BoardTileScript.TYPE_KEYS[group[&"type"]]
		var value := 0
		for cell in group[&"cells"]:
			value += _tiles[cell.y][cell.x].score_value()
		values[key] += value * combo


func _clear_cells(clear_cells: Dictionary) -> void:
	for cell in clear_cells.keys():
		_tiles[cell.y][cell.x] = null


func _collapse_columns() -> Array:
	var movements: Array[Dictionary] = []
	for x in range(width):
		var write_y := height - 1
		for read_y in range(height - 1, -1, -1):
			var tile: Variant = _tiles[read_y][x]
			if tile == null:
				continue
			if write_y != read_y:
				_tiles[write_y][x] = tile
				_tiles[read_y][x] = null
				movements.append({
					&"from": Vector2i(x, read_y),
					&"to": Vector2i(x, write_y)
				})
			write_y -= 1
	return movements


func _refill_columns() -> Array:
	var spawns: Array[Dictionary] = []
	for x in range(width):
		var spawn_offset := 0
		for y in range(height):
			if _tiles[y][x] != null:
				continue
			var tile: Variant = _roll_tile()
			_tiles[y][x] = tile
			spawns.append({
				&"from": Vector2i(x, -1 - spawn_offset),
				&"to": Vector2i(x, y),
				&"tile": tile.copy()
			})
			spawn_offset += 1
	return spawns


func _swap_tiles(a: Vector2i, b: Vector2i) -> void:
	var temp: Variant = _tiles[a.y][a.x]
	_tiles[a.y][a.x] = _tiles[b.y][b.x]
	_tiles[b.y][b.x] = temp


func _empty_values() -> Dictionary:
	return {
		&"attack": 0,
		&"health": 0,
		&"money": 0,
		&"energy": 0,
		&"experience": 0
	}
