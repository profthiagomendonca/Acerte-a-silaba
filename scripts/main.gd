extends Control

# Banco de dados simplificado: apenas as sílabas e o caminho da imagem.
# O jogo agora decide onde colocar a lacuna e quais as opções em tempo real.
var all_levels_data = {}
var game_queue = []
var progress_in_game = 0 # 0 a 21 (total 22)

var current_level = 0
var completed = false

# Variáveis do estado atual da fase (sorteadas dinamicamente)
var current_missing_idx = 0
var current_correct_syllable = ""

# UI Elements
var bg_rect : TextureRect
var menu_vbox : VBoxContainer
var game_vbox : VBoxContainer

# Game Elements
var image_rect : TextureRect
var word_container : HBoxContainer
var options_container : HBoxContainer
var feedback_label : Label
var mascot_rect : TextureRect
var progress_bar : ProgressBar

@onready var music_player = $MusicPlayer
@onready var sfx_correct = $SfxCorrect
@onready var sfx_error = $SfxError

func _ready():
	_load_json_data()
	_setup_audio_loop()
	_build_base_ui()
	_show_menu()

func _load_json_data():
	var file = FileAccess.open("res://assets/data/levels.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		all_levels_data = JSON.parse_string(content)
		file.close()
	else:
		push_error("Não foi possível carregar o arquivo levels.json")

func _setup_audio_loop():
	if music_player:
		music_player.finished.connect(func(): music_player.play())

func _build_base_ui():
	bg_rect = TextureRect.new()
	bg_rect.set_anchors_preset(PRESET_FULL_RECT)
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg_rect)
	
	menu_vbox = VBoxContainer.new()
	menu_vbox.set_anchors_preset(PRESET_FULL_RECT)
	menu_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_vbox.add_theme_constant_override("separation", 50)
	add_child(menu_vbox)
	
	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 50)
	menu_vbox.add_child(spacer_top)
	
	var btn_start = Button.new()
	btn_start.text = "INICIAR JOGO"
	btn_start.custom_minimum_size = Vector2(350, 100)
	btn_start.add_theme_font_size_override("font_size", 50)
	btn_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Estilo Lúdico 3D (Botão Laranja)
	var styl_n = StyleBoxFlat.new()
	styl_n.bg_color = Color(1.0, 0.6, 0.1) # Laranja
	styl_n.corner_radius_top_left = 50
	styl_n.corner_radius_top_right = 50
	styl_n.corner_radius_bottom_left = 50
	styl_n.corner_radius_bottom_right = 50
	styl_n.border_width_bottom = 12
	styl_n.border_color = Color(0.8, 0.4, 0.0) # Sombra
	styl_n.shadow_color = Color(0, 0, 0, 0.25)
	styl_n.shadow_size = 10
	styl_n.shadow_offset = Vector2(0, 5)
	
	var styl_h = styl_n.duplicate()
	styl_h.bg_color = Color(1.0, 0.7, 0.2)
	
	btn_start.add_theme_stylebox_override("normal", styl_n)
	btn_start.add_theme_stylebox_override("hover", styl_h)
	btn_start.add_theme_stylebox_override("pressed", styl_n)
	
	btn_start.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	btn_start.add_theme_constant_override("outline_size", 10)
	btn_start.add_theme_color_override("font_outline_color", Color(0.8, 0.4, 0.0))
	
	btn_start.pressed.connect(self._start_game)
	menu_vbox.add_child(btn_start)
	
	game_vbox = VBoxContainer.new()
	game_vbox.set_anchors_preset(PRESET_FULL_RECT)
	game_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	game_vbox.add_theme_constant_override("separation", 15)
	game_vbox.visible = false
	add_child(game_vbox)
	
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(600, 20)
	progress_bar.show_percentage = false
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.8, 0.8, 0.8, 0.3)
	style_bg.corner_radius_top_left = 15
	style_bg.corner_radius_top_right = 15
	style_bg.corner_radius_bottom_left = 15
	style_bg.corner_radius_bottom_right = 15
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(1.0, 0.8, 0.1) # Dourado
	style_fg.corner_radius_top_left = 15
	style_fg.corner_radius_top_right = 15
	style_fg.corner_radius_bottom_left = 15
	style_fg.corner_radius_bottom_right = 15
	progress_bar.add_theme_stylebox_override("background", style_bg)
	progress_bar.add_theme_stylebox_override("fill", style_fg)
	game_vbox.add_child(progress_bar)
	
	image_rect = TextureRect.new()
	image_rect.custom_minimum_size = Vector2(250, 250)
	image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	game_vbox.add_child(image_rect)
	
	word_container = HBoxContainer.new()
	word_container.alignment = BoxContainer.ALIGNMENT_CENTER
	word_container.add_theme_constant_override("separation", 15)
	
	var word_panel = PanelContainer.new()
	word_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 1.0, 1.0, 0.8) # Branco translúcido
	panel_style.corner_radius_top_left = 30
	panel_style.corner_radius_top_right = 30
	panel_style.corner_radius_bottom_left = 30
	panel_style.corner_radius_bottom_right = 30
	panel_style.content_margin_left = 50
	panel_style.content_margin_right = 50
	panel_style.content_margin_top = 15
	panel_style.content_margin_bottom = 15
	word_panel.add_theme_stylebox_override("panel", panel_style)
	
	word_panel.add_child(word_container)
	game_vbox.add_child(word_panel)
	
	var spacer_game = Control.new()
	spacer_game.custom_minimum_size = Vector2(0, 10)
	game_vbox.add_child(spacer_game)
	
	options_container = HBoxContainer.new()
	options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	options_container.add_theme_constant_override("separation", 20)
	game_vbox.add_child(options_container)
	
	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 40)
	feedback_label.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	game_vbox.add_child(feedback_label)
	
	# Mascotinho Professor
	mascot_rect = TextureRect.new()
	mascot_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot_rect.custom_minimum_size = Vector2(300, 300)
	mascot_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Posicionamento no Canto Inferior Direito
	mascot_rect.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	mascot_rect.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	mascot_rect.grow_vertical = Control.GROW_DIRECTION_BEGIN
	mascot_rect.offset_left = -300
	mascot_rect.offset_top = -300
	add_child(mascot_rect)
	
	# --- SISTEMA DE ÁUDIO ---
	# Configurado via Cena (main.tscn) para garantir exportação.
	# Acessado via @onready var no topo do script.
	if music_player and music_player.stream:
		music_player.play() # Começa na abertura (menu)

