extends Control

const SCREEN_MAIN := &"main"
const SCREEN_SETTINGS := &"settings"
const SCREEN_MAP := &"map"
const SCREEN_SHOP := &"shop"
const SCREEN_SKILLS := &"skills"
const SCREEN_INVENTORY := &"inventory"
const SCREEN_BATTLE := &"battle"
const SCREEN_CHARACTER := &"character"
const SCREEN_ABOUT := &"about"
const BoardViewScript := preload("res://scripts/board/board_view.gd")

var _content: MarginContainer
var _title: Label
var _screen_buttons: Dictionary = {}
var _current_screen: StringName = SCREEN_MAIN

var _palette := {
	&"bg": Color("171518"),
	&"panel": Color("242027"),
	&"panel_dark": Color("111014"),
	&"line": Color("6f5d45"),
	&"gold": Color("d8aa55"),
	&"red": Color("b9443c"),
	&"green": Color("4fa96a"),
	&"blue": Color("4c8fc8"),
	&"purple": Color("8c6bd6"),
	&"text": Color("eadfce"),
	&"muted": Color("b7a994")
}

func _ready() -> void:
	theme = _build_theme()
	_build_shell()
	_show_screen(SCREEN_MAIN)


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = _palette[&"bg"]
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override(&"margin_left", 18)
	root_margin.add_theme_constant_override(&"margin_right", 18)
	root_margin.add_theme_constant_override(&"margin_top", 18)
	root_margin.add_theme_constant_override(&"margin_bottom", 18)
	add_child(root_margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override(&"separation", 14)
	root_margin.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 72
	header.add_theme_constant_override(&"separation", 12)
	root.add_child(header)

	var crest := _make_emblem("XII")
	header.add_child(crest)

	_title = Label.new()
	_title.text = tr("ui.main.title")
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override(&"font_size", 32)
	_title.add_theme_color_override(&"font_color", _palette[&"gold"])
	header.add_child(_title)

	var quick_battle := Button.new()
	quick_battle.text = tr("ui.nav.battle")
	quick_battle.pressed.connect(func() -> void: _show_screen(SCREEN_BATTLE))
	header.add_child(quick_battle)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", 14)
	root.add_child(body)

	var nav := VBoxContainer.new()
	nav.custom_minimum_size.x = 170
	nav.add_theme_constant_override(&"separation", 8)
	body.add_child(nav)

	_add_nav_button(nav, SCREEN_MAIN, "ui.nav.home")
	_add_nav_button(nav, SCREEN_MAP, "ui.nav.map")
	_add_nav_button(nav, SCREEN_BATTLE, "ui.nav.battle")
	_add_nav_button(nav, SCREEN_INVENTORY, "ui.nav.inventory")
	_add_nav_button(nav, SCREEN_SKILLS, "ui.nav.skills")
	_add_nav_button(nav, SCREEN_SHOP, "ui.nav.shop")
	_add_nav_button(nav, SCREEN_SETTINGS, "ui.nav.settings")
	_add_nav_button(nav, SCREEN_ABOUT, "ui.nav.about")

	_content = MarginContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override(&"margin_left", 8)
	_content.add_theme_constant_override(&"margin_right", 8)
	_content.add_theme_constant_override(&"margin_top", 8)
	_content.add_theme_constant_override(&"margin_bottom", 8)
	body.add_child(_content)


func _add_nav_button(parent: VBoxContainer, screen_id: StringName, key: String) -> void:
	var button := Button.new()
	button.text = tr(key)
	button.custom_minimum_size.y = 50
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void: _show_screen(screen_id))
	parent.add_child(button)
	_screen_buttons[screen_id] = button


func _show_screen(screen_id: StringName) -> void:
	_current_screen = screen_id
	for child in _content.get_children():
		child.queue_free()
	for key in _screen_buttons.keys():
		var button: Button = _screen_buttons[key]
		button.disabled = key == screen_id

	match screen_id:
		SCREEN_MAIN:
			_title.text = tr("ui.main.title")
			_content.add_child(_screen_main())
		SCREEN_SETTINGS:
			_title.text = tr("ui.settings.title")
			_content.add_child(_screen_settings())
		SCREEN_MAP:
			_title.text = tr("ui.map.title")
			_content.add_child(_screen_map())
		SCREEN_SHOP:
			_title.text = tr("ui.shop.title")
			_content.add_child(_screen_shop())
		SCREEN_SKILLS:
			_title.text = tr("ui.skills.title")
			_content.add_child(_screen_skills())
		SCREEN_INVENTORY:
			_title.text = tr("ui.inventory.title")
			_content.add_child(_screen_inventory())
		SCREEN_BATTLE:
			_title.text = tr("ui.battle.title")
			_content.add_child(_screen_battle())
		SCREEN_CHARACTER:
			_title.text = tr("ui.character.title")
			_content.add_child(_screen_character())
		SCREEN_ABOUT:
			_title.text = tr("ui.about.title")
			_content.add_child(_screen_about())


