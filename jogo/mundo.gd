extends CharacterBody2D

const EFEITOS = preload("res://efeitos_visuais.gd")
const CENA_DISPARO_BRACO = preload("res://jogador/disparo_braco.tscn")
const SOM_DASH = preload("res://sons/personagem/dash.ogg")
const SOM_ATAQUE = preload("res://sons/personagem/ataque.ogg")
const SOM_DISPARO = preload("res://sons/personagem/disparo.ogg")
const SOM_DANO = preload("res://sons/personagem/dano.ogg")
const SONS_PASSOS: Array[AudioStream] = [
	preload("res://sons/personagem/andar_01.ogg"),
	preload("res://sons/personagem/andar_02.ogg"),
	preload("res://sons/personagem/andar_03.ogg")
]


# ==================================================
# MOVIMENTO
# ==================================================

@export var velocidade: float = 80.0

# Última direção em que o jogador estava andando.
# Usada pelo dash.
var ultima_direcao: Vector2 = Vector2.DOWN


# ==================================================
# ANIMAÇÃO DO PERSONAGEM
# ==================================================

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
var braco_robotico_ativo: bool = false
var perna_robotica_ativa: bool = false
var disparo_braco_disponivel: bool = true
@export var cooldown_disparo_braco: float = 0.4
var botao_braco_dev: Button = null
var audio_acoes: AudioStreamPlayer
var audio_passos: AudioStreamPlayer
var tempo_ate_proximo_passo: float = 0.0
var indice_passo: int = 0
var tween_tremida: Tween = null
var posicao_camera_original: Vector2


# ==================================================
# DASH
# ==================================================

@export var distancia_dash: float = 70.0
@export var velocidade_dash: float = 500.0
@export var cooldown_dash: float = 1.5

var dashing: bool = false
var dash_disponivel: bool = true
var cargas_dash: int = 1
var cargas_dash_maximas: int = 1


# ==================================================
# VIDA
# ==================================================

const CORACOES_INICIAIS: int = 5

var vida: int
var vida_maxima_atual: int = CORACOES_INICIAIS
var morto: bool = false

@onready var barra_vida: HBoxContainer = $"../CanvasLayer/BarraVida"


# ==================================================
# ATAQUE
# ==================================================

# Distância máxima do ataque
@export var alcance_ataque: float = 60.0

# Ângulo total do ataque
@export var angulo_ataque: float = 160.0

# Dano causado
@export var dano: float = 10.0

# Duração do ataque
@export var duracao_ataque: float = 0.5

# Indica se está atacando
var atacando: bool = false

# Guarda os inimigos que já foram atingidos
# durante o ataque atual
var inimigos_atingidos: Array[Node] = []

# Direção do ataque.
# Essa direção é definida pelo mouse no momento
# em que o jogador clica.
var direcao_ataque: Vector2 = Vector2.RIGHT


# ==================================================
# ATAQUE
# ==================================================

@onready var attack_pivot: Node2D = $AttackPivot

@onready var golpe: AnimatedSprite2D = $AttackPivot/Golpe


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:
	criar_audio_personagem()
	posicao_camera_original = camera.position

	# ==================================================
	# GRUPO DO JOGADOR
	# ==================================================

	add_to_group("jogador")


	# ==================================================
	# VIDA
	# ==================================================

	vida_maxima_atual = DificuldadeGlobal.get_vida_maxima()
	if not DificuldadeGlobal.vida_inicializada:
		DificuldadeGlobal.vida_jogador = vida_maxima_atual
		DificuldadeGlobal.vida_inicializada = true
	vida = clampi(
		DificuldadeGlobal.vida_jogador,
		0,
		vida_maxima_atual
	)
	velocidade *= DificuldadeGlobal.multiplicador_velocidade_jogador
	braco_robotico_ativo = DificuldadeGlobal.braco_equipado
	perna_robotica_ativa = DificuldadeGlobal.perna_equipada
	cargas_dash_maximas = 2 if perna_robotica_ativa else 1
	cargas_dash = cargas_dash_maximas
	criar_botoes_modificacoes()


	# ==================================================
	# BARRA DE VIDA
	# ==================================================

	atualizar_coracoes()


	# ==================================================
	# GOLPE
	# ==================================================

	golpe.visible = false


	# ==================================================
	# ANIMAÇÃO INICIAL
	# ==================================================

	tocar_animacao("parado")


