extends CharacterBody2D


# ==================================================
# MOVIMENTO
# ==================================================

@export var velocidade: float = 120.0

# Guarda a última direção em que o personagem estava andando.
# É utilizada pelo ataque e pelo dash.
var ultima_direcao: Vector2 = Vector2.DOWN


# ==================================================
# ANIMAÇÃO
# ==================================================

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D


# ==================================================
# DASH
# ==================================================

# Distância total do dash
@export var distancia_dash: float = 70.0

# Velocidade do dash
@export var velocidade_dash: float = 500.0

# Tempo de espera entre os dashes
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

@export var alcance_ataque: float = 60.0
@export var angulo_ataque: float = 160.0
@export var dano: float = 10.0
@export var duracao_ataque: float = 0.35

var atacando: bool = false

var inimigos_atingidos: Array[Node] = []

@onready var attack_pivot: Node2D = $AttackPivot
@onready var golpe: AnimatedSprite2D = $AttackPivot/Golpe


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	# --------------------------------------------------
	# Grupo do jogador
	# --------------------------------------------------

	add_to_group("jogador")


	# --------------------------------------------------
	# Vida
	# --------------------------------------------------

	vida = vida_maxima


	# --------------------------------------------------
	# Barra de vida
	# --------------------------------------------------

	barra_vida.max_value = vida_maxima
	barra_vida.value = vida


	# --------------------------------------------------
	# Golpe
	# --------------------------------------------------

	golpe.visible = false


	# --------------------------------------------------
	# Animação inicial
	# --------------------------------------------------

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
	# PEGAR DIREÇÃO DO JOGADOR
	# ==================================================

	var direcao: Vector2 = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)


	# ==================================================
	# MOVIMENTO NORMAL
	# ==================================================

	if not atacando:

		velocity = direcao * velocidade


		# --------------------------------------------------
		# ESTÁ ANDANDO
		# --------------------------------------------------

		if direcao != Vector2.ZERO:

			# Guarda a última direção
			ultima_direcao = direcao.normalized()

			# Atualiza a animação
			atualizar_animacao(direcao)


		# --------------------------------------------------
		# ESTÁ PARADO
		# --------------------------------------------------

		else:

			atualizar_animacao_parado()


	# ==================================================
	# DURANTE ATAQUE
	# ==================================================

	else:

		velocity = Vector2.ZERO


	# ==================================================
	# MOVIMENTO
	# ==================================================

	move_and_slide()


	# ==================================================
	# ATAQUE
	# ==================================================

	if atacando:

		verificar_inimigos()


# ==================================================
# ATUALIZAR ANIMAÇÃO DE MOVIMENTO
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

	# O personagem sempre olha para a tela
	# quando está parado.

	animacao.play("parado")


# ==================================================
# DASH
# ==================================================

func iniciar_dash() -> void:

	# --------------------------------------------------
	# Verifica se pode dar dash
	# --------------------------------------------------

	if dashing:

		return


	if atacando:

		return


	if not dash_disponivel:

		return


	# --------------------------------------------------
	# Inicia dash
	# --------------------------------------------------

	dashing = true

	dash_disponivel = false

	velocity = Vector2.ZERO


	# ==================================================
	# DIREÇÃO DO DASH
	# ==================================================

	# O dash usa a última direção em que o jogador
	# estava andando.

	var direcao_dash: Vector2 = ultima_direcao.normalized()


	# ==================================================
	# DISTÂNCIA PERCORRIDA
	# ==================================================

	var distancia_percorrida: float = 0.0


	# ==================================================
	# MOVIMENTO DO DASH
	# ==================================================

	while distancia_percorrida < distancia_dash:

		# Calcula o movimento deste frame
		var movimento: Vector2 = (
			direcao_dash
			* velocidade_dash
			* get_process_delta_time()
		)


		# Calcula quanto ainda falta
		var restante: float = (
			distancia_dash
			- distancia_percorrida
		)


		# Evita ultrapassar a distância
		if movimento.length() > restante:

			movimento = direcao_dash * restante


		# --------------------------------------------------
		# Move com colisão
		# --------------------------------------------------

		var colisao: KinematicCollision2D = move_and_collide(
			movimento
		)


		# Atualiza distância
		distancia_percorrida += movimento.length()


		# --------------------------------------------------
		# Bateu em alguma coisa
		# --------------------------------------------------

		if colisao != null:

			print("Dash bateu em uma parede!")

			break


		await get_tree().process_frame


	# ==================================================
	# FINALIZAR DASH
	# ==================================================

	velocity = Vector2.ZERO

	dashing = false


	# Volta para o sprite parado
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


	print("Dash disponível novamente!")


