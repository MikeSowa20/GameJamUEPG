extends Node

const AUMENTO_VIDA_POR_SALA: float = 0.35
const AUMENTO_VELOCIDADE_POR_SALA: float = 0.12
const TOKENS_BASE: int = 2
const CENA_ESCOLHA_MELHORIA = preload("res://escolha_melhoria.tscn")

var sala_atual: int = 1
var tokens: int = 0
var mortes: int = 0
var ultima_cena: String = ""
var vida_jogador: int = 5
var vida_inicializada: bool = false
var multiplicador_velocidade_jogador: float = 1.0
var braco_robotico_ativo: bool = false
var perna_robotica_ativa: bool = false
var cabeca_robotica_ativa: bool = false
var braco_equipado: bool = false
var perna_equipada: bool = false
var escolha_aberta: bool = false
var tela_escolha: Control = null
var dialogo_inicial_loja_exibido: bool = false

var canvas_hud: CanvasLayer
var texto_dificuldade: Label
var barra_dificuldade: ProgressBar
var texto_tokens: Label


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
	canvas_hud.visible = nome.begins_with("sala")
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
		"recompensa": maxi(1, roundi(TOKENS_BASE * sala_atual * fator_tipo))
	}


func dropar_tokens(posicao: Vector2, valor_total: int) -> void:
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
		var token := preload("res://token.tscn").instantiate()
		var valor: int = maxi(1, restante / (quantidade - indice))
		restante -= valor
		cena.add_child.call_deferred(token)
		token.call_deferred(
			"configurar",
			posicao,
			valor,
			Vector2.RIGHT.rotated(TAU * indice / quantidade)
		)


func adicionar_tokens(valor: int) -> void:
	tokens += maxi(valor, 0)
	atualizar_hud()


func registrar_morte() -> void:
	mortes += 1


func bonus_pos_morte() -> float:
	return 1.0 + mortes * 0.15


func iniciar_nova_partida() -> void:
	# Inicia uma campanha nova a partir do menu principal.
	tokens = 0
	mortes = 0
	dialogo_inicial_loja_exibido = false
	braco_robotico_ativo = false
	perna_robotica_ativa = false
	cabeca_robotica_ativa = false
	braco_equipado = false
	perna_equipada = false
	preparar_nova_run()


func preparar_nova_run() -> void:
	# Limpa somente os bônus obtidos durante a run. Dinheiro e peças ficam.
	if escolha_aberta:
		fechar_escolha()
	get_tree().paused = false
	sala_atual = 1
	vida_jogador = get_vida_maxima()
	vida_inicializada = false
	multiplicador_velocidade_jogador = 1.0
	braco_equipado = braco_robotico_ativo
	perna_equipada = perna_robotica_ativa
	ultima_cena = ""
	atualizar_hud()


func get_vida_maxima() -> int:
	var total := 5
	if perna_robotica_ativa:
		total += 1
	if cabeca_robotica_ativa:
		total += 2
	return total


func get_multiplicador_perna() -> float:
	return 1.0


func comprar_melhoria(tipo: String, preco: int) -> bool:
	if tokens < preco:
		return false
	match tipo:
		"braco":
			if braco_robotico_ativo:
				return false
			braco_robotico_ativo = true
		"perna":
			if perna_robotica_ativa or not braco_robotico_ativo:
				return false
			perna_robotica_ativa = true
		"cabeca":
			if cabeca_robotica_ativa or not perna_robotica_ativa:
				return false
			cabeca_robotica_ativa = true
		_:
			return false
	tokens -= preco
	atualizar_hud()
	return true


func mostrar_escolha_melhoria() -> void:
	if escolha_aberta:
		return
	await get_tree().process_frame
	atualizar_sala_pela_cena()
	escolha_aberta = true
	get_tree().paused = true
	tela_escolha = CENA_ESCOLHA_MELHORIA.instantiate()
	canvas_hud.add_child(tela_escolha)
	tela_escolha.call("configurar", sala_atual)


func selecionar_melhoria(escolha: String) -> void:
	match escolha:
		"velocidade":
			multiplicador_velocidade_jogador *= 1.10
			var jogador := get_tree().get_first_node_in_group("jogador")
			if jogador != null:
				jogador.velocidade *= 1.10
		"vida":
			var jogador := get_tree().get_first_node_in_group("jogador")
			if jogador != null and jogador.has_method("recuperar_vida"):
				jogador.recuperar_vida(2)
			else:
				vida_jogador = mini(vida_jogador + 2, get_vida_maxima())
		"tokens":
			var sala_concluida := maxi(sala_atual - 1, 1)
			adicionar_tokens(5 * sala_concluida)

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

	texto_tokens = Label.new()
	texto_tokens.add_theme_color_override("font_color", Color("ffd166"))
	texto_tokens.add_theme_font_size_override("font_size", 13)
	coluna.add_child(texto_tokens)
	atualizar_hud()


func atualizar_hud() -> void:
	if not is_instance_valid(texto_dificuldade):
		return
	texto_dificuldade.text = "Dificuldade: %d" % sala_atual
	barra_dificuldade.max_value = maxf(10.0, float(sala_atual))
	barra_dificuldade.value = sala_atual
	texto_tokens.text = "Tokens: %d" % tokens