# ==================================================
# FÍSICA
# ==================================================

func _physics_process(delta: float) -> void:
	ignorar_colisao_com_inimigos()

	# ==================================================
	# DASH
	# ==================================================

	if dashing:

		return


	# ==================================================
	# PEGAR DIREÇÃO DO MOVIMENTO
	# ==================================================

	var direcao: Vector2 = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)


	# ==================================================
	# MOVIMENTO
	# ==================================================

	# O jogador pode continuar andando
	# mesmo durante o ataque.

	velocity = direcao * velocidade


	# ==================================================
	# ATUALIZAR DIREÇÃO E ANIMAÇÃO
	# ==================================================

	if direcao != Vector2.ZERO:

		# Guarda a última direção
		ultima_direcao = direcao.normalized()


		# Não troca para animação de caminhada
		# enquanto estiver atacando.
		#
		# O golpe possui seu próprio AnimatedSprite2D.

		if not atacando:

			atualizar_animacao(direcao)


	else:

		# Só mostra "parado" se não estiver atacando.

		if not atacando:

			atualizar_animacao_parado()


	# ==================================================
	# MOVIMENTO COM COLISÃO
	# ==================================================

	move_and_slide()
	atualizar_som_passos(delta)


	# ==================================================
	# VERIFICAR INIMIGOS
	# ==================================================

	if atacando:

		verificar_inimigos()


func ignorar_colisao_com_inimigos() -> void:
	# Exceções preservam colisões com paredes, tokens e projéteis.
	for inimigo: Node in get_tree().get_nodes_in_group("inimigos"):
		if inimigo is PhysicsBody2D:
			var corpo := inimigo as PhysicsBody2D
			add_collision_exception_with(corpo)
			corpo.add_collision_exception_with(self)


# ==================================================
# ANIMAÇÃO DE MOVIMENTO
# ==================================================

func atualizar_animacao(direcao: Vector2) -> void:

	# ==================================================
	# MOVIMENTO HORIZONTAL
	# ==================================================

	if abs(direcao.x) > abs(direcao.y):

		# --------------------------------------------------
		# DIREITA
		# --------------------------------------------------

		if direcao.x > 0:

			tocar_animacao("andando_direita")


		# --------------------------------------------------
		# ESQUERDA
		# --------------------------------------------------

		else:

			tocar_animacao("andando_esquerda")


	# ==================================================
	# MOVIMENTO VERTICAL
	# ==================================================

	else:

		# --------------------------------------------------
		# BAIXO
		# --------------------------------------------------

		if direcao.y > 0:

			tocar_animacao("andando_baixo")


		# --------------------------------------------------
		# CIMA
		# --------------------------------------------------

		else:

			tocar_animacao("andando_cima")


# ==================================================
# ANIMAÇÃO PARADO
# ==================================================

func atualizar_animacao_parado() -> void:

	# A animação "parado" possui somente
	# o personagem olhando para a tela.

	tocar_animacao("parado")


func tocar_animacao(nome_base: StringName) -> void:
	var nome_final: StringName = nome_base
	if DificuldadeGlobal.cabeca_robotica_ativa:
		var nome_cabeca := StringName(str(nome_base) + "_cabeca")
		if animacao.sprite_frames.has_animation(nome_cabeca):
			nome_final = nome_cabeca
	elif perna_robotica_ativa:
		var nome_perna := StringName(str(nome_base) + "_perna")
		if animacao.sprite_frames.has_animation(nome_perna):
			nome_final = nome_perna
	elif braco_robotico_ativo:
		var nome_braco := StringName(str(nome_base) + "_braco")
		if animacao.sprite_frames.has_animation(nome_braco):
			nome_final = nome_braco
	animacao.play(nome_final)


