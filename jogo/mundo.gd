extends CharacterBody2D


# ==================================================
# MOVIMENTO
# ==================================================

@export var velocidade: float = 120.0


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
@export var duracao_ataque: float = 0.4

var atacando: bool = false
var inimigos_atingidos: Array[Node] = []

@onready var attack_pivot: Node2D = $AttackPivot
@onready var golpe: AnimatedSprite2D = $AttackPivot/Golpe


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	# Adiciona o jogador ao grupo
	add_to_group("jogador")

	# Inicializa a vida
	vida = vida_maxima

	# Configura a barra de vida
	barra_vida.max_value = vida_maxima
	barra_vida.value = vida

	# Esconde o golpe
	golpe.visible = false


# ==================================================
# FÍSICA
# ==================================================

func _physics_process(_delta: float) -> void:

	# ==================================================
	# MOVIMENTO
	# ==================================================

	var direcao: Vector2 = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	# Se estiver atacando, não pode se mover
	if atacando:

		velocity = Vector2.ZERO

	else:

		velocity = direcao * velocidade

		# Rotaciona para a direção do movimento
		if direcao != Vector2.ZERO:
			rotation = direcao.angle()

	move_and_slide()


	# ==================================================
	# VERIFICAR ATAQUE
	# ==================================================

	if atacando:

		verificar_inimigos()


# ==================================================
# ATAQUE
# ==================================================

func atacar() -> void:

	# Não pode atacar enquanto já estiver atacando
	if atacando:
		return

	atacando = true

	# Limpa a lista de inimigos atingidos
	inimigos_atingidos.clear()

	# Mostra o golpe
	golpe.visible = true

	# Coloca o golpe no início do arco
	attack_pivot.rotation_degrees = -angulo_ataque / 2.0


	# ==================================================
	# ANIMAÇÃO
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


# ==================================================
# VERIFICAR INIMIGOS ATINGIDOS
# ==================================================

func verificar_inimigos() -> void:

	var inimigos: Array[Node] = get_tree().get_nodes_in_group("inimigos")

	for inimigo: Node in inimigos:

		# Verifica se ainda existe
		if not is_instance_valid(inimigo):
			continue

		# Não pode acertar o mesmo inimigo duas vezes
		if inimigos_atingidos.has(inimigo):
			continue

		# Só trabalha com CharacterBody2D
		if not inimigo is CharacterBody2D:
			continue

		var alvo: CharacterBody2D = inimigo as CharacterBody2D

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

		var direcao_ataque: Vector2 = Vector2.RIGHT.rotated(
			rotation + attack_pivot.rotation
		)

		var direcao_inimigo: Vector2 = global_position.direction_to(
			alvo.global_position
		)

		var angulo: float = abs(
			direcao_ataque.angle_to(direcao_inimigo)
		)


		# ==================================================
		# VERIFICAR SE ESTÁ DENTRO DO ARCO
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

	barra_vida.value = vida

	print("Jogador recebeu ", valor, " de dano. Vida: ", vida)

	if vida <= 0.0:

		morrer()


# ==================================================
# MORRER
# ==================================================

func morrer() -> void:

	print("Jogador morreu!")

	velocity = Vector2.ZERO

	atacando = false

	golpe.visible = false


# ==================================================
# INPUT
# ==================================================

func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton:

		var mouse_event: InputEventMouseButton = event as InputEventMouseButton

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:

			if mouse_event.pressed:

				atacar()
