extends Node

const AUMENTO_VIDA_POR_SALA: float = 0.35
const AUMENTO_VELOCIDADE_POR_SALA: float = 0.12
const MOEDAS_BASE: int = 2

var sala_atual: int = 1
var moedas: int = 0
var mortes: int = 0
var ultima_cena: String = ""
var vida_jogador: int = 5
var vida_inicializada: bool = false
var multiplicador_velocidade_jogador: float = 1.0
var escolha_aberta: bool = false
var tela_escolha: Control = null

var canvas_hud: CanvasLayer
var texto_dificuldade: Label
var barra_dificuldade: ProgressBar
var texto_moedas: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	criar_hud()
	await get_tree().process_frame
	atualizar_sala_pela_cena()


func _process(_delta: float) -> void:
	var cena := get_tree().current_scene
	if cena == null:
		return
	if cena.scene_file_path != ultima_cena:
		ultima_cena = cena.scene_file_path
		atualizar_sala_pela_cena()


func atualizar_sala_pela_cena() -> void:
	var cena := get_tree().current_scene
	if cena == null:
		return

	var nome: String = cena.scene_file_path.get_file().get_basename()
	canvas_hud.visible = nome != "menu_inicial"
	if nome.begins_with("sala"):
		var numero: int = nome.trim_prefix("sala").to_int()
		if numero > 0:
			sala_atual = numero

	atualizar_hud()


func aplicar_dificuldade_inimigo(
	vida_base: float,
	velocidade_base: float,
	fator_tipo: float = 1.0
) -> Dictionary:
	atualizar_sala_pela_cena()
	var progresso: float = float(max(sala_atual - 1, 0))
	var multiplicador_vida: float = 1.0 + progresso * AUMENTO_VIDA_POR_SALA
	var multiplicador_velocidade: float = 1.0 + progresso * AUMENTO_VELOCIDADE_POR_SALA
	return {
		"vida": vida_base * multiplicador_vida * fator_tipo,
		"velocidade": velocidade_base * multiplicador_velocidade,
		"recompensa": maxi(1, roundi(MOEDAS_BASE * sala_atual * fator_tipo))
	}


func dropar_moedas(posicao: Vector2, valor_total: int) -> void:
	var cena := get_tree().current_scene
	if cena == null:
		return

	var quantidade: int = clampi(
		1 + floori(float(sala_atual - 1) / 2.0),
		1,
		6
	)
	quantidade = mini(quantidade, maxi(valor_total, 1))
	var restante: int = maxi(valor_total, 1)

	for indice: int in range(quantidade):
		var moeda := preload("res://moeda.tscn").instantiate()
		var valor: int = maxi(1, restante / (quantidade - indice))
		restante -= valor
		cena.add_child.call_deferred(moeda)
		moeda.call_deferred(
			"configurar",
			posicao,
			valor,
			Vector2.RIGHT.rotated(TAU * indice / quantidade)
		)


func adicionar_moedas(valor: int) -> void:
	moedas += maxi(valor, 0)
	atualizar_hud()


func registrar_morte() -> void:
	mortes += 1


func bonus_pos_morte() -> float:
	return 1.0 + mortes * 0.15


func iniciar_nova_partida() -> void:
	if escolha_aberta:
		fechar_escolha()
	get_tree().paused = false
	sala_atual = 1
	moedas = 0
	vida_jogador = 5
	vida_inicializada = false
	multiplicador_velocidade_jogador = 1.0
	ultima_cena = ""
	atualizar_hud()