func _show_menu():
	menu_vbox.visible = true
	game_vbox.visible = false
	var tex = load("res://assets/images/Fundo.png")
	if tex: bg_rect.texture = tex
	_update_mascot("res://assets/images/Mascote_menu.png")
	music_player.volume_db = 0 # Volume normal no menu

func _start_game():
	menu_vbox.visible = false
	game_vbox.visible = true
	var tex = load("res://assets/images/Fundo 2.png")
	if tex: bg_rect.texture = tex
	
	music_player.volume_db = -25 # Fica bem baixinho para não poluir
	_update_mascot("res://assets/images/Mascote_menu.png")
	
	_prepare_game_queue()
	
	progress_in_game = 0
	completed = false
	_load_level(progress_in_game)

func _prepare_game_queue():
	game_queue = []
	randomize()
	
	# Regra: 7x2, 7x3, 6x4, 2x5
	game_queue.append_array(_get_random_samples("2", 7))
	game_queue.append_array(_get_random_samples("3", 7))
	game_queue.append_array(_get_random_samples("4", 6))
	game_queue.append_array(_get_random_samples("5", 2))

func _get_random_samples(category: String, count: int) -> Array:
	if not all_levels_data.has(category):
		return []
	
	var pool = all_levels_data[category].duplicate()
	pool.shuffle()
	
	var samples = []
	for i in range(min(count, pool.size())):
		samples.append(pool[i])
	return samples

func _do_restart(btn: Node, part: Node):
	btn.queue_free()
	part.queue_free()
	_show_menu()

