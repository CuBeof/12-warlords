extends Button
class_name BoardTileView

signal cell_pressed(cell: Vector2i)
signal cell_swiped(cell: Vector2i, direction: Vector2i)

const BoardTileScript := preload("res://scripts/board/tile.gd")

var cell: Vector2i = Vector2i.ZERO
var tile: Variant
var _base_scale := Vector2.ONE
var _tween: Tween
var _touch_start := Vector2.ZERO
var _swipe_sent := false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	pressed.connect(func() -> void: cell_pressed.emit(cell))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch_start = touch.position
			_swipe_sent = false
		return
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_try_emit_swipe(drag.position - _touch_start)
		return
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			_touch_start = mouse_button.position
			_swipe_sent = false
		return
	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_try_emit_swipe(mouse_motion.position - _touch_start)


func setup(new_cell: Vector2i, new_tile: Variant, tile_size: float) -> void:
	cell = new_cell
	tile = new_tile.copy()
	custom_minimum_size = Vector2(tile_size, tile_size)
	pivot_offset = custom_minimum_size * 0.5
	tooltip_text = str(BoardTileScript.TYPE_KEYS[tile.type])
	_refresh_visuals(false)


func update_cell(new_cell: Vector2i) -> void:
	cell = new_cell


func set_selected(selected: bool) -> void:
	_refresh_visuals(selected)
	if _tween:
		_tween.kill()
	_tween = create_tween().bind_node(self)
	_tween.tween_property(self, "scale", Vector2.ONE * (1.08 if selected else 1.0), 0.11) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func play_pop(delay: float = 0.0) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().bind_node(self)
	_tween.tween_interval(delay)
	_tween.tween_property(self, "scale", Vector2.ONE * 1.22, 0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ZERO, 0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_callback(queue_free)


func play_spawn() -> void:
	modulate.a = 0.0
	scale = Vector2.ONE * 0.55
	if _tween:
		_tween.kill()
	_tween = create_tween().bind_node(self).set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, 0.16)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func play_land_bounce() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().bind_node(self)
	_tween.tween_property(self, "scale", Vector2(1.14, 0.86), 0.06) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", _base_scale, 0.16) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _refresh_visuals(selected: bool) -> void:
	var color: Color = tile.color()
	var border: Color = Color.WHITE if selected else color.lightened(0.25)
	if tile.enhanced:
		border = Color("ffe08a")
	var normal := _style(color.darkened(0.14), border, 2 if selected or tile.enhanced else 1)
	var hover := _style(color.lightened(0.1), Color.WHITE, 2)
	var pressed_style := _style(color.darkened(0.24), border, 2)
	add_theme_stylebox_override(&"normal", normal)
	add_theme_stylebox_override(&"hover", hover)
	add_theme_stylebox_override(&"pressed", pressed_style)
	add_theme_stylebox_override(&"disabled", normal)
	text = _symbol_for_tile(tile)
	add_theme_color_override(&"font_color", Color("fff8e6") if tile.enhanced else Color("f8f2e8"))
	add_theme_font_size_override(&"font_size", 24 if tile.enhanced else 22)


func _try_emit_swipe(delta: Vector2) -> void:
	if _swipe_sent or delta.length() < maxf(18.0, custom_minimum_size.x * 0.32):
		return
	_swipe_sent = true
	var direction := Vector2i.ZERO
	if absf(delta.x) > absf(delta.y):
		direction.x = 1 if delta.x > 0.0 else -1
	else:
		direction.y = 1 if delta.y > 0.0 else -1
	cell_swiped.emit(cell, direction)


func _symbol_for_tile(source: Variant) -> String:
	match source.type:
		BoardTileScript.TileType.ATTACK:
			return "A*" if source.enhanced else "A"
		BoardTileScript.TileType.HEALTH:
			return "H*" if source.enhanced else "H"
		BoardTileScript.TileType.MONEY:
			return "G*" if source.enhanced else "G"
		BoardTileScript.TileType.ENERGY:
			return "E*" if source.enhanced else "E"
		BoardTileScript.TileType.EXPERIENCE:
			return "X*" if source.enhanced else "X"
	return "?"


func _style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_bottom = border_width
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 3
	return style
