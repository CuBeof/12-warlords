extends Control
class_name BoardView

const BoardModelScript := preload("res://scripts/board/board_model.gd")
const BoardTileScript := preload("res://scripts/board/tile.gd")
const BoardTileViewScene := preload("res://scripts/board/board_tile_view.gd")

@export var tile_size: float = 54.0
@export var tile_gap: float = 5.0

var model: Variant
var _tiles: Dictionary = {}
var _selected: Vector2i = Vector2i(-1, -1)
var _busy := false
var _board_layer: Control
var _fx_layer: Control
var _combo_label: Label
var _summary_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(tile_size * 8.0 + tile_gap * 7.0, tile_size * 8.0 + tile_gap * 7.0 + 72.0)
	_build_layers()
	_start_new_board()


func _build_layers() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override(&"separation", 8)
	add_child(root)

	var hud := HBoxContainer.new()
	hud.custom_minimum_size.y = 38
	hud.add_theme_constant_override(&"separation", 10)
	root.add_child(hud)

	_combo_label = Label.new()
	_combo_label.text = ""
	_combo_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.add_theme_font_size_override(&"font_size", 26)
	_combo_label.add_theme_color_override(&"font_color", Color("ffd56a"))
	hud.add_child(_combo_label)

	var reset := Button.new()
	reset.text = tr("ui.battle.new_board")
	reset.pressed.connect(_start_new_board)
	hud.add_child(reset)

	var board_frame := PanelContainer.new()
	board_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_frame.add_theme_stylebox_override(&"panel", _style(Color("111014"), Color("6f5d45"), 2, 8))
	root.add_child(board_frame)

	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override(&"margin_left", 10)
	board_margin.add_theme_constant_override(&"margin_right", 10)
	board_margin.add_theme_constant_override(&"margin_top", 10)
	board_margin.add_theme_constant_override(&"margin_bottom", 10)
	board_frame.add_child(board_margin)

	var board_stack := Control.new()
	board_stack.custom_minimum_size = Vector2(tile_size * 8.0 + tile_gap * 7.0, tile_size * 8.0 + tile_gap * 7.0)
	board_margin.add_child(board_stack)

	_board_layer = Control.new()
	_board_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	board_stack.add_child(_board_layer)

	_fx_layer = Control.new()
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	board_stack.add_child(_fx_layer)

	_summary_label = Label.new()
	_summary_label.text = tr("ui.battle.board_hint")
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.add_theme_font_size_override(&"font_size", 18)
	_summary_label.add_theme_color_override(&"font_color", Color("b7a994"))
	root.add_child(_summary_label)


func _start_new_board() -> void:
	if _busy:
		return
	_selected = Vector2i(-1, -1)
	_clear_tile_nodes()
	model = BoardModelScript.new()
	model.board_initialized.connect(_on_board_initialized)
	model.tiles_swapped.connect(_on_tiles_swapped)
	model.swap_reverted.connect(_on_swap_reverted)
	model.match_resolved.connect(_on_match_resolved)
	model.tiles_dropped.connect(_on_tiles_dropped)
	model.tiles_refilled.connect(_on_tiles_refilled)
	model.cascade_finished.connect(_on_cascade_finished)
	model.new_board()


func _on_board_initialized(snapshot: Array) -> void:
	_render_snapshot(snapshot, true)
	_summary_label.text = tr("ui.battle.board_hint")


func _render_snapshot(snapshot: Array, animate_spawn: bool) -> void:
	_clear_tile_nodes()
	for y in range(snapshot.size()):
		var row: Array = snapshot[y]
		for x in range(row.size()):
			var cell := Vector2i(x, y)
			var tile: Variant = row[x]
			var view: Variant = _make_tile_view(cell, tile)
			_board_layer.add_child(view)
			_tiles[cell] = view
			if animate_spawn:
				view.play_spawn()


func _make_tile_view(cell: Vector2i, tile: Variant) -> Variant:
	var view: Variant = BoardTileViewScene.new()
	view.setup(cell, tile, tile_size)
	view.position = _cell_position(cell)
	view.cell_pressed.connect(_on_cell_pressed)
	view.cell_swiped.connect(_on_cell_swiped)
	return view


func _on_cell_pressed(cell: Vector2i) -> void:
	if _busy:
		return
	if _selected == Vector2i(-1, -1):
		_select_cell(cell)
		return
	if _selected == cell:
		_select_cell(Vector2i(-1, -1))
		return
	if model.are_adjacent(_selected, cell):
		var from := _selected
		_select_cell(Vector2i(-1, -1))
		_busy = true
		model.try_swap(from, cell)
	else:
		_select_cell(cell)


func _on_cell_swiped(cell: Vector2i, direction: Vector2i) -> void:
	if _busy:
		return
	var target := cell + direction
	if not model.is_in_bounds(target):
		return
	_select_cell(Vector2i(-1, -1))
	_busy = true
	model.try_swap(cell, target)


func _select_cell(cell: Vector2i) -> void:
	if _tiles.has(_selected):
		_tiles[_selected].set_selected(false)
	_selected = cell
	if _tiles.has(_selected):
		_tiles[_selected].set_selected(true)


func _on_tiles_swapped(a: Vector2i, b: Vector2i) -> void:
	_swap_view_entries(a, b)
	var tween := create_tween().bind_node(self).set_parallel(true)
	_tween_tile_to(tween, a)
	_tween_tile_to(tween, b)


