extends CharacterBody2D


# ==================================================
# MOVIMENTO
# ==================================================

@export var velocidade: float = 50.0


# ==================================================
# VIDA
# ==================================================

@export var vida_maxima: float = 30.0
const DANO_AO_JOGADOR: int = 1
const FATOR_DIFICULDADE: float = 1.0

var vida: float
var jogador: CharacterBody2D = null
var recompensa_tokens: int = 1


# ==================================================
# ATAQUE
# ==================================================

@export var distancia_ataque: float = 40.0
@export var alcance_golpe: float = 60.0
@export var largura_golpe: float = 12.0

@export var tempo_carregamento: float = 0.6
@export var tempo_golpe: float = 0.3
@export var tempo_cooldown: float = 1.0

var atacando: bool = false
var pode_atacar: bool = true
var morrendo: bool = false

@onready var attack_area: Polygon2D = $AttackArea/Polygon2D
@onready var icon: AnimatedSprite2D = $Icon


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:
	var atributos: Dictionary = DificuldadeGlobal.aplicar_dificuldade_inimigo(
		vida_maxima,
		velocidade,
		FATOR_DIFICULDADE
	)
	vida_maxima = atributos["vida"]
	velocidade = atributos["velocidade"]
	recompensa_tokens = atributos["recompensa"]

	vida = vida_maxima

	# Coloca o inimigo no grupo
	add_to_group("inimigos")

	# Procura o jogador
	procurar_jogador()

	# Esconde a área de ataque
	attack_area.visible = false

	# Cria o formato visual do ataque
	criar_area_ataque()


# ==================================================
# FÍSICA
# ==================================================

func _physics_process(_delta: float) -> void:

	# ==================================================
	# PROCURAR JOGADOR
	# ==================================================

	if jogador == null or not is_instance_valid(jogador):

		procurar_jogador()

		velocity = Vector2.ZERO
		icon.play("parado")

		return


	# ==================================================
	# DURANTE O ATAQUE
	# ==================================================

	if atacando:

		# O inimigo fica completamente parado
		velocity = Vector2.ZERO
		icon.play("parado")

		move_and_slide()

		return


	# ==================================================
	# DISTÂNCIA DO JOGADOR
	# ==================================================

	var direcao: Vector2 = global_position.direction_to(
		jogador.global_position
	)

	var distancia: float = global_position.distance_to(
		jogador.global_position
	)


	# ==================================================
	# ATAQUE
	# ==================================================

	if distancia <= distancia_ataque:

		# Para
		velocity = Vector2.ZERO

		move_and_slide()

		# Ataca
		if pode_atacar:

			iniciar_ataque()

		return


	# ==================================================
	# PERSEGUIR JOGADOR
	# ==================================================

	velocity = direcao * velocidade
	icon.flip_h = direcao.x < 0.0
	icon.play("andar")

	move_and_slide()


# ==================================================
# PROCURAR JOGADOR
# ==================================================

func procurar_jogador() -> void:

	var encontrado: Node = get_tree().get_first_node_in_group("jogador")

	if encontrado != null:

		jogador = encontrado as CharacterBody2D


# ==================================================
# INICIAR ATAQUE
# ==================================================

func iniciar_ataque() -> void:

	if atacando:
		return

	if not pode_atacar:
		return


	# ==================================================
	# COMEÇA ATAQUE
	# ==================================================

	atacando = true

	pode_atacar = false

	# Para imediatamente
	velocity = Vector2.ZERO
	icon.play("ataque")


	# ==================================================
	# APONTAR PARA O JOGADOR
	# ==================================================

	apontar_area_para_jogador()


	# ==================================================
	# MOSTRAR ÁREA VERMELHA
	# ==================================================

	attack_area.visible = true


	# ==================================================
	# CARREGAMENTO — 0.3s
	# ==================================================

	await get_tree().create_timer(
		tempo_carregamento
	).timeout


	# ==================================================
	# GOLPE
	# ==================================================

	# Continua parado
	velocity = Vector2.ZERO

	# Causa dano
	verificar_dano_ataque()


	# ==================================================
	# DURAÇÃO DO GOLPE — 0.3s
	# ==================================================

	await get_tree().create_timer(
		tempo_golpe
	).timeout


	# ==================================================
	# FINALIZAR
	# ==================================================

	finalizar_ataque()


# ==================================================
# VERIFICAR DANO DO ATAQUE
# ==================================================

func verificar_dano_ataque() -> void:

	if jogador == null:
		return

	if not is_instance_valid(jogador):
		return


	# ==================================================
	# DISTÂNCIA
	# ==================================================

	var distancia: float = global_position.distance_to(
		jogador.global_position
	)

	if distancia > alcance_golpe:
		return


	# ==================================================
	# DIREÇÃO DO GOLPE
	# ==================================================

	var direcao_jogador: Vector2 = global_position.direction_to(
		jogador.global_position
	)

	var direcao_golpe: Vector2 = Vector2.RIGHT.rotated(
		attack_area.rotation
	)


	# ==================================================
	# ÂNGULO
	# ==================================================

	var angulo: float = abs(
		direcao_golpe.angle_to(direcao_jogador)
	)


	# ==================================================
	# JOGADOR ESTÁ NA LINHA DO GOLPE
	# ==================================================

	if angulo <= deg_to_rad(15.0):

		if jogador.has_method("receber_dano"):

			jogador.receber_dano(DANO_AO_JOGADOR)

			print("Inimigo atacou o jogador!")


# ==================================================
# APONTAR ATAQUE PARA O JOGADOR
# ==================================================

func apontar_area_para_jogador() -> void:

	if jogador == null:
		return

	if not is_instance_valid(jogador):
		return

	var direcao: Vector2 = global_position.direction_to(
		jogador.global_position
	)

	attack_area.rotation = direcao.angle()
	icon.flip_h = direcao.x < 0.0


# ==================================================
# CRIAR ÁREA VISUAL DO ATAQUE
# ==================================================

func criar_area_ataque() -> void:

	var metade_largura: float = largura_golpe / 2.0

	var pontos: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -metade_largura),
		Vector2(alcance_golpe, -metade_largura),
		Vector2(alcance_golpe, metade_largura),
		Vector2(0.0, metade_largura)
	])

	attack_area.polygon = pontos

	# Vermelho com 80% de opacidade
	attack_area.color = Color(
		1.0,
		0.0,
		0.0,
		0.8
	)


# ==================================================
# FINALIZAR ATAQUE
# ==================================================

func finalizar_ataque() -> void:

	# Esconde a área vermelha
	attack_area.visible = false

	# Libera o movimento
	atacando = false
	icon.play("parado")


	# ==================================================
	# COOLDOWN
	# ==================================================

	await get_tree().create_timer(
		tempo_cooldown
	).timeout

	pode_atacar = true


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
		"Inimigo recebeu ",
		valor,
		" de dano. Vida: ",
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
	DificuldadeGlobal.dropar_tokens(global_position, recompensa_tokens)

	print("Inimigo morreu!")
	velocity = Vector2.ZERO
	atacando = false
	pode_atacar = false
	attack_area.visible = false
	icon.play("derrotado")
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
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
