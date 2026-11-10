extends Control

const PAPER := Color("e5e1cd")
const MUTED := Color("9daea0")
const ACCENT := Color("dfb579")
const DARK := Color("142723")
const REGULAR: Font = preload("res://art/regular.ttf")
const BOLD: Font = preload("res://art/bold.ttf")
const PISTOL: Texture2D = preload("res://art/vendor/craftpix/pistol.png")

var game: Node
var screen: String = "title"
var previous_screen: String = "title"
var primary: Button
var secondary: Button
var third: Button
var quit_button: Button
var pause_button: Button
var volume_slider: HSlider
var hit_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := Theme.new()
	style.default_font = REGULAR
	style.default_font_size = 15
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("1e3630")
	normal.border_color = Color("536352")
	normal.set_border_width_all(1)
	normal.set_content_margin_all(12)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("344a3d")
	hover.border_color = ACCENT
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("52604a")
	style.set_stylebox("normal", "Button", normal)
	style.set_stylebox("hover", "Button", hover)
	style.set_stylebox("focus", "Button", hover)
	style.set_stylebox("pressed", "Button", pressed)
	style.set_color("font_color", "Button", PAPER)
	style.set_color("font_hover_color", "Button", Color.WHITE)
	theme = style
	primary = _button(_primary_pressed)
	secondary = _button(_secondary_pressed)
	third = _button(func() -> void: open_help())
	quit_button = _button(func() -> void: game.quit_game())
	quit_button.text = "SAIR DO JOGO"
	pause_button = _button(func() -> void: game.toggle_pause())
	pause_button.text = "ESC  /  PAUSA"
	pause_button.add_theme_font_size_override("font_size", 12)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = 1
	volume_slider.value = 70
	volume_slider.value_changed.connect(func(value: float) -> void: game.audio.set_volume(value / 100.0))
	add_child(volume_slider)
	show_screen("title")

func _button(callback: Callable) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	add_child(button)
	return button

func show_screen(mode: String) -> void:
	screen = mode
	_layout()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if screen == "none" and not game.dialogue_active else Input.MOUSE_MODE_VISIBLE
	if screen != "none":
		primary.grab_focus()
	else:
		primary.release_focus()
	queue_redraw()

func _layout() -> void:
	var w := size.x
	var h := size.y
	primary.visible = screen != "none"
	secondary.visible = screen in ["title", "pause", "dead"]
	third.visible = screen == "pause"
	quit_button.visible = screen == "pause"
	volume_slider.visible = screen == "pause"
	pause_button.visible = screen == "none" and not game.dialogue_active
	pause_button.position = Vector2(w - 182, h - 58)
	pause_button.size = Vector2(150, 30)
	if screen in ["title", "dead"]:
		primary.position = Vector2(90, h - 174)
		primary.size = Vector2(318, 54)
		secondary.position = Vector2(90, h - 108)
		secondary.size = Vector2(200, 42)
		secondary.text = "CONTROLES"
		primary.text = "COMEÇAR EXPLORAÇÃO" if screen == "title" else "TENTAR NOVAMENTE"
	elif screen == "pause":
		primary.position = Vector2(w / 2 - 190, h / 2 - 85)
		primary.size = Vector2(380, 48)
		primary.text = "CONTINUAR"
		secondary.position = primary.position + Vector2(0, 61)
		secondary.size = Vector2(185, 40)
		secondary.text = "RECOMEÇAR"
		third.position = secondary.position + Vector2(195, 0)
		third.size = Vector2(185, 40)
		third.text = "CONTROLES"
		volume_slider.position = primary.position + Vector2(0, 151)
		volume_slider.size = Vector2(380, 24)
		quit_button.position = primary.position + Vector2(0, 196)
		quit_button.size = Vector2(380, 36)
	elif screen == "help":
		primary.position = Vector2(w / 2 - 230, h / 2 + 192)
		primary.size = Vector2(460, 44)
		primary.text = "VOLTAR"