func definir_braco_robotico(ativo: bool) -> void:
	if not DificuldadeGlobal.braco_robotico_ativo:
		return
	braco_robotico_ativo = ativo
	DificuldadeGlobal.braco_equipado = ativo
	atualizar_texto_botao_braco()
	var direcao_atual := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direcao_atual == Vector2.ZERO:
		tocar_animacao("parado")
	else:
		atualizar_animacao(direcao_atual)


func definir_perna_robotica(ativo: bool) -> void:
	if not DificuldadeGlobal.perna_robotica_ativa:
		return
	perna_robotica_ativa = ativo
	DificuldadeGlobal.perna_equipada = ativo
	cargas_dash_maximas = 2 if perna_robotica_ativa else 1
	cargas_dash = mini(cargas_dash, cargas_dash_maximas)
	if cargas_dash <= 0:
		cargas_dash = cargas_dash_maximas
	dash_disponivel = cargas_dash > 0
	atualizar_texto_botoes_modificacoes()
	var direcao_atual := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direcao_atual == Vector2.ZERO:
		tocar_animacao("parado")
	else:
		atualizar_animacao(direcao_atual)


func criar_botoes_modificacoes() -> void:
	var canvas := get_node_or_null("../CanvasLayer")
	if canvas == null:
		return
	var coluna := VBoxContainer.new()
	coluna.name = "Modificacoes"
	coluna.anchor_left = 1.0
	coluna.anchor_right = 1.0
	coluna.offset_left = -128.0
	coluna.offset_top = 8.0
	coluna.offset_right = -8.0
	coluna.custom_minimum_size = Vector2(120, 0)
	coluna.add_theme_constant_override("separation", 4)
	canvas.add_child(coluna)
	if DificuldadeGlobal.braco_robotico_ativo:
		botao_braco_dev = Button.new()
		botao_braco_dev.custom_minimum_size = Vector2(120, 28)
		botao_braco_dev.add_theme_font_size_override("font_size", 10)
		botao_braco_dev.pressed.connect(func() -> void: definir_braco_robotico(not braco_robotico_ativo))
		coluna.add_child(botao_braco_dev)
	if DificuldadeGlobal.perna_robotica_ativa:
		var botao_perna := Button.new()
		botao_perna.name = "BotaoPerna"
		botao_perna.custom_minimum_size = Vector2(120, 28)
		botao_perna.add_theme_font_size_override("font_size", 10)
		botao_perna.pressed.connect(func() -> void: definir_perna_robotica(not perna_robotica_ativa))
		coluna.add_child(botao_perna)
	atualizar_texto_botoes_modificacoes()


func atualizar_texto_botoes_modificacoes() -> void:
	atualizar_texto_botao_braco()
	var botao_perna := get_node_or_null("../CanvasLayer/Modificacoes/BotaoPerna") as Button
	if botao_perna != null:
		botao_perna.text = "Perna: %s | Dash %d/%d" % ["ON" if perna_robotica_ativa else "OFF", cargas_dash, cargas_dash_maximas]


func criar_botao_braco_dev() -> void:
	var canvas := get_node_or_null("../CanvasLayer")
	if canvas == null:
		return
	botao_braco_dev = Button.new()
	botao_braco_dev.position = Vector2(8, 232)
	botao_braco_dev.custom_minimum_size = Vector2(190, 30)
	botao_braco_dev.add_theme_font_size_override("font_size", 11)
	botao_braco_dev.pressed.connect(
		func() -> void: definir_braco_robotico(not braco_robotico_ativo)
	)
	canvas.add_child(botao_braco_dev)
	atualizar_texto_botao_braco()