# ==================================================
# ATAQUE
# ==================================================

func atacar() -> void:

	# --------------------------------------------------
	# Não pode atacar durante dash
	# --------------------------------------------------

	if dashing:

		return


	# --------------------------------------------------
	# Não pode atacar se já estiver atacando
	# --------------------------------------------------

	if atacando:

		return


	# --------------------------------------------------
	# Inicia ataque
	# --------------------------------------------------

	atacando = true

	inimigos_atingidos.clear()


	# ==================================================
	# MOSTRAR GOLPE
	# ==================================================

	golpe.visible = true


	# Coloca o golpe no início do arco
	attack_pivot.rotation_degrees = (
		-angulo_ataque / 2.0
	)


	# ==================================================
	# ANIMAÇÃO DO GOLPE
	# ==================================================

	if golpe.sprite_frames != null:

		if golpe.sprite_frames.has_animation("golpe"):

			golpe.play("golpe")


	# ==================================================
	# MOVIMENTO DO GOLPE
	# ==================================================

	var tween: Tween = create_tween()


	tween.tween_property(
		attack_pivot,
		"rotation_degrees",
		angulo_ataque / 2.0,
		duracao_ataque
	)


	await tween.finished


	# ==================================================
	# FINALIZAR ATAQUE
	# ==================================================

	golpe.stop()

	golpe.visible = false

	attack_pivot.rotation_degrees = 0.0

	atacando = false


	# Volta para o personagem parado
	animacao.play("parado")


# ==================================================
# VERIFICAR INIMIGOS ATINGIDOS
# ==================================================

func verificar_inimigos() -> void:

	var inimigos: Array[Node] = get_tree().get_nodes_in_group(
		"inimigos"
	)


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

		var distancia: float = global_position.distance_to(
			alvo.global_position
		)


		if distancia > alcance_ataque:

			continue


		# ==================================================
		# DIREÇÃO DO ATAQUE
		# ==================================================

		var direcao_ataque: Vector2 = (
			ultima_direcao
			.rotated(attack_pivot.rotation)
		)


		var direcao_inimigo: Vector2 = (
			global_position.direction_to(
				alvo.global_position
			)
		)


		var angulo: float = abs(
			direcao_ataque.angle_to(
				direcao_inimigo
			)
		)


		# ==================================================
		# VERIFICAR ARCO
		# ==================================================

		if angulo <= deg_to_rad(40.0):

			# Marca como atingido
			inimigos_atingidos.append(inimigo)


			# Causa dano
			if alvo.has_method("receber_dano"):

				alvo.receber_dano(dano)


# ==================================================
# RECEBER DANO
# ==================================================

func receber_dano(valor: float) -> void:

	vida -= valor


	vida = clamp(
		vida,
		0.0,
		vida_maxima
	)


	# Atualiza barra
	barra_vida.value = vida


	print(
		"Jogador recebeu ",
		valor,
		" de dano. Vida: ",
		vida
	)


	# Verifica morte
	if vida <= 0.0:

		morrer()


# ==================================================
# MORRER
# ==================================================

func morrer() -> void:

	print("Jogador morreu!")


	velocity = Vector2.ZERO

	atacando = false

	dashing = false

	golpe.visible = false

	# Mantém o personagem parado
	animacao.play("parado")


# ==================================================
# INPUT
# ==================================================

func _input(event: InputEvent) -> void:

	# ==================================================
	# ATAQUE
	# ==================================================

	if event is InputEventMouseButton:

		var mouse_event: InputEventMouseButton = (
			event as InputEventMouseButton
		)


		if mouse_event.button_index == MOUSE_BUTTON_LEFT:

			if mouse_event.pressed:

				atacar()


	# ==================================================
	# DASH
	# ==================================================

	if event is InputEventKey:

		var key_event: InputEventKey = (
			event as InputEventKey
		)


		if key_event.keycode == KEY_SPACE:

			if key_event.pressed and not key_event.echo:

				iniciar_dash()
