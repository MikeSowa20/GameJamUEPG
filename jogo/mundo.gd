extends CharacterBody2D

const EFEITOS = preload("res://efeitos_visuais.gd")
const CENA_DISPARO_BRACO = preload("res://jogador/disparo_braco.tscn")


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
var braco_robotico_ativo: bool = false
var disparo_braco_disponivel: bool = true
@export var cooldown_disparo_braco: float = 0.4
var botao_braco_dev: Button = null


# ==================================================
# DASH
# ==================================================

@export var distancia_dash: float = 70.0
@export var velocidade_dash: float = 500.0
@export var cooldown_dash: float = 1.5

var dashing: bool = false
var dash_disponivel: bool = true


# ==================================================
# VIDA
# ==================================================

const CORACOES_INICIAIS: int = 5

var vida: int
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

	# ==================================================
	# GRUPO DO JOGADOR
	# ==================================================

	add_to_group("jogador")


	# ==================================================
	# VIDA
	# ==================================================

	if not DificuldadeGlobal.vida_inicializada:
		DificuldadeGlobal.vida_jogador = CORACOES_INICIAIS
		DificuldadeGlobal.vida_inicializada = true
	vida = clampi(
		DificuldadeGlobal.vida_jogador,
		0,
		CORACOES_INICIAIS
	)
	velocidade *= DificuldadeGlobal.multiplicador_velocidade_jogador
	braco_robotico_ativo = DificuldadeGlobal.braco_robotico_ativo
	criar_botao_braco_dev()


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

func _physics_process(_delta: float) -> void:

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


	# ==================================================
	# VERIFICAR INIMIGOS
	# ==================================================

	if atacando:

		verificar_inimigos()


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
	if braco_robotico_ativo:
		var nome_braco := StringName(str(nome_base) + "_braco")
		if animacao.sprite_frames.has_animation(nome_braco):
			nome_final = nome_braco
	animacao.play(nome_final)


func definir_braco_robotico(ativo: bool) -> void:
	braco_robotico_ativo = ativo
	DificuldadeGlobal.braco_robotico_ativo = ativo
	atualizar_texto_botao_braco()
	var direcao_atual := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direcao_atual == Vector2.ZERO:
		tocar_animacao("parado")
	else:
		atualizar_animacao(direcao_atual)


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
		botao_braco_dev.text = "Braço robótico: %s (DEV)" % (
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

	dash_disponivel = false

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

	iniciar_cooldown_dash()


# ==================================================
# COOLDOWN DO DASH
# ==================================================

func iniciar_cooldown_dash() -> void:

	await get_tree().create_timer(
		cooldown_dash
	).timeout


	dash_disponivel = true


	print(
		"Dash disponível novamente!"
	)


# ==================================================
# RECEBER DANO
# ==================================================

func receber_dano(_valor: float = 1.0) -> void:
	if morto:
		return

	animacao.modulate = Color(1.0, 0.2, 0.2, 1.0)
	var tween_impacto := create_tween()
	tween_impacto.set_trans(Tween.TRANS_SINE)
	tween_impacto.set_ease(Tween.EASE_OUT)
	tween_impacto.tween_property(animacao, "modulate", Color.WHITE, 0.22)
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
		CORACOES_INICIAIS
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


func atualizar_coracoes() -> void:
	for filho: Node in barra_vida.get_children():
		filho.free()

	for indice: int in range(CORACOES_INICIAIS):
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
	vida = CORACOES_INICIAIS
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
	var erro: Error = get_tree().change_scene_to_file("res://menu_inicial.tscn")
	if erro != OK:
		push_error("Não foi possível voltar ao menu inicial.")


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