func mostrar_escolha_melhoria() -> void:
	if escolha_aberta:
		return

	await get_tree().process_frame
	atualizar_sala_pela_cena()
	escolha_aberta = true
	get_tree().paused = true

	tela_escolha = ColorRect.new()
	tela_escolha.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tela_escolha.color = Color(0.025, 0.035, 0.065, 0.88)
	tela_escolha.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_hud.add_child(tela_escolha)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tela_escolha.add_child(centro)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 14)
	centro.add_child(coluna)

	var titulo := Label.new()
	titulo.text = "ESCOLHA UMA MELHORIA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 22)
	titulo.add_theme_color_override("font_color", Color("ffe29a"))
	coluna.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "Sala %d concluída" % maxi(sala_atual - 1, 1)
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 13)
	coluna.add_child(subtitulo)

	var cartoes := HBoxContainer.new()
	cartoes.add_theme_constant_override("separation", 12)
	coluna.add_child(cartoes)

	criar_cartao(
		cartoes,
		"VELOCIDADE\n\n+10% de velocidade\npermanente",
		"velocidade"
	)
	criar_cartao(
		cartoes,
		"RECUPERAÇÃO\n\nRecuperar todos\nos corações",
		"vida"
	)
	criar_cartao(
		cartoes,
		"MOEDAS\n\n+%d moedas\n(10 × dificuldade)" % (10 * sala_atual),
		"moedas"
	)


func criar_cartao(pai: HBoxContainer, texto: String, escolha: String) -> void:
	var botao := Button.new()
	botao.custom_minimum_size = Vector2(138, 145)
	botao.text = texto
	botao.add_theme_font_size_override("font_size", 14)
	botao.pressed.connect(_selecionar_melhoria.bind(escolha))
	pai.add_child(botao)


func _selecionar_melhoria(escolha: String) -> void:
	match escolha:
		"velocidade":
			multiplicador_velocidade_jogador *= 1.10
			var jogador := get_tree().get_first_node_in_group("jogador")
			if jogador != null:
				jogador.velocidade *= 1.10
		"vida":
			vida_jogador = 5
			var jogador := get_tree().get_first_node_in_group("jogador")
			if jogador != null and jogador.has_method("recuperar_vida_total"):
				jogador.recuperar_vida_total()
		"moedas":
			adicionar_moedas(10 * sala_atual)

	fechar_escolha()


func fechar_escolha() -> void:
	if is_instance_valid(tela_escolha):
		tela_escolha.queue_free()
	tela_escolha = null
	escolha_aberta = false
	get_tree().paused = false


func criar_hud() -> void:
	canvas_hud = CanvasLayer.new()
	canvas_hud.layer = 100
	canvas_hud.visible = false
	add_child(canvas_hud)

	var painel := PanelContainer.new()
	painel.position = Vector2(8, 8)
	painel.custom_minimum_size = Vector2(150, 66)
	canvas_hud.add_child(painel)

	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 8)
	margem.add_theme_constant_override("margin_right", 8)
	margem.add_theme_constant_override("margin_top", 5)
	margem.add_theme_constant_override("margin_bottom", 5)
	painel.add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 2)
	margem.add_child(coluna)

	texto_dificuldade = Label.new()
	texto_dificuldade.add_theme_font_size_override("font_size", 13)
	coluna.add_child(texto_dificuldade)

	barra_dificuldade = ProgressBar.new()
	barra_dificuldade.custom_minimum_size = Vector2(134, 10)
	barra_dificuldade.min_value = 1.0
	barra_dificuldade.max_value = 10.0
	barra_dificuldade.show_percentage = false
	coluna.add_child(barra_dificuldade)

	texto_moedas = Label.new()
	texto_moedas.add_theme_color_override("font_color", Color("ffd166"))
	texto_moedas.add_theme_font_size_override("font_size", 13)
	coluna.add_child(texto_moedas)
	atualizar_hud()


func atualizar_hud() -> void:
	if not is_instance_valid(texto_dificuldade):
		return
	texto_dificuldade.text = "Dificuldade: %d" % sala_atual
	barra_dificuldade.max_value = maxf(10.0, float(sala_atual))
	barra_dificuldade.value = sala_atual
	texto_moedas.text = "Moedas: %d" % moedas