func _generate_options(correct_syllable: String) -> Array:
	var vowels = "aeiouáéíóúâêôãõAEIOUÁÉÍÓÚÂÊÔÃÕ"
	var vowel_replacements = ["A", "E", "I", "O", "U"]
	
	# Localiza índices das vogais na sílaba
	var vowel_indices = []
	for i in range(correct_syllable.length()):
		if vowels.find(correct_syllable[i]) != -1:
			vowel_indices.append(i)
	
	var options = [correct_syllable]
	
	if vowel_indices.size() > 0:
		var last_v_idx = vowel_indices[-1]
		var original_v = correct_syllable[last_v_idx].to_upper()
		
		var pool = []
		for v in vowel_replacements:
			if v != original_v:
				pool.append(v)
		pool.shuffle()
		
		# Cria 2 distratores mudando apenas a vogal (Método Silábico)
		for i in range(min(2, pool.size())):
			var distractor = correct_syllable.left(last_v_idx) + pool[i] + correct_syllable.right(correct_syllable.length() - last_v_idx - 1)
			options.append(distractor)
	else:
		options.append("X1")
		options.append("X2")
	
	options.shuffle()
	return options

func _load_level(idx):
	if progress_bar: progress_bar.max_value = game_queue.size()
	
	if idx >= game_queue.size():
		var final_image = load("res://assets/images/Fim de jogo.png")
		if final_image: bg_rect.texture = final_image
		game_vbox.visible = false
		_update_mascot("res://assets/images/Mascote_fim_de_jogo.png")
		music_player.volume_db = 0 # Volta a música alta na vitória!
		completed = true
		
		# Confetes
		var particles = CPUParticles2D.new()
		var tex = PlaceholderTexture2D.new(); tex.size = Vector2(15, 15)
		particles.texture = tex
		particles.position = Vector2(size.x / 2, size.y)
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = Vector2(size.x / 2, 10)
		particles.direction = Vector2(0, -1)
		particles.gravity = Vector2(0, 800)
		particles.initial_velocity_min = 500
		particles.initial_velocity_max = 1000
		particles.amount = 200
		particles.one_shot = true
		particles.explosiveness = 0.8
		particles.hue_variation_min = -1.0; particles.hue_variation_max = 1.0
		add_child(particles); particles.emitting = true
		
		# Botão Reset
		var btn_restart = Button.new()
		btn_restart.text = "JOGAR DE NOVO"
		btn_restart.custom_minimum_size = Vector2(350, 90)
		btn_restart.add_theme_font_size_override("font_size", 45)
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = Color(0.2, 0.75, 0.3)
		b_style.corner_radius_top_left = 50; b_style.corner_radius_top_right = 50
		b_style.corner_radius_bottom_left = 50; b_style.corner_radius_bottom_right = 50
		b_style.border_width_bottom = 12; b_style.border_color = Color(0.1, 0.5, 0.1)
		btn_restart.add_theme_stylebox_override("normal", b_style)
		btn_restart.add_theme_stylebox_override("hover", b_style)
		btn_restart.add_theme_color_override("font_color", Color(1, 1, 1))
		btn_restart.set_anchors_preset(PRESET_CENTER_BOTTOM)
		btn_restart.offset_left = -175; btn_restart.offset_right = 175
		btn_restart.offset_bottom = -50; btn_restart.offset_top = -140
		add_child(btn_restart)
		btn_restart.pressed.connect(self._do_restart.bind(btn_restart, particles))
		return
		
	var tw = create_tween()
	tw.tween_property(progress_bar, "value", float(idx), 0.5).set_trans(Tween.TRANS_QUAD)
		
	var level_data = game_queue[idx]
	feedback_label.text = ""
	_update_mascot("res://assets/images/Mascote_pensando.png")
	
	var tex = load(level_data["image"])
	if tex: image_rect.texture = tex
	
	# --- RANDOMIZAÇÃO DA LACUNA PARA CADA CARREGAMENTO ---
	current_missing_idx = randi() % level_data["syllables"].size()
	current_correct_syllable = level_data["syllables"][current_missing_idx]
	var current_options = _generate_options(current_correct_syllable)
	
	# Construção Dinâmica da Palavra
	_clear_children(word_container)
	var font_size = 65
	if level_data["syllables"].size() >= 4: font_size = 45
		
	for i in range(level_data["syllables"].size()):
		var lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", font_size)
		if i == current_missing_idx:
			lbl.text = "___"
			lbl.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		else:
			lbl.text = level_data["syllables"][i]
			lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
		word_container.add_child(lbl)
		if i < level_data["syllables"].size() - 1:
			var dash = Label.new()
			dash.text = "-"
			dash.add_theme_font_size_override("font_size", font_size)
			dash.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
			word_container.add_child(dash)
	
	# Constrói as Opções (Botões)
	_clear_children(options_container)
	for opt in current_options:
		var btn = Button.new()
		btn.text = opt
		btn.custom_minimum_size = Vector2(110, 70)
		btn.add_theme_font_size_override("font_size", 45)
		btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		var btn_n = StyleBoxFlat.new()
		btn_n.bg_color = Color(1.0, 1.0, 1.0, 0.95)
		btn_n.corner_radius_top_left = 20; btn_n.corner_radius_top_right = 20
		btn_n.corner_radius_bottom_left = 20; btn_n.corner_radius_bottom_right = 20
		btn.add_theme_stylebox_override("normal", btn_n)
		btn.add_theme_stylebox_override("hover", btn_n)
		btn.pressed.connect(self._on_option_selected.bind(opt, btn))
		options_container.add_child(btn)

