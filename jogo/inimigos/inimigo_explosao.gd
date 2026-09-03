extends CharacterBody2D


# ==================================================
# CONFIGURAÇÕES
# ==================================================

@export var velocidade: float = 40.0

# Distância para começar a carregar a explosão
# Aumentei para 35 para facilitar o funcionamento.
@export var distancia_ativacao: float = 35.0

# Raio da explosão
@export var raio_explosao: float = 70.0

# Dano causado pela explosão
const DANO_AO_JOGADOR: int = 1

# Tempo preparando a explosão
@export var tempo_carregamento: float = 1.5

# Tempo esperando depois da explosão
@export var tempo_cooldown: float = 3.0


# ==================================================
# FUMAÇA
# ==================================================

# Quanto tempo a fumaça permanece
@export var duracao_fumaca: float = 2.5


# ==================================================
# TREMOR DA EXPLOSÃO
# ==================================================

@export var intensidade_tremor: float = 2.0

@export var intensidade_tremor_final: float = 8.0


# ==================================================
# ANIMAÇÃO DE MOVIMENTO
# ==================================================

@export var velocidade_pulo: float = 8.0

@export var altura_pulo: float = 3.0

@export var intensidade_balanco: float = 5.0

@export var movimento_lateral: float = 2.0


# ==================================================
# VIDA
# ==================================================

@export var vida_maxima: float = 30.0

var vida: float


# ==================================================
# ESTADO
# ==================================================

var jogador: CharacterBody2D = null

var carregando: bool = false

var explodindo: bool = false

var em_cooldown: bool = false
var morrendo: bool = false


# ==================================================
# REFERÊNCIAS
# ==================================================

@onready var icon: Node2D = $Icon

@onready var raio_dano: Polygon2D = $raioDano

@onready var area_dano: Area2D = $Area2D

@onready var collision_dano: CollisionShape2D = (
	$Area2D/CollisionShape2D
)


# ==================================================
# FUMAÇA
# ==================================================

# IMPORTANTE:
# O seu Fumaca é CPUParticles2D.
@onready var fumaca: CPUParticles2D = $Fumaca


# ==================================================
# ANIMAÇÃO
# ==================================================

var tempo_movimento: float = 0.0

var icon_posicao_original: Vector2

var icon_rotacao_original: float


# ==================================================
# READY
# ==================================================

func _ready() -> void:

	vida = vida_maxima

	add_to_group("inimigos")

	procurar_jogador()


	# ==================================================
	# GUARDAR POSIÇÃO DO ICON
	# ==================================================

	icon_posicao_original = icon.position

	icon_rotacao_original = icon.rotation


	# ==================================================
	# CONFIGURAR RAIO DA EXPLOSÃO
	# ==================================================

	raio_dano.position = Vector2.ZERO

	raio_dano.visible = false

	raio_dano.color = Color(
		1.0,
		0.0,
		0.0,
		0.2
	)


	# ==================================================
	# CONFIGURAR COLISÃO DA EXPLOSÃO
	# ==================================================

	var circulo: CircleShape2D = CircleShape2D.new()

	circulo.radius = raio_explosao

	collision_dano.shape = circulo

	area_dano.monitoring = false


	# ==================================================
	# CONFIGURAR FUMAÇA
	# ==================================================

	fumaca.emitting = false

	fumaca.one_shot = true


	print("Inimigo explosivo pronto!")


# ==================================================
# PROCESS
# ==================================================

func _process(delta: float) -> void:

	# Durante preparação, explosão ou cooldown,
	# não executar animação de caminhada.

	if carregando or explodindo or em_cooldown:

		return


	# ==================================================
	# ANIMAÇÃO ANDANDO
	# ==================================================

	if velocity.length() > 0.1:

		animar_movimento(delta)

	else:

		icon.position = icon.position.lerp(
			icon_posicao_original,
			delta * 10.0
		)

		icon.rotation = lerp_angle(
			icon.rotation,
			icon_rotacao_original,
			delta * 10.0
		)


# ==================================================
# PHYSICS PROCESS
# ==================================================

