extends CharacterBody2D


# ==================================================
# CONFIGURAÇÕES
# ==================================================

@export var velocidade: float = 50.0

# Distância para começar a carregar a explosão
@export var distancia_ativacao: float = 100.0

# Raio da explosão
@export var raio_explosao: float = 100.0

# Dano da explosão
@export var dano: float = 20.0

# Tempo tremendo antes de explodir
@export var tempo_carregamento: float = 1.0

# Intensidade da tremedeira
@export var intensidade_tremor: float = 5.0


# ==================================================
# VIDA
# ==================================================

@export var vida_maxima: float = 30.0

var vida: float


# ==================================================
# ESTADO
# ==================================================

var jogador: CharacterBody2D = null

var carregando := false
var explodindo := false


# ==================================================
# REFERÊNCIAS
# ==================================================

@onready var icon: Node2D = $Icon
@onready var raio_dano: Node2D = $CanvasLayer/raioDano

# IMPORTANTE:
# Na sua cena o nome é Area2D
@onready var area_dano: Area2D = $Area2D

@onready var collision_dano: CollisionShape2D = $Area2D/CollisionShape2D


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	vida = vida_maxima

	add_to_group("inimigos")

	procurar_jogador()

	# Esconde o raio inicialmente
	raio_dano.visible = false

	# Cria o círculo de colisão
	var circulo := CircleShape2D.new()

	circulo.radius = raio_explosao

	collision_dano.shape = circulo

	# Desativa a área até a explosão
	area_dano.monitoring = false


# ==================================================
# FÍSICA
# ==================================================

func _physics_process(_delta: float) -> void:

	if explodindo:
		return

	# Se não encontrou o jogador
	if not is_instance_valid(jogador):

		procurar_jogador()

		velocity = Vector2.ZERO

		return


	# Calcula distância até o jogador
	var distancia := global_position.distance_to(
		jogador.global_position
	)


	# ==================================================
	# COMEÇAR A CARREGAR EXPLOSÃO
	# ==================================================

	if distancia <= distancia_ativacao:

		if not carregando:
			iniciar_carregamento()

		velocity = Vector2.ZERO

		return


	# ==================================================
	# PERSEGUIR JOGADOR
	# ==================================================

	var direcao := global_position.direction_to(
		jogador.global_position
	)

	velocity = direcao * velocidade

	move_and_slide()


# ==================================================
# PROCURAR JOGADOR
# ==================================================

func procurar_jogador() -> void:

	var encontrado := get_tree().get_first_node_in_group("jogador")

	if encontrado != null:
		jogador = encontrado as CharacterBody2D


# ==================================================
# INICIAR CARREGAMENTO
# ==================================================

func iniciar_carregamento() -> void:

	if carregando:
		return

	carregando = true

	velocity = Vector2.ZERO

	print("Inimigo explosivo começou a carregar!")


	# Mostra área da explosão
	raio_dano.visible = true


	# Começa a tremer
	await tremer()


# ==================================================
# TREMER
# ==================================================

func tremer() -> void:

	var tempo := 0.0

	var posicao_original := icon.position


	while tempo < tempo_carregamento:

		# Tremedeira aleatória
		icon.position = posicao_original + Vector2(
			randf_range(
				-intensidade_tremor,
				intensidade_tremor
			),
			randf_range(
				-intensidade_tremor,
				intensidade_tremor
			)
		)

		await get_tree().process_frame

		tempo += get_process_delta_time()


	# Volta para a posição original
	icon.position = posicao_original


	# Explode
	explodir()


# ==================================================
# EXPLODIR
# ==================================================

func explodir() -> void:

	if explodindo:
		return

	explodindo = true

	carregando = false

	velocity = Vector2.ZERO

	print("EXPLOSAO!")


	# Ativa a área de dano
	area_dano.monitoring = true


	# Verifica se o jogador está dentro do círculo
	aplicar_dano()


	# Aguarda um pouco
	await get_tree().create_timer(0.15).timeout


	# Desativa a área
	area_dano.monitoring = false


	# Remove o inimigo
	morrer()


# ==================================================
# APLICAR DANO
# ==================================================

func aplicar_dano() -> void:

	if not is_instance_valid(jogador):
		return


	var distancia := global_position.distance_to(
		jogador.global_position
	)


	# Jogador está dentro do círculo?
	if distancia <= raio_explosao:

		print("Jogador atingido pela explosão!")

		jogador.receber_dano(dano)


# ==================================================
# RECEBER DANO
# ==================================================

func receber_dano(valor: float) -> void:

	vida -= valor

	print("Inimigo explosivo recebeu dano: ", valor)
	print("Vida atual: ", vida)


	if vida <= 0:
		morrer()


# ==================================================
# MORRER
# ==================================================

func morrer() -> void:

	print("Inimigo explosivo morreu!")

	velocity = Vector2.ZERO

	queue_free()