func atualizar_texto_botao_braco() -> void:
	if is_instance_valid(botao_braco_dev):
		botao_braco_dev.text = "Braço: %s" % (
			"ON" if braco_robotico_ativo else "OFF"
		)


func disparar_braco_robotico() -> void:
	if not braco_robotico_ativo or not disparo_braco_disponivel or morto:
		return
	var direcao: Vector2 = global_position.direction_to(get_global_mouse_position())
	if direcao == Vector2.ZERO:
		direcao = ultima_direcao
	var disparo := CENA_DISPARO_BRACO.instantiate() as Area2D
	get_parent().add_child(disparo)
	disparo.global_position = global_position + direcao.normalized() * 22.0
	disparo.configurar(direcao, self)
	tocar_som_acao(SOM_DISPARO, -5.0, randf_range(0.96, 1.04))
	disparo_braco_disponivel = false
	EFEITOS.criar_clarao(
		get_parent(),
		disparo.global_position,
		Color(0.45, 0.9, 1.0, 1.0),
		10.0,
		0.13
	)
	await get_tree().create_timer(cooldown_disparo_braco).timeout
	if is_instance_valid(self):
		disparo_braco_disponivel = true


# ==================================================
# ATAQUE
# ==================================================

func atacar() -> void:

	# ==================================================
	# VERIFICAÇÕES
	# ==================================================

	# Não pode atacar durante o dash
	if dashing:

		return


	# Não pode iniciar outro ataque
	if atacando:

		return


	# ==================================================
	# PEGAR POSIÇÃO DO MOUSE
	# ==================================================

	var mouse_posicao: Vector2 = get_global_mouse_position()


	# ==================================================
	# CALCULAR DIREÇÃO DO ATAQUE
	# ==================================================

	# Calcula a direção GLOBAL do jogador até o mouse.

	direcao_ataque = global_position.direction_to(
		mouse_posicao
	)


	# Caso o mouse esteja exatamente sobre o jogador
	if direcao_ataque == Vector2.ZERO:

		direcao_ataque = Vector2.RIGHT


	# ==================================================
	# INICIAR ATAQUE
	# ==================================================

	atacando = true
	tocar_som_acao(SOM_ATAQUE, -7.0, randf_range(0.94, 1.06))

	inimigos_atingidos.clear()


	# ==================================================
	# DIRECIONAR ATTACK PIVOT
	# ==================================================

	# IMPORTANTE:
	#
	# O AttackPivot é filho do jogador.
	#
	# Por isso usamos GLOBAL ROTATION.
	#
	# Dessa forma o golpe aponta para o mouse
	# independentemente da rotação do jogador.

	attack_pivot.global_rotation = direcao_ataque.angle()


	# ==================================================
	# MOSTRAR GOLPE
	# ==================================================

	golpe.visible = true


	# ==================================================
	# INICIAR ANIMAÇÃO DO GOLPE
	# ==================================================

	if golpe.sprite_frames != null:

		if golpe.sprite_frames.has_animation("golpe"):

			# Garante que começa do primeiro frame

			golpe.stop()

			golpe.frame = 0

			golpe.play("golpe")

		else:

			print(
				"ERRO: A animação 'golpe' não existe."
			)

	else:

		print(
			"ERRO: O Golpe não possui SpriteFrames."
		)


	# ==================================================
	# DURANTE O ATAQUE
	# ==================================================

	# O jogador NÃO para.
	#
	# O _physics_process continua executando
	# normalmente e o personagem pode andar.

	await get_tree().create_timer(
		duracao_ataque
	).timeout


	# ==================================================
	# FINALIZAR ATAQUE
	# ==================================================

	golpe.stop()

	golpe.visible = false


	# ==================================================
	# RESET DO ATTACK PIVOT
	# ==================================================

	# O jogador pode ter mudado de direção
	# enquanto atacava.
	#
	# Portanto o AttackPivot volta a acompanhar
	# a rotação atual do jogador.

	attack_pivot.global_rotation = global_rotation


	# ==================================================
	# FINALIZAR ESTADO DE ATAQUE
	# ==================================================

	atacando = false


	# ==================================================
	# ATUALIZAR ANIMAÇÃO
	# ==================================================

	var direcao_atual: Vector2 = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)


	if direcao_atual != Vector2.ZERO:

		atualizar_animacao(direcao_atual)

	else:

		atualizar_animacao_parado()