func _physics_process(_delta: float) -> void:

	# ==================================================
	# EXPLODINDO
	# ==================================================

	if explodindo:

		velocity = Vector2.ZERO

		return


	# ==================================================
	# COOLDOWN
	# ==================================================

	if em_cooldown:

		velocity = Vector2.ZERO

		return


	# ==================================================
	# CARREGANDO
	# ==================================================

	if carregando:

		velocity = Vector2.ZERO

		return


	# ==================================================
	# PROCURAR JOGADOR
	# ==================================================

	if jogador == null or not is_instance_valid(jogador):

		procurar_jogador()

		velocity = Vector2.ZERO

		return


	# ==================================================
	# CALCULAR DISTÂNCIA
	# ==================================================

	var distancia: float = global_position.distance_to(
		jogador.global_position
	)


	# ==================================================
	# DEBUG
	# ==================================================

	# Descomente se quiser verificar a distância.
	# print("Distância até jogador: ", distancia)


	# ==================================================
	# DISTÂNCIA DE ATIVAÇÃO
	# ==================================================

	if distancia <= distancia_ativacao:

		velocity = Vector2.ZERO

		if not carregando:

			iniciar_carregamento()

		return


	# ==================================================
	# PERSEGUIR JOGADOR
	# ==================================================

	var direcao: Vector2 = global_position.direction_to(
		jogador.global_position
	)

	velocity = direcao * velocidade

	move_and_slide()


# ==================================================
# PROCURAR JOGADOR
# ==================================================

func procurar_jogador() -> void:

	var encontrado: Node = get_tree().get_first_node_in_group(
		"jogador"
	)

	if encontrado != null:

		jogador = encontrado as CharacterBody2D

		print("Jogador encontrado!")


# ==================================================
# INICIAR CARREGAMENTO
# ==================================================

func iniciar_carregamento() -> void:

	if carregando:

		return

	if explodindo:

		return

	if em_cooldown:

		return


	# ==================================================
	# ATIVAR ESTADO
	# ==================================================

	carregando = true

	velocity = Vector2.ZERO


	# ==================================================
	# MOSTRAR RAIO
	# ==================================================

	raio_dano.visible = true


	print("================================")
	print("EXTINTOR COMEÇOU A CARREGAR!")
	print("Tempo: ", tempo_carregamento)
	print("================================")


	# ==================================================
	# TREMOR
	# ==================================================

	await tremer()


# ==================================================
# TREMOR
# ==================================================

func tremer() -> void:

	var tempo: float = 0.0


	while tempo < tempo_carregamento:

		# Se o objeto foi destruído
		if not is_instance_valid(self):

			return


		# Se por algum motivo deixou de carregar
		if not carregando:

			return


		# ==================================================
		# PROGRESSO
		# ==================================================

		var progresso: float = tempo / tempo_carregamento

		progresso = clamp(
			progresso,
			0.0,
			1.0
		)


		# ==================================================
		# INTENSIDADE
		# ==================================================

		var intensidade_atual: float = lerp(
			intensidade_tremor,
			intensidade_tremor_final,
			progresso
		)


		# ==================================================
		# TREMOR POSIÇÃO
		# ==================================================

		icon.position = (
			icon_posicao_original
			+ Vector2(
				randf_range(
					-intensidade_atual,
					intensidade_atual
				),
				randf_range(
					-intensidade_atual,
					intensidade_atual
				)
			)
		)


		# ==================================================
		# TREMOR ROTAÇÃO
		# ==================================================

		var tremor_rotacao: float = randf_range(
			-intensidade_atual,
			intensidade_atual
		)


		icon.rotation = (
			icon_rotacao_original
			+ deg_to_rad(tremor_rotacao)
		)


		# ==================================================
		# ESPERAR
		# ==================================================

		await get_tree().process_frame

		tempo += get_process_delta_time()


	# ==================================================
	# RESTAURAR ICON
	# ==================================================

	icon.position = icon_posicao_original

	icon.rotation = icon_rotacao_original


	# ==================================================
	# EXPLODIR
	# ==================================================

	explodir()


# ==================================================
# ANIMAÇÃO DE MOVIMENTO
# ==================================================

func animar_movimento(delta: float) -> void:

	tempo_movimento += (
		delta * velocidade_pulo
	)


	# ==================================================
	# PULO
	# ==================================================

	var pulo: float = abs(
		sin(tempo_movimento)
	)


	icon.position.y = (
		icon_posicao_original.y
		- pulo * altura_pulo
	)


	# ==================================================
	# BALANÇO
	# ==================================================

	var balanco: float = sin(
		tempo_movimento * 1.5
	)


	icon.position.x = (
		icon_posicao_original.x
		+ balanco * movimento_lateral
	)


	# ==================================================
	# ROTAÇÃO
	# ==================================================

	icon.rotation = (
		icon_rotacao_original
		+ deg_to_rad(
			balanco * intensidade_balanco
		)
	)