func _screen_main() -> Control:
	var box := _make_panel()
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override(&"separation", 16)
	box.add_child(layout)

	var hero := _make_banner("ui.main.title", "ui.main.subtitle")
	layout.add_child(hero)

	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override(&"h_separation", 12)
	actions.add_theme_constant_override(&"v_separation", 12)
	layout.add_child(actions)

	_add_action(actions, "ui.main.continue", SCREEN_MAP)
	_add_action(actions, "ui.main.new_game", SCREEN_CHARACTER)
	_add_action(actions, "ui.main.settings", SCREEN_SETTINGS)
	_add_action(actions, "ui.main.about", SCREEN_ABOUT)

	var preview := _make_section("ui.main.preview")
	preview.custom_minimum_size.y = 300
	layout.add_child(preview)
	_fill_placeholder_rows(preview, ["ui.placeholder.map", "ui.placeholder.hero", "ui.placeholder.enemy"])
	return box


func _screen_settings() -> Control:
	var tabs := TabContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(_settings_audio())
	tabs.add_child(_settings_ux())
	tabs.add_child(_settings_language())
	return tabs


func _settings_audio() -> Control:
	var panel := _make_panel()
	panel.name = tr("ui.settings.audio")
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 16)
	panel.add_child(box)
	_add_toggle_slider(box, "ui.settings.audio_master")
	_add_toggle_slider(box, "ui.settings.audio_sfx")
	_add_toggle_slider(box, "ui.settings.audio_music")
	return panel


func _settings_ux() -> Control:
	var panel := _make_panel()
	panel.name = tr("ui.settings.ux")
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 16)
	panel.add_child(box)
	_add_slider(box, "ui.settings.effect_speed", 0.5, 1.5, 1.0)
	_add_check(box, "ui.settings.show_hints", true)
	_add_check(box, "ui.settings.guidance", true)
	_add_check(box, "ui.settings.reduce_shake", false)
	_add_check(box, "ui.settings.reduce_flashes", false)
	return panel


func _settings_language() -> Control:
	var panel := _make_panel()
	panel.name = tr("ui.settings.language")
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 12)
	panel.add_child(box)
	box.add_child(_make_label("ui.settings.language_pending", 24, _palette[&"gold"]))
	box.add_child(_make_label("ui.settings.account_pending", 20, _palette[&"muted"]))
	return panel


func _screen_map() -> Control:
	var panel := _make_panel()
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override(&"separation", 12)
	panel.add_child(layout)
	layout.add_child(_make_banner("ui.map.title", "ui.map.subtitle"))

	var map_area := GridContainer.new()
	map_area.columns = 3
	map_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_area.add_theme_constant_override(&"h_separation", 12)
	map_area.add_theme_constant_override(&"v_separation", 12)
	layout.add_child(map_area)

	for key in ["ui.map.node_tavern", "ui.map.node_forest", "ui.map.node_ruins", "ui.map.node_bridge", "ui.map.node_castle", "ui.map.node_market"]:
		map_area.add_child(_make_map_node(key))
	return panel