# ==================================================
# VERIFICAR INIMIGOS ATINGIDOS
# ==================================================

func verificar_inimigos() -> void:

	# ==================================================
	# PEGAR INIMIGOS
	# ==================================================

	var inimigos: Array[Node] = (
		get_tree().get_nodes_in_group("inimigos")
	)


	# ==================================================
	# PERCORRER INIMIGOS
	# ==================================================

	for inimigo: Node in inimigos:

		# --------------------------------------------------
		# Verifica se ainda existe
		# --------------------------------------------------

		if not is_instance_valid(inimigo):

			continue


		# --------------------------------------------------
		# Não pode acertar duas vezes
		# --------------------------------------------------

		if inimigos_atingidos.has(inimigo):

			continue


		# --------------------------------------------------
		# Só aceita CharacterBody2D
		# --------------------------------------------------

		if not inimigo is CharacterBody2D:

			continue


		var alvo: CharacterBody2D = (
			inimigo as CharacterBody2D
		)


		# ==================================================
		# DISTÂNCIA
		# ==================================================

		var distancia: float = (
			global_position.distance_to(
				alvo.global_position
			)
		)


		# Se estiver longe demais, ignora.

		if distancia > alcance_ataque:

			continue


		# ==================================================
		# DIREÇÃO DO INIMIGO
		# ==================================================

		var direcao_inimigo: Vector2 = (
			global_position.direction_to(
				alvo.global_position
			)
		)


		# ==================================================
		# ÂNGULO DO ATAQUE
		# ==================================================

		# Usa a direção que foi capturada
		# quando o jogador clicou.

		var angulo: float = abs(
			direcao_ataque.angle_to(
				direcao_inimigo
			)
		)


		# ==================================================
		# VERIFICAR ARCO
		# ==================================================

		if angulo <= deg_to_rad(
			angulo_ataque / 2.0
		):

			# Marca o inimigo como atingido

			inimigos_atingidos.append(inimigo)


			# Causa dano

			if alvo.has_method("receber_dano"):

				alvo.receber_dano(dano)


# ==================================================
# DASH
# ==================================================

func iniciar_dash() -> void:

	# ==================================================
	# VERIFICAÇÕES
	# ==================================================

	if dashing:

		return


	if atacando:

		return


	if not dash_disponivel:

		return


	# ==================================================
	# INICIAR DASH
	# ==================================================

	dashing = true
	tocar_som_acao(SOM_DASH, -6.0, randf_range(0.96, 1.04))

	cargas_dash -= 1
	dash_disponivel = cargas_dash > 0
	atualizar_texto_botoes_modificacoes()

	velocity = Vector2.ZERO


	# ==================================================
	# DIREÇÃO DO DASH
	# ==================================================

	var direcao_dash: Vector2 = (
		ultima_direcao.normalized()
	)


	# ==================================================
	# DISTÂNCIA PERCORRIDA
	# ==================================================

	var distancia_percorrida: float = 0.0
	var contador_pos_imagem: int = 0


	# ==================================================
	# MOVIMENTO DO DASH
	# ==================================================

	while distancia_percorrida < distancia_dash:
		contador_pos_imagem += 1
		if contador_pos_imagem % 2 == 0:
			EFEITOS.criar_pos_imagem(
				animacao,
				get_parent(),
				Color(0.25, 0.85, 1.0, 0.5),
				0.24
			)

		# --------------------------------------------------
		# Movimento deste frame
		# --------------------------------------------------

		var movimento: Vector2 = (
			direcao_dash
			* velocidade_dash
			* get_process_delta_time()
		)


		# --------------------------------------------------
		# Distância restante
		# --------------------------------------------------

		var restante: float = (
			distancia_dash
			- distancia_percorrida
		)


		# --------------------------------------------------
		# Impede ultrapassar a distância
		# --------------------------------------------------

		if movimento.length() > restante:

			movimento = direcao_dash * restante


		# ==================================================
		# MOVIMENTO COM COLISÃO
		# ==================================================

		var colisao: KinematicCollision2D = (
			move_and_collide(movimento)
		)


		# Atualiza distância percorrida

		distancia_percorrida += movimento.length()


		# ==================================================
		# COLISÃO COM PAREDE
		# ==================================================

		if colisao != null:

			print(
				"Dash bateu em uma parede!"
			)

			break


		await get_tree().process_frame
		if not is_inside_tree():
			return


	# ==================================================
	# FINALIZAR DASH
	# ==================================================

	velocity = Vector2.ZERO

	dashing = false


	# ==================================================
	# ANIMAÇÃO
	# ==================================================

	tocar_animacao("parado")


	# ==================================================
	# COOLDOWN
	# ==================================================

	if cargas_dash <= 0:
		iniciar_cooldown_dash()