func _primary_pressed() -> void:
	match screen:
		"title": game.begin()
		"pause": game.toggle_pause()
		"dead": game.restart()
		"help": show_screen(previous_screen)

func _secondary_pressed() -> void:
	if screen == "pause":
		game.restart()
	else:
		open_help()

func open_help() -> void:
	previous_screen = screen
	show_screen("help")

func mark_hit() -> void:
	hit_timer = .14

func _process(delta: float) -> void:
	hit_timer = maxf(0, hit_timer - delta)
	_layout()
	queue_redraw()

func text_at(value: String, at: Vector2, pixels: int = 14, color: Color = PAPER, bold: bool = false) -> void:
	draw_string(BOLD if bold else REGULAR, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, color)

func panel(rect: Rect2, color: Color = Color(.055, .115, .10, .94)) -> void:
	draw_rect(rect, color)
	draw_rect(rect, Color(.51, .59, .46, .35), false, 1)

func _draw() -> void:
	if not is_instance_valid(game.player):
		return
	var w := size.x
	var h := size.y
	if screen == "none":
		_draw_game(w, h)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(.025, .055, .05, .83 if screen in ["title", "dead"] else .73))
		if screen in ["title", "dead"]:
			_draw_title(w, h)
		elif screen == "pause":
			panel(Rect2(w / 2 - 230, h / 2 - 210, 460, 380))
			text_at("UM INSTANTE DE SILÊNCIO", Vector2(w / 2 - 190, h / 2 - 155), 12, ACCENT, true)
			text_at("Jogo pausado", Vector2(w / 2 - 190, h / 2 - 113), 28, PAPER, true)
			text_at("VOLUME", Vector2(w / 2 - 190, h / 2 + 53), 11, MUTED, true)
		elif screen == "help":
			_draw_help(w, h)

func _draw_title(w: float, h: float) -> void:
	draw_line(Vector2(90, 86), Vector2(150, 86), ACCENT, 3)
	text_at("UM PROTÓTIPO DE SOBREVIVÊNCIA", Vector2(168, 92), 12, ACCENT, true)
	if screen == "title":
		text_at("ÚLTIMO", Vector2(84, 232), 76, PAPER, true)
		text_at("BAIRRO", Vector2(84, 310), 76, PAPER, true)
		text_at("UM DIA DE CADA VEZ.", Vector2(92, 360), 16, ACCENT, true)
		draw_multiline_string(REGULAR, Vector2(92, 401), "As ruas são as mesmas. O mundo, não.\nSaia de casa, encontre outros sobreviventes\ne descubra o que restou de Vila Aurora.", HORIZONTAL_ALIGNMENT_LEFT, 560, 17, -1, MUTED)
	else:
		text_at("O BAIRRO FICOU", Vector2(88, 225), 42, PAPER, true)
		text_at("EM SILÊNCIO.", Vector2(88, 281), 48, PAPER, true)
		text_at("VOCÊ NÃO SOBREVIVEU DESTA VEZ.", Vector2(92, 340), 14, ACCENT, true)
		text_at("Infectados eliminados: %02d   /   Tempo: %s" % [game.kills, _time(game.elapsed)], Vector2(92, 392), 17, MUTED)
	var x := maxf(760, w - 432)
	panel(Rect2(x, 205, 340, 280), Color(.08, .15, .13, .82))
	text_at("RELATÓRIO DE CAMPO", Vector2(x + 26, 242), 11, ACCENT, true)
	text_at("Vila Aurora", Vector2(x + 26, 285), 28, PAPER, true)
	text_at("DIA 01   /   17:42", Vector2(x + 26, 316), 13, MUTED)
	draw_line(Vector2(x + 26, 337), Vector2(x + 314, 337), Color("4a5b47"), 1)
	text_at("01   EXPLORE O BAIRRO", Vector2(x + 26, 370), 12, PAPER, true)
	text_at("02   ENCONTRE MARA", Vector2(x + 26, 409), 12, PAPER, true)
	text_at("03   MANTENHA DISTÂNCIA", Vector2(x + 26, 448), 12, PAPER, true)
	text_at("VERSÃO 0.2.0  /  KIT CRAFTPIX", Vector2(92, h - 27), 10, MUTED)
	text_at("WASD + MOUSE  ·  F11 TELA CHEIA", Vector2(w - 340, h - 27), 10, MUTED)