func _screen_shop() -> Control:
	var panel := _make_panel()
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override(&"separation", 12)
	panel.add_child(layout)
	layout.add_child(_make_banner("ui.shop.title", "ui.shop.subtitle"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", 12)
	grid.add_theme_constant_override(&"v_separation", 12)
	layout.add_child(grid)
	for key in ["ui.shop.potion", "ui.shop.ward", "ui.shop.charm", "ui.shop.armor", "ui.shop.map", "ui.shop.key"]:
		grid.add_child(_make_item_card(key, "ui.common.buy"))
	return panel


func _screen_skills() -> Control:
	var panel := _make_panel()
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override(&"separation", 12)
	panel.add_child(layout)
	var tree := GridContainer.new()
	tree.columns = 3
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.add_theme_constant_override(&"h_separation", 12)
	tree.add_theme_constant_override(&"v_separation", 12)
	layout.add_child(tree)
	for key in ["ui.skills.slash", "ui.skills.guard", "ui.skills.storm", "ui.skills.heal", "ui.skills.tax", "ui.skills.final"]:
		tree.add_child(_make_skill_node(key))
	var details := _make_section("ui.skills.details")
	details.custom_minimum_size.x = 230
	layout.add_child(details)
	_fill_placeholder_rows(details, ["ui.skills.cost", "ui.skills.effect", "ui.skills.status"])
	return panel


func _screen_inventory() -> Control:
	var panel := _make_panel()
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override(&"separation", 12)
	panel.add_child(layout)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override(&"h_separation", 10)
	grid.add_theme_constant_override(&"v_separation", 10)
	layout.add_child(grid)
	for index in range(16):
		grid.add_child(_make_inventory_slot(index))
	var equipment := _make_section("ui.inventory.equipment")
	equipment.custom_minimum_size.x = 220
	layout.add_child(equipment)
	_fill_placeholder_rows(equipment, ["ui.inventory.weapon", "ui.inventory.armor", "ui.inventory.trinket"])
	return panel


func _screen_battle() -> Control:
	var panel := _make_panel()
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override(&"separation", 12)
	panel.add_child(layout)

	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 12)
	layout.add_child(top)
	var retreat := Button.new()
	retreat.text = tr("ui.battle.retreat")
	top.add_child(retreat)
	top.add_child(_make_combatant("ui.battle.enemy", _palette[&"red"]))

	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override(&"separation", 12)
	layout.add_child(middle)
	middle.add_child(_make_chat_box())
	middle.add_child(_make_board())
	middle.add_child(_make_skill_bar(true))

	layout.add_child(_make_combatant("ui.battle.player", _palette[&"blue"]))
	return panel


func _screen_character() -> Control:
	var panel := _make_panel()
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override(&"separation", 12)
	panel.add_child(layout)
	layout.add_child(_make_banner("ui.character.title", "ui.character.subtitle"))
	var choices := GridContainer.new()
	choices.columns = 3
	choices.add_theme_constant_override(&"h_separation", 12)
	layout.add_child(choices)
	for key in ["ui.character.warlord", "ui.character.oracle", "ui.character.raider"]:
		choices.add_child(_make_character_card(key))
	return panel


func _screen_about() -> Control:
	var panel := _make_panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 12)
	panel.add_child(box)
	box.add_child(_make_banner("ui.about.title", "ui.about.subtitle"))
	box.add_child(_make_label("ui.about.body", 22, _palette[&"muted"]))
	return panel


func _add_action(parent: Control, key: String, target: StringName) -> void:
	var button := Button.new()
	button.text = tr(key)
	button.custom_minimum_size = Vector2(220, 72)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void: _show_screen(target))
	parent.add_child(button)


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override(&"margin_left", 18)
	panel.add_theme_constant_override(&"margin_right", 18)
	panel.add_theme_constant_override(&"margin_top", 18)
	panel.add_theme_constant_override(&"margin_bottom", 18)
	panel.add_theme_stylebox_override(&"panel", _style(_palette[&"panel"], 8, _palette[&"line"], 2))
	return panel


func _make_banner(title_key: String, body_key: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 140
	panel.add_theme_stylebox_override(&"panel", _style(_palette[&"panel_dark"], 8, _palette[&"gold"], 2))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 18)
	margin.add_theme_constant_override(&"margin_right", 18)
	margin.add_theme_constant_override(&"margin_top", 14)
	margin.add_theme_constant_override(&"margin_bottom", 14)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)
	margin.add_child(box)
	box.add_child(_make_label(title_key, 32, _palette[&"gold"]))
	box.add_child(_make_label(body_key, 20, _palette[&"muted"]))
	return panel


func _make_section(title_key: String) -> PanelContainer:
	var panel := _make_panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 10)
	panel.add_child(box)
	box.add_child(_make_label(title_key, 24, _palette[&"gold"]))
	return panel


func _fill_placeholder_rows(panel: Control, keys: Array) -> void:
	var box := panel.get_child(0) as VBoxContainer
	for key in keys:
		var row := PanelContainer.new()
		row.custom_minimum_size.y = 54
		row.add_theme_stylebox_override(&"panel", _style(_palette[&"panel_dark"], 6, _palette[&"line"], 1))
		var label := _make_label(key, 18, _palette[&"muted"])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)
		box.add_child(row)