# ==================================================
# COOLDOWN DO DASH
# ==================================================

func iniciar_cooldown_dash() -> void:
	if not is_inside_tree():
		return

	await get_tree().create_timer(
		cooldown_dash
	).timeout


	cargas_dash = cargas_dash_maximas
	dash_disponivel = true
	atualizar_texto_botoes_modificacoes()


	print(
		"Dash disponível novamente!"
	)


# ==================================================
# RECEBER DANO
# ==================================================

func receber_dano(_valor: float = 1.0) -> void:
	if morto:
		return

	tocar_som_acao(SOM_DANO, -4.0, randf_range(0.94, 1.04))
	piscar_ao_receber_dano()
	tremer_camera()
	EFEITOS.criar_onda(
		get_parent(),
		global_position,
		Color(1.0, 0.15, 0.12, 0.8),
		22.0,
		0.2
	)

	# ==================================================
	# DIMINUIR VIDA
	# ==================================================

	vida -= 1


	# ==================================================
	# LIMITAR VIDA
	# ==================================================

	vida = clamp(
		vida,
		0,
		vida_maxima_atual
	)
	DificuldadeGlobal.vida_jogador = vida


	# ==================================================
	# ATUALIZAR BARRA
	# ==================================================

	atualizar_coracoes()


	print(
		"Jogador recebeu ",
		1,
		" coração de dano. Corações: ",
		vida
	)


	# ==================================================
	# VERIFICAR MORTE
	# ==================================================

	if vida <= 0:

		morrer()


func criar_audio_personagem() -> void:
	audio_acoes = AudioStreamPlayer.new()
	audio_acoes.name = "AudioAcoes"
	add_child(audio_acoes)
	audio_passos = AudioStreamPlayer.new()
	audio_passos.name = "AudioPassos"
	audio_passos.volume_db = -13.0
	add_child(audio_passos)


func tocar_som_acao(som: AudioStream, volume: float, tom: float = 1.0) -> void:
	audio_acoes.stream = som
	audio_acoes.volume_db = volume
	audio_acoes.pitch_scale = tom
	audio_acoes.play()


func atualizar_som_passos(delta: float) -> void:
	if velocity.length() < 1.0 or dashing or morto:
		tempo_ate_proximo_passo = 0.0
		return
	tempo_ate_proximo_passo -= delta
	if tempo_ate_proximo_passo > 0.0:
		return
	audio_passos.stream = SONS_PASSOS[indice_passo]
	audio_passos.pitch_scale = randf_range(0.94, 1.06)
	audio_passos.play()
	indice_passo = (indice_passo + 1) % SONS_PASSOS.size()
	tempo_ate_proximo_passo = 0.32