# ==================================================
# EXPLODIR
# ==================================================

func explodir() -> void:

	if explodindo:

		return


	# ==================================================
	# MUDAR ESTADOS
	# ==================================================

	explodindo = true

	carregando = false

	velocity = Vector2.ZERO


	# ==================================================
	# RESETAR ICON
	# ==================================================

	icon.position = icon_posicao_original

	icon.rotation = icon_rotacao_original


	print("================================")
	print("💥 EXTINTOR EXPLODIU!")
	print("================================")


	# ==================================================
	# ATIVAR RAIO
	# ==================================================

	raio_dano.visible = true

	area_dano.monitoring = true


	# ==================================================
	# APLICAR DANO
	# ==================================================

	aplicar_dano()


	# ==================================================
	# DURAÇÃO DA EXPLOSÃO
	# ==================================================

	await get_tree().create_timer(
		0.15
	).timeout


	# ==================================================
	# DESATIVAR RAIO
	# ==================================================

	area_dano.monitoring = false

	raio_dano.visible = false


	# ==================================================
	# TERMINAR EXPLOSÃO
	# ==================================================

	explodindo = false


	# ==================================================
	# FUMAÇA
	# ==================================================

	iniciar_fumaca()


	# ==================================================
	# COOLDOWN
	# ==================================================

	iniciar_cooldown()


# ==================================================
# FUMAÇA
# ==================================================

func iniciar_fumaca() -> void:

	if not is_instance_valid(fumaca):

		print("ERRO: Fumaca não existe!")

		return


	print("Fumaça iniciada!")


	# ==================================================
	# REINICIAR PARTÍCULAS
	# ==================================================

	fumaca.emitting = false

	fumaca.restart()

	fumaca.emitting = true


	# ==================================================
	# ESPERAR
	# ==================================================

	await get_tree().create_timer(
		duracao_fumaca
	).timeout


	# ==================================================
	# DESLIGAR
	# ==================================================

	if is_instance_valid(fumaca):

		fumaca.emitting = false


	print("Fumaça terminou!")


# ==================================================
# COOLDOWN
# ==================================================

func iniciar_cooldown() -> void:

	if em_cooldown:

		return


	em_cooldown = true

	velocity = Vector2.ZERO


	print(
		"Cooldown iniciado: ",
		tempo_cooldown,
		" segundos."
	)


	await get_tree().create_timer(
		tempo_cooldown
	).timeout


	if not is_instance_valid(self):

		return


	em_cooldown = false


	print("Extintor pode explodir novamente!")


# ==================================================
# APLICAR DANO
# ==================================================

func aplicar_dano() -> void:

	if jogador == null:

		return

	if not is_instance_valid(jogador):

		return


	# ==================================================
	# DISTÂNCIA
	# ==================================================

	var distancia: float = (
		global_position.distance_to(
			jogador.global_position
		)
	)


	print(
		"Distância do jogador na explosão: ",
		distancia
	)


	# ==================================================
	# VERIFICAR RAIO
	# ==================================================

	if distancia <= raio_explosao:

		print("JOGADOR ATINGIDO PELA EXPLOSÃO!")


		if jogador.has_method("receber_dano"):

			jogador.receber_dano(DANO_AO_JOGADOR)

	else:

		print("Jogador estava fora do raio.")


# ==================================================
# RECEBER DANO
# ==================================================

func receber_dano(valor: float) -> void:
	if morrendo:
		return

	vida -= valor

	vida = clamp(
		vida,
		0.0,
		vida_maxima
	)


	print(
		"Extintor recebeu dano: ",
		valor
	)

	print(
		"Vida atual: ",
		vida
	)


	if vida <= 0.0:

		morrer()


# ==================================================
# MORRER
# ==================================================

func morrer() -> void:
	if morrendo:
		return
	morrendo = true

	print("Extintor morreu!")

	velocity = Vector2.ZERO
	carregando = false
	explodindo = false
	em_cooldown = true
	raio_dano.visible = false
	area_dano.set_deferred("monitoring", false)
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	collision_dano.set_deferred("disabled", true)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.4)
	tween.tween_property(self, "scale", scale * 0.15, 0.4)
	tween.tween_property(self, "position", position + Vector2(0, -12), 0.4)
	tween.tween_property(self, "rotation", rotation + deg_to_rad(90.0), 0.4)
	await tween.finished

	queue_free()