func _make_label(key: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = tr(key)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _make_emblem(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(68, 68)
	panel.add_theme_stylebox_override(&"panel", _style(_palette[&"gold"], 8, _palette[&"text"], 1))
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", 24)
	label.add_theme_color_override(&"font_color", _palette[&"bg"])
	panel.add_child(label)
	return panel


func _make_map_node(key: String) -> Button:
	var button := Button.new()
	button.text = tr(key)
	button.custom_minimum_size = Vector2(150, 120)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _make_item_card(key: String, action_key: String) -> Control:
	var panel := _make_section(key)
	panel.custom_minimum_size = Vector2(150, 190)
	var box := panel.get_child(0) as VBoxContainer
	var icon := ColorRect.new()
	icon.color = _palette[&"panel_dark"]
	icon.custom_minimum_size.y = 80
	box.add_child(icon)
	var button := Button.new()
	button.text = tr(action_key)
	box.add_child(button)
	return panel


func _make_skill_node(key: String) -> Button:
	var button := Button.new()
	button.text = tr(key)
	button.custom_minimum_size = Vector2(150, 110)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _make_inventory_slot(index: int) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(86, 86)
	slot.add_theme_stylebox_override(&"panel", _style(_palette[&"panel_dark"], 6, _palette[&"line"], 1))
	var label := Label.new()
	label.text = str(index + 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override(&"font_color", _palette[&"muted"])
	slot.add_child(label)
	return slot


func _make_character_card(key: String) -> Control:
	var panel := _make_section(key)
	panel.custom_minimum_size = Vector2(180, 300)
	var box := panel.get_child(0) as VBoxContainer
	var portrait := ColorRect.new()
	portrait.color = _palette[&"panel_dark"]
	portrait.custom_minimum_size.y = 160
	box.add_child(portrait)
	var choose := Button.new()
	choose.text = tr("ui.character.choose")
	choose.pressed.connect(func() -> void: _show_screen(SCREEN_MAP))
	box.add_child(choose)
	return panel


func _make_combatant(key: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(&"panel", _style(_palette[&"panel_dark"], 6, color, 2))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 12)
	margin.add_theme_constant_override(&"margin_right", 12)
	margin.add_theme_constant_override(&"margin_top", 10)
	margin.add_theme_constant_override(&"margin_bottom", 10)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)
	margin.add_child(box)
	box.add_child(_make_label(key, 22, _palette[&"text"]))
	box.add_child(_make_bar(_palette[&"red"], 0.72, "HP 72/100"))
	box.add_child(_make_bar(_palette[&"blue"], 0.45, "EN 45/100"))
	return panel


func _make_bar(color: Color, value: float, label_text: String) -> Control:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size.y = 28
	bar.add_theme_stylebox_override(&"fill", _style(color, 4, color, 0))
	bar.add_theme_stylebox_override(&"background", _style(_palette[&"panel"], 4, _palette[&"line"], 1))
	bar.tooltip_text = label_text
	return bar


func _make_chat_box() -> Control:
	var panel := _make_section("ui.battle.dialogue")
	panel.custom_minimum_size.x = 170
	_fill_placeholder_rows(panel, ["ui.battle.dialogue_sample"])
	return panel


func _make_board() -> Control:
	var wrapper := CenterContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var board := BoardViewScript.new()
	board.tile_size = 50.0
	board.tile_gap = 5.0
	wrapper.add_child(board)
	return wrapper


func _make_skill_bar(vertical: bool) -> Control:
	var box: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	box.custom_minimum_size.x = 170
	box.add_theme_constant_override(&"separation", 8)
	for key in ["ui.battle.skill_1", "ui.battle.skill_2", "ui.battle.skill_3", "ui.battle.skill_4"]:
		var button := Button.new()
		button.text = tr(key)
		button.custom_minimum_size.y = 58
		box.add_child(button)
	return box


func _add_toggle_slider(parent: VBoxContainer, key: String) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	parent.add_child(row)
	_add_check(row, key, true)
	_add_slider(row, key + "_volume", 0.0, 1.0, 0.8)


func _add_check(parent: VBoxContainer, key: String, enabled: bool) -> void:
	var check := CheckBox.new()
	check.text = tr(key)
	check.button_pressed = enabled
	parent.add_child(check)


func _add_slider(parent: VBoxContainer, key: String, min_value: float, max_value: float, current: float) -> void:
	var label := _make_label(key, 18, _palette[&"muted"])
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.05
	slider.value = current
	slider.custom_minimum_size.y = 36
	parent.add_child(slider)


func _build_theme() -> Theme:
	var new_theme := Theme.new()
	new_theme.default_font_size = 22
	new_theme.set_color(&"font_color", &"Label", _palette[&"text"])
	new_theme.set_color(&"font_color", &"Button", _palette[&"text"])
	new_theme.set_color(&"font_disabled_color", &"Button", _palette[&"gold"])
	new_theme.set_stylebox(&"normal", &"Button", _style(_palette[&"panel"], 6, _palette[&"line"], 1))
	new_theme.set_stylebox(&"hover", &"Button", _style(_palette[&"panel"].lightened(0.08), 6, _palette[&"gold"], 2))
	new_theme.set_stylebox(&"pressed", &"Button", _style(_palette[&"panel_dark"], 6, _palette[&"gold"], 2))
	new_theme.set_stylebox(&"disabled", &"Button", _style(_palette[&"panel_dark"], 6, _palette[&"gold"], 2))
	new_theme.set_stylebox(&"panel", &"PanelContainer", _style(_palette[&"panel"], 8, _palette[&"line"], 1))
	new_theme.set_stylebox(&"panel", &"MarginContainer", _style(_palette[&"panel"], 8, _palette[&"line"], 1))
	new_theme.set_constant(&"separation", &"VBoxContainer", 10)
	new_theme.set_constant(&"separation", &"HBoxContainer", 10)
	return new_theme


func _style(bg: Color, radius: int, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