func piscar_ao_receber_dano() -> void:
	animacao.modulate = Color.WHITE
	var tween_impacto := create_tween()
	tween_impacto.set_trans(Tween.TRANS_SINE)
	for repeticao: int in range(3):
		tween_impacto.tween_property(animacao, "modulate", Color(1.0, 0.25, 0.25, 1.0), 0.055)
		tween_impacto.tween_property(animacao, "modulate", Color.WHITE, 0.055)


func tremer_camera() -> void:
	if tween_tremida != null and tween_tremida.is_valid():
		tween_tremida.kill()
	camera.position = posicao_camera_original
	tween_tremida = create_tween()
	tween_tremida.set_trans(Tween.TRANS_SINE)
	tween_tremida.set_ease(Tween.EASE_OUT)
	for intensidade: float in [4.0, 3.0, 2.0, 1.0]:
		tween_tremida.tween_property(camera, "position", posicao_camera_original + Vector2(randf_range(-intensidade, intensidade), randf_range(-intensidade, intensidade)), 0.035)
	tween_tremida.tween_property(camera, "position", posicao_camera_original, 0.05)


func atualizar_coracoes() -> void:
	for filho: Node in barra_vida.get_children():
		filho.free()

	for indice: int in range(vida_maxima_atual):
		var coracao := Label.new()
		coracao.text = "♥" if indice < vida else "♡"
		coracao.add_theme_font_size_override("font_size", 28)
		coracao.add_theme_color_override(
			"font_color",
			Color("e63946") if indice < vida else Color("6c757d")
		)
		coracao.add_theme_color_override("font_outline_color", Color.BLACK)
		coracao.add_theme_constant_override("outline_size", 4)
		barra_vida.add_child(coracao)


func recuperar_vida_total() -> void:
	vida = vida_maxima_atual
	DificuldadeGlobal.vida_jogador = vida
	atualizar_coracoes()


func recuperar_vida(quantidade: int) -> void:
	vida = mini(vida + maxi(quantidade, 0), vida_maxima_atual)
	DificuldadeGlobal.vida_jogador = vida
	atualizar_coracoes()


# ==================================================
# MORRER
# ==================================================

func morrer() -> void:
	if morto:
		return
	morto = true
	DificuldadeGlobal.registrar_morte()
	DificuldadeGlobal.preparar_nova_run()

	print(
		"Jogador morreu!"
	)


	velocity = Vector2.ZERO

	atacando = false

	dashing = false


	# Esconde o golpe

	golpe.visible = false


	# Animação parado

	tocar_animacao("parado")
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

	var tween_morte := create_tween()
	tween_morte.set_parallel(true)
	tween_morte.set_trans(Tween.TRANS_QUAD)
	tween_morte.set_ease(Tween.EASE_IN)
	tween_morte.tween_property(animacao, "modulate:a", 0.0, 0.65)
	tween_morte.tween_property(animacao, "scale", animacao.scale * 0.65, 0.65)
	await tween_morte.finished

	get_tree().paused = false
	var erro: Error = get_tree().change_scene_to_file("res://loja.tscn")
	if erro != OK:
		push_error("Não foi possível voltar à loja.")


# ==================================================
# INPUT
# ==================================================

func _input(event: InputEvent) -> void:

	# ==================================================
	# ATAQUE - BOTÃO ESQUERDO
	# ==================================================

	if event is InputEventMouseButton:

		var mouse_event: InputEventMouseButton = (
			event as InputEventMouseButton
		)


		if mouse_event.button_index == MOUSE_BUTTON_LEFT:

			if mouse_event.pressed:

				atacar()

		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:

			if mouse_event.pressed:

				disparar_braco_robotico()


	# ==================================================
	# DASH - ESPAÇO
	# ==================================================

	if event is InputEventKey:

		var key_event: InputEventKey = (
			event as InputEventKey
		)


		if key_event.keycode == KEY_SPACE:

			if key_event.pressed and not key_event.echo:

				iniciar_dash()