func _on_swap_reverted(a: Vector2i, b: Vector2i) -> void:
	await get_tree().create_timer(0.18).timeout
	_swap_view_entries(a, b)
	var tween := create_tween().bind_node(self).set_parallel(true)
	_tween_tile_to(tween, a)
	_tween_tile_to(tween, b)
	_float_text(tr("ui.battle.failed_swap"), (_cell_position(a) + _cell_position(b)) * 0.5, Color("ff6a5c"))


func _on_match_resolved(groups: Array, combo: int, extra_turns_added: int) -> void:
	_combo_label.text = tr("ui.battle.combo").format({ "combo": combo })
	_punch_label(_combo_label)
	for group in groups:
		var cells: Array = group[&"cells"]
		var shape: StringName = group[&"shape"]
		var color := _color_for_type(group[&"type"])
		for index in range(cells.size()):
			var cell: Vector2i = cells[index]
			if not _tiles.has(cell):
				continue
			var view: Variant = _tiles[cell]
			view.play_pop(float(index) * 0.018)
		_float_text(_label_for_shape(shape), _center_for_cells(cells), color.lightened(0.2))
	if extra_turns_added > 0:
		_float_text(tr("ui.battle.extra_turn"), Vector2(_board_layer.size.x * 0.5, 10), Color("ffd56a"))


func _on_tiles_dropped(movements: Array) -> void:
	for movement in movements:
		var from: Vector2i = movement[&"from"]
		var to: Vector2i = movement[&"to"]
		if not _tiles.has(from):
			continue
		var view: Variant = _tiles[from]
		_tiles.erase(from)
		_tiles[to] = view
		view.update_cell(to)
	var tween := create_tween().bind_node(self).set_parallel(true)
	for movement in movements:
		var to_cell: Vector2i = movement[&"to"]
		_tween_tile_to(tween, to_cell, 0.18 + float(to_cell.y) * 0.012)
	tween.finished.connect(func() -> void:
		for movement in movements:
			var view: Variant = _tiles[movement[&"to"]]
			view.play_land_bounce()
	)


func _on_tiles_refilled(spawns: Array) -> void:
	for spawn in spawns:
		var to_cell: Vector2i = spawn[&"to"]
		var from_cell: Vector2i = spawn[&"from"]
		var tile: Variant = spawn[&"tile"]
		var view: Variant = _make_tile_view(to_cell, tile)
		view.position = _cell_position(from_cell)
		_board_layer.add_child(view)
		_tiles[to_cell] = view
		var tween := create_tween().bind_node(view)
		tween.tween_property(view, "position", _cell_position(to_cell), 0.24 + float(to_cell.y) * 0.012) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_callback(view.play_land_bounce)


func _on_cascade_finished(summary: Dictionary) -> void:
	await get_tree().create_timer(0.24).timeout
	_busy = false
	_combo_label.text = ""
	if not summary[&"valid"]:
		_summary_label.text = tr("ui.battle.invalid_summary")
		return
	var values: Dictionary = summary[&"values"]
	_summary_label.text = tr("ui.battle.summary").format({
		"combo": summary[&"combo"],
		"turns": summary[&"extra_turns"],
		"attack": values[&"attack"],
		"health": values[&"health"],
		"money": values[&"money"],
		"energy": values[&"energy"],
		"experience": values[&"experience"]
	})


func _swap_view_entries(a: Vector2i, b: Vector2i) -> void:
	var view_a: Variant = _tiles[a]
	var view_b: Variant = _tiles[b]
	_tiles[a] = view_b
	_tiles[b] = view_a
	view_a.update_cell(b)
	view_b.update_cell(a)


func _tween_tile_to(tween: Tween, cell: Vector2i, duration: float = 0.18) -> void:
	if not _tiles.has(cell):
		return
	var view: Variant = _tiles[cell]
	tween.tween_property(view, "position", _cell_position(cell), duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)


func _clear_tile_nodes() -> void:
	for view in _tiles.values():
		if is_instance_valid(view):
			view.queue_free()
	_tiles.clear()


func _cell_position(cell: Vector2i) -> Vector2:
	return Vector2(float(cell.x) * (tile_size + tile_gap), float(cell.y) * (tile_size + tile_gap))


func _center_for_cells(cells: Array) -> Vector2:
	var total := Vector2.ZERO
	for cell in cells:
		total += _cell_position(cell) + Vector2(tile_size, tile_size) * 0.5
	return total / maxf(1.0, float(cells.size()))


func _float_text(text: String, pos: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.modulate = color
	label.add_theme_font_size_override(&"font_size", 24)
	label.add_theme_color_override(&"font_color", color)
	_fx_layer.add_child(label)
	var tween := create_tween().bind_node(label).set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 48.0, 0.55) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)


func _punch_label(label: Label) -> void:
	label.scale = Vector2.ONE
	var tween := create_tween().bind_node(label)
	tween.tween_property(label, "scale", Vector2.ONE * 1.2, 0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.16) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _label_for_shape(shape: StringName) -> String:
	match shape:
		&"line4":
			return tr("ui.battle.match4")
		&"line5":
			return tr("ui.battle.match5")
		&"corner":
			return tr("ui.battle.match_corner")
	return tr("ui.battle.match3")


func _color_for_type(tile_type: int) -> Color:
	return BoardTileScript.TYPE_COLORS[tile_type]


func _style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_bottom = border_width
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	return style
