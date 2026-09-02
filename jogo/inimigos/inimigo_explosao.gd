extends CharacterBody2D


# ==================================================
# CONFIGURAÇÕES
# ==================================================

@export var velocidade: float = 50.0

# Distância para começar a carregar a explosão
@export var distancia_ativacao: float = 60.0

# Raio da explosão
@export var raio_explosao: float = 70.0

# Dano causado pela explosão
@export var dano: float = 20.0

# Tempo tremendo antes da explosão
@export var tempo_carregamento: float = 0.8

# Tempo esperando depois da explosão
@export var tempo_cooldown: float = 3.0

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
var em_cooldown := false


# ==================================================
# REFERÊNCIAS
# ==================================================

@onready var icon: Node2D = $Icon
@onready var raio_dano: Node2D = $raioDano

@onready var area_dano: Area2D = $Area2D

@onready var collision_dano: CollisionShape2D = $Area2D/CollisionShape2D


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	vida = vida_maxima

	add_to_group("inimigos")

	procurar_jogador()

	# Centraliza o raio no inimigo
	raio_dano.position = Vector2.ZERO
	raio_dano.color.a = 0.2

	# Esconde inicialmente
	raio_dano.visible = false

	# Cria o círculo de dano
	var circulo := CircleShape2D.new()
	circulo.radius = raio_explosao

	collision_dano.shape = circulo

	area_dano.monitoring = false


# ==================================================
# FÍSICA
# ==================================================

func _physics_process(_delta: float) -> void:

	# Se estiver explodindo ou no cooldown,
	# permanece parado
	if explodindo or em_cooldown:
		velocity = Vector2.ZERO
		return


	# Procura o jogador caso ele não exista
	if not is_instance_valid(jogador):

		procurar_jogador()

		velocity = Vector2.ZERO

		return


	# Calcula a distância até o jogador
	var distancia := global_position.distance_to(
		jogador.global_position
	)


	# ==================================================
	# COMEÇAR A CARREGAR
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

	if carregando or explodindo or em_cooldown:
		return

	carregando = true

	velocity = Vector2.ZERO

	print("Inimigo explosivo começou a carregar!")


	# Mostra o raio
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

		# Tremor aleatório
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


	# Retorna à posição original
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

	print("💥 EXPLOSÃO!")


	# Ativa a área de dano
	area_dano.monitoring = true


	# Verifica se o jogador está dentro do raio
	aplicar_dano()


	# Mantém o efeito da explosão por um pequeno tempo
	await get_tree().create_timer(0.15).timeout


	# Desativa a área
	area_dano.monitoring = false

	raio_dano.visible = false


	# Finaliza a explosão
	explodindo = false


	# Começa o cooldown de 3 segundos
	iniciar_cooldown()


# ==================================================
# COOLDOWN
# ==================================================

func iniciar_cooldown() -> void:

	if em_cooldown:
		return

	em_cooldown = true

	velocity = Vector2.ZERO

	print("Inimigo entrou em cooldown por ", tempo_cooldown, " segundos.")


	await get_tree().create_timer(tempo_cooldown).timeout


	em_cooldown = false

	print("Inimigo pode explodir novamente!")


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