func _draw_help(w: float, h: float) -> void:
	var x := w / 2 - 270
	var y := h / 2 - 268
	panel(Rect2(x, y, 540, 540))
	text_at("ANTES DE SAIR", Vector2(x + 40, y + 42), 12, ACCENT, true)
	text_at("Conheça os controles", Vector2(x + 40, y + 81), 26, PAPER, true)
	var controls := [["W A S D / SETAS", "Caminhar"], ["MOUSE / RODA", "Mirar / ajustar zoom"], ["BOTÃO ESQUERDO", "Atirar / segure para repetir"], ["E", "Abrir portas / conversar"], ["ESC", "Pausar / fechar diálogo"], ["M", "Ligar ou desligar o som"], ["F11", "Alternar tela cheia"]]
	for i in range(controls.size()):
		var row_y: float = y + 129 + i * 39
		text_at(controls[i][0], Vector2(x + 40, row_y), 11, ACCENT, true)
		text_at(controls[i][1], Vector2(x + 215, row_y), 12, PAPER)
	text_at("Munição infinita. Sem coleta ou inventário nesta versão.", Vector2(x + 40, y + 430), 11, MUTED)

func _draw_game(w: float, h: float) -> void:
	# Small edge panels keep the center of the play area unobstructed.
	panel(Rect2(24, 24, 300, 69))
	draw_rect(Rect2(24, 24, 3, 69), ACCENT)
	text_at("ÚLTIMO BAIRRO", Vector2(43, 52), 18, PAPER, true)
	text_at("VILA AURORA  /  DIA 01", Vector2(44, 76), 10, MUTED, true)
	panel(Rect2(24, 105, 300, 63), Color(.055, .115, .10, .86))
	var title := "PRIMEIRO CONTATO"
	var detail := "Encontre Mara perto da casa."
	if game.met_mara:
		title = "RUA EM SILÊNCIO"
		detail = "Explore e elimine os infectados."
	if game.remaining == 0:
		title = "BAIRRO SEGURO"
		detail = "Área limpa. Explore livremente."
	text_at(title, Vector2(43, 128), 10, ACCENT, true)
	text_at(detail, Vector2(43, 151), 12, PAPER)
	_draw_minimap(w - 210, 24)
	# Health, status and weapon.
	panel(Rect2(24, h - 98, 264, 74))
	draw_rect(Rect2(42, h - 76, 28, 28), Color("344b3b"))
	draw_rect(Rect2(53, h - 71, 6, 18), ACCENT)
	draw_rect(Rect2(47, h - 65, 18, 6), ACCENT)
	text_at("VITALIDADE", Vector2(84, h - 72), 10, MUTED, true)
	text_at("%03d / 100" % game.player.health, Vector2(182, h - 72), 11, PAPER, true)
	draw_rect(Rect2(84, h - 60, 184, 8), Color("344a3a"))
	var health_color := ACCENT if game.player.health > 30 else Color("d16d52")
	draw_rect(Rect2(84, h - 60, 184.0 * game.player.health / 100.0, 8), health_color)
	text_at("EM MOVIMENTO" if game.player.velocity.length() > 0 else "MANTENHA A CALMA", Vector2(84, h - 34), 9, MUTED)
	panel(Rect2(w - 276, h - 144, 252, 74))
	draw_texture_rect(PISTOL, Rect2(w - 260, h - 123, 52, 35), false)
	text_at("PISTOLA 9 mm", Vector2(w - 195, h - 116), 11, MUTED, true)
	text_at("∞", Vector2(w - 198, h - 84), 29, ACCENT, true)
	text_at("MUNIÇÃO INFINITA", Vector2(w - 164, h - 88), 9, PAPER)
	text_at("WASD  MOVER    MOUSE  MIRAR    E  INTERAGIR", Vector2(w / 2 - 190, h - 28), 10, MUTED)
	if game.dialogue_active:
		_draw_dialogue(w, h)
	elif is_instance_valid(game.nearby):
		var caption: String = game.nearby.interaction_text()
		var length := REGULAR.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		panel(Rect2(w / 2 - length / 2 - 35, h - 135, length + 82, 42))
		draw_rect(Rect2(w / 2 - length / 2 - 25, h - 126, 25, 24), ACCENT)
		text_at("E", Vector2(w / 2 - length / 2 - 18, h - 109), 13, DARK, true)
		text_at(caption, Vector2(w / 2 - length / 2 + 12, h - 108), 14, PAPER)
	if game.player.invulnerable > 0:
		var alpha: float = game.player.invulnerable * .11
		draw_rect(Rect2(Vector2.ZERO, size), Color(.7, .17, .11, alpha))
	if not game.dialogue_active:
		var at := get_local_mouse_position()
		var col := ACCENT if hit_timer > 0 else PAPER
		for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			draw_line(at + dir * 6, at + dir * 12, Color(.02, .06, .04, .9), 4)
			draw_line(at + dir * 6, at + dir * 11, col, 2)
		draw_rect(Rect2(at - Vector2.ONE, Vector2(2, 2)), col)
		if hit_timer > 0:
			draw_circle(at, 17, Color(ACCENT, .6), false, 1)

