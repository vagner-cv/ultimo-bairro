extends Control

const ITEMS = preload("res://src/systems/items.gd")
var game: Node
var target: Node2D
var frame: PanelContainer
var title: Label
var subtitle: Label
var source_label: Label
var source_list: ItemList
var player_list: ItemList
var quantity: SpinBox
var selected_source: String = ""
var selected_player: String = ""
var status: Label
var take_button: Button
var store_button: Button
var take_all_button: Button
var use_button: Button
var equip_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = Color(.012, .028, .026, .82)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	frame = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("142723")
	style.border_color = Color("8d9474")
	style.set_border_width_all(1)
	style.set_content_margin_all(24)
	style.set_corner_radius_all(8)
	frame.add_theme_stylebox_override("panel", style)
	add_child(frame)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	frame.add_child(layout)
	title = Label.new()
	title.add_theme_font_size_override("font_size", 26)
	layout.add_child(title)
	subtitle = Label.new()
	subtitle.text = "Carregamento sem limite · selecione um item para usar, equipar ou transferir."
	subtitle.add_theme_color_override("font_color", Color("b5b9a5"))
	subtitle.add_theme_font_size_override("font_size", 12)
	layout.add_child(subtitle)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 20)
	layout.add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	source_label = Label.new()
	left.add_child(source_label)
	source_list = _list(left)
	source_list.item_selected.connect(func(index: int) -> void: selected_source = source_list.get_item_metadata(index); _update_buttons())
	source_list.item_activated.connect(func(_index: int) -> void: _take())
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	var heading := Label.new()
	heading.text = "SEUS ITENS  /  SEM LIMITE"
	right.add_child(heading)
	player_list = _list(right)
	player_list.item_selected.connect(func(index: int) -> void: selected_player = player_list.get_item_metadata(index); _update_buttons())
	player_list.item_activated.connect(func(_index: int) -> void: _activate())
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	layout.add_child(actions)
	var quantity_label := Label.new()
	quantity_label.text = "Quantidade:"
	actions.add_child(quantity_label)
	quantity = SpinBox.new()
	quantity.min_value = 1
	quantity.max_value = 1000000000
	quantity.value = 1
	quantity.custom_minimum_size.x = 98
	actions.add_child(quantity)
	take_button = _button(actions, "PEGAR →", _take)
	store_button = _button(actions, "← GUARDAR", _store)
	take_all_button = _button(actions, "PEGAR TUDO", _take_all)
	var player_actions := HBoxContainer.new()
	player_actions.add_theme_constant_override("separation", 10)
	layout.add_child(player_actions)
	use_button = _button(player_actions, "USAR ERVA", _use)
	equip_button = _button(player_actions, "EQUIPAR", _equip)
	var close_button := _button(player_actions, "FECHAR [I / ESC]", func() -> void: game.close_inventory())
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status = Label.new()
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override("font_color", Color("dfb579"))
	layout.add_child(status)
	resized.connect(_layout)
	_layout()
	hide()

func _list(parent: Control) -> ItemList:
	var list := ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size = Vector2(300, 220)
	list.fixed_icon_size = Vector2i(44, 44)
	list.allow_search = false
	list.add_theme_constant_override("v_separation", 7)
	list.add_theme_font_size_override("font_size", 13)
	parent.add_child(list)
	return list

func _button(parent: Control, label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _layout() -> void:
	frame.position = Vector2(40, 42)
	frame.size = size - Vector2(80, 84)

func open(container: Node2D = null) -> void:
	target = container
	selected_source = ""
	selected_player = ""
	status.text = "O jogo fica pausado enquanto você organiza os itens."
	refresh()
	show()

func refresh() -> void:
	title.text = target.caption if is_instance_valid(target) else "Inventário de Leon"
	source_label.text = "CONTEÚDO DO RECIPIENTE" if is_instance_valid(target) else "ABRA UM RECIPIENTE COM E PARA VASCULHAR"
	source_list.clear()
	player_list.clear()
	if is_instance_valid(target):
		_fill(source_list, target.inventory, selected_source)
	_fill(player_list, game.inventory, selected_player)
	_update_buttons()

func _fill(list: ItemList, inventory: RefCounted, selected: String) -> void:
	for id: String in inventory.stacks:
		var label := "%s  × %d" % [ITEMS.label(id), inventory.count(id)]
		if id == game.player.weapon_id:
			label += "   [equipada]"
		var index := list.add_item(label, ITEMS.icon(id))
		list.set_item_metadata(index, id)
		if id == selected:
			list.select(index)

func _update_buttons() -> void:
	var has_source := is_instance_valid(target)
	take_button.disabled = not has_source or selected_source.is_empty() or target.inventory.count(selected_source) == 0
	store_button.disabled = not has_source or selected_player.is_empty() or selected_player == "knife" or game.inventory.count(selected_player) == 0
	take_all_button.disabled = not has_source or target.inventory.is_empty()
	use_button.disabled = selected_player != "herb" or game.inventory.count("herb") == 0 or game.player.health >= 100
	equip_button.disabled = not ITEMS.DATA.has(selected_player) or ITEMS.DATA[selected_player].kind != "weapon" or game.inventory.count(selected_player) == 0

func _take() -> void:
	if not is_instance_valid(target):
		return
	var amount: int = mini(int(quantity.value), target.inventory.count(selected_source))
	if target.inventory.transfer_to(game.inventory, selected_source, amount):
		status.text = "Recolhido: %s × %d" % [ITEMS.label(selected_source), amount]
	refresh()

func _store() -> void:
	if not is_instance_valid(target) or selected_player == "knife":
		return
	var amount: int = mini(int(quantity.value), game.inventory.count(selected_player))
	if game.inventory.transfer_to(target.inventory, selected_player, amount):
		status.text = "Guardado: %s × %d" % [ITEMS.label(selected_player), amount]
		if selected_player == game.player.weapon_id and game.inventory.count(selected_player) == 0:
			game.player.equip("knife")
	refresh()

func _take_all() -> void:
	if is_instance_valid(target):
		target.inventory.transfer_all_to(game.inventory)
		status.text = "Todos os itens foram recolhidos."
	refresh()

func _activate() -> void:
	if selected_player == "herb":
		_use()
	else:
		_equip()

func _use() -> void:
	if game.use_item(selected_player):
		status.text = "Erva utilizada. Vida: %d / 100" % game.player.health
	refresh()

func _equip() -> void:
	if game.player.equip(selected_player):
		status.text = "Equipada: " + ITEMS.label(selected_player)
	refresh()
