extends CharacterBody2D


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

@export var vida_maxima: float = 100.0

var vida: float

@onready var barra_vida: ProgressBar = $"../CanvasLayer/BarraVida"


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

	vida = vida_maxima


	# ==================================================
	# BARRA DE VIDA
	# ==================================================

	barra_vida.max_value = vida_maxima
	barra_vida.value = vida


	# ==================================================
	# GOLPE
	# ==================================================

	golpe.visible = false


	# ==================================================
	# ANIMAÇÃO INICIAL
	# ==================================================

	animacao.play("parado")


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

			animacao.play("andando_direita")


		# --------------------------------------------------
		# ESQUERDA
		# --------------------------------------------------

		else:

			animacao.play("andando_esquerda")


	# ==================================================
	# MOVIMENTO VERTICAL
	# ==================================================

	else:

		# --------------------------------------------------
		# BAIXO
		# --------------------------------------------------

		if direcao.y > 0:

			animacao.play("andando_baixo")


		# --------------------------------------------------
		# CIMA
		# --------------------------------------------------

		else:

			animacao.play("andando_cima")


# ==================================================
# ANIMAÇÃO PARADO
# ==================================================

func atualizar_animacao_parado() -> void:

	# A animação "parado" possui somente
	# o personagem olhando para a tela.

	animacao.play("parado")


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


	# ==================================================
	# MOVIMENTO DO DASH
	# ==================================================

	while distancia_percorrida < distancia_dash:

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

	animacao.play("parado")


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

func receber_dano(valor: float) -> void:

	# ==================================================
	# DIMINUIR VIDA
	# ==================================================

	vida -= valor


	# ==================================================
	# LIMITAR VIDA
	# ==================================================

	vida = clamp(
		vida,
		0.0,
		vida_maxima
	)


	# ==================================================
	# ATUALIZAR BARRA
	# ==================================================

	barra_vida.value = vida


	print(
		"Jogador recebeu ",
		valor,
		" de dano. Vida: ",
		vida
	)


	# ==================================================
	# VERIFICAR MORTE
	# ==================================================

	if vida <= 0.0:

		morrer()


# ==================================================
# MORRER
# ==================================================

func morrer() -> void:

	print(
		"Jogador morreu!"
	)


	velocity = Vector2.ZERO

	atacando = false

	dashing = false


	# Esconde o golpe

	golpe.visible = false


	# Animação parado

	animacao.play("parado")


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