func _draw_minimap(x: float, y: float) -> void:
	panel(Rect2(x, y, 186, 176))
	text_at("VILA AURORA", Vector2(x + 12, y + 23), 10, PAPER, true)
	var origin := Vector2(x + 12, y + 36)
	var scale_map := Vector2(162.0 / 2304.0, 108.0 / 1536.0)
	draw_rect(Rect2(origin, Vector2(162, 108)), Color("304839"))
	draw_rect(Rect2(origin + Vector2(0, 640) * scale_map, Vector2(162, 160 * scale_map.y)), Color("67756b"))
	draw_rect(Rect2(origin + Vector2(960, 0) * scale_map, Vector2(160 * scale_map.x, 108)), Color("67756b"))
	for house in game.world.houses:
		var rect: Rect2 = house.rect
		draw_rect(Rect2(origin + rect.position * scale_map, rect.size * scale_map), Color("a49c7b"))
	draw_circle(origin + Vector2(466, 548) * scale_map, 2, Color("99c1b1"))
	var player_pos: Vector2 = origin + game.player.global_position * scale_map
	draw_circle(player_pos, 4, Color("1d322b"))
	draw_circle(player_pos, 2.5, ACCENT)
	text_at("%02d INFECTADOS  /  %s" % [game.remaining, _time(game.elapsed)], Vector2(x + 12, y + 162), 9, MUTED)

func _draw_dialogue(w: float, h: float) -> void:
	var rect := Rect2(w / 2 - 350, h - 216, 700, 154)
	panel(rect)
	draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), ACCENT)
	text_at(game.dialogue_name, rect.position + Vector2(24, 31), 13, ACCENT, true)
	draw_multiline_string(REGULAR, rect.position + Vector2(24, 61), _wrap(game.dialogue_lines[game.dialogue_index], 650, 16), HORIZONTAL_ALIGNMENT_LEFT, 650, 16, -1, PAPER)
	text_at("E  CONTINUAR    /    ESC  ENCERRAR", rect.position + Vector2(24, 133), 10, MUTED)

func _wrap(value: String, width: float, pixels: int) -> String:
	var output := ""
	var line := ""
	for word in value.split(" "):
		var candidate: String = word if line.is_empty() else line + " " + word
		if REGULAR.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x > width and not line.is_empty():
			output += line + "\n"
			line = word
		else:
			line = candidate
	return output + line

func _time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