func _clear_children(node: Node):
	for c in node.get_children(): c.queue_free()

func _on_option_selected(selected_silaba: String, btn: Button):
	if completed: return
	if selected_silaba == current_correct_syllable:
		# Acerto
		if sfx_correct.stream: sfx_correct.play()
		feedback_label.text = "PARABÉNS VOCÊ ACERTOU"
		feedback_label.add_theme_color_override("font_color", Color(0.1, 0.7, 0.1))
		_update_mascot("res://assets/images/Mascote_acerto.png")
		
		# Mostra a sílaba correta na lacuna
		var missing_node_index = current_missing_idx * 2
		var missing_node = word_container.get_child(missing_node_index)
		if missing_node is Label:
			missing_node.text = current_correct_syllable
			missing_node.add_theme_color_override("font_color", Color(0.1, 0.7, 0.1))
			
		# Tweens
		feedback_label.pivot_offset = feedback_label.size / 2
		var t_fb = create_tween()
		t_fb.tween_property(feedback_label, "scale", Vector2(1.3, 1.3), 0.15).set_trans(Tween.TRANS_SPRING)
		t_fb.tween_property(feedback_label, "scale", Vector2(1.0, 1.0), 0.25)
		
		word_container.pivot_offset = word_container.size / 2
		var t_wd = create_tween()
		t_wd.tween_property(word_container, "scale", Vector2(1.15, 1.15), 0.15)
		t_wd.tween_property(word_container, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_SPRING)
			
		for c in options_container.get_children(): c.disabled = true
		await get_tree().create_timer(1.8).timeout
		progress_in_game += 1
		_load_level(progress_in_game)
	else:
		# Erro
		if sfx_error.stream: sfx_error.play()
		feedback_label.text = "TENTE NOVAMENTE"
		feedback_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.1))
		_update_mascot("res://assets/images/Mascote_erro.png")
		var original_color = btn.modulate
		btn.modulate = Color(0.9, 0.4, 0.4) 
		await get_tree().create_timer(0.4).timeout
		if is_instance_valid(btn): btn.modulate = original_color
		
		# Novo: Volta para a pose pensando após 1.5 segundos para incentivar nova tentativa
		await get_tree().create_timer(1.1).timeout
		if not completed and feedback_label.text == "TENTE NOVAMENTE":
			_update_mascot("res://assets/images/Mascote_pensando.png")

func _update_mascot(texture_path: String):
	var tex = load(texture_path)
	if tex and mascot_rect:
		mascot_rect.texture = tex
		# Pequena animação de feedback
		var tw = create_tween()
		mascot_rect.pivot_offset = Vector2(mascot_rect.size.x / 2, mascot_rect.size.y)
		tw.tween_property(mascot_rect, "scale", Vector2(1.1, 1.1), 0.1)
		tw.tween_property(mascot_rect, "scale", Vector2(1.0, 1.0), 0.1)
