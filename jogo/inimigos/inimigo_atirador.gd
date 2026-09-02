extends CharacterBody2D


# ==================================================
# MOVIMENTO
# ==================================================

@export var velocidade: float = 40.0

# Distância que tenta manter do jogador
@export var distancia_ideal: float = 200.0

# Distância em que começa a fugir
@export var distancia_fuga: float = 140.0

# Distância que recua quando o jogador chega perto
@export var distancia_recuo: float = 100.0


# ==================================================
# VIDA
# ==================================================

@export var vida_maxima: float = 30.0

var vida: float


# ==================================================
# JOGADOR
# ==================================================

var jogador: CharacterBody2D = null


# ==================================================
# ATAQUE
# ==================================================

@export var tempo_carregamento: float = 0.5
@export var tempo_cooldown: float = 1.5

# Distância máxima para atacar
@export var alcance_ataque: float = 300.0

# Dano causado pelo projétil
@export var dano: float = 10.0


# ==================================================
# PROJÉTIL
# ==================================================

# IMPORTANTE:
# No Inspector, coloque aqui a cena projetil.tscn
@export var projetil_cena: PackedScene


# ==================================================
# ESTADO
# ==================================================

var atacando: bool = false
var pode_atacar: bool = true


# ==================================================
# ÁREA VISUAL DO ATAQUE
# ==================================================

@onready var attack_area: Polygon2D = $AttackArea/Polygon2D


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	vida = vida_maxima

	# Coloca o inimigo no grupo
	add_to_group("inimigos")

	# Procura o jogador
	procurar_jogador()

	# Esconde a indicação do tiro
	attack_area.visible = false

	# Cria o retângulo visual
	criar_area_ataque()


# ==================================================
# FÍSICA
# ==================================================

func _physics_process(_delta: float) -> void:

	# --------------------------------------------------
	# Procurar jogador
	# --------------------------------------------------

	if jogador == null or not is_instance_valid(jogador):

		procurar_jogador()

		velocity = Vector2.ZERO

		move_and_slide()

		return


	# --------------------------------------------------
	# Enquanto estiver carregando o tiro
	# --------------------------------------------------

	if atacando:

		velocity = Vector2.ZERO

		move_and_slide()

		return


	# --------------------------------------------------
	# Calcula distância
	# --------------------------------------------------

	var distancia: float = global_position.distance_to(
		jogador.global_position
	)


	# ==================================================
	# JOGADOR MUITO PERTO
	# ==================================================

	if distancia <= distancia_fuga:

		afastar_do_jogador()

		return


	# ==================================================
	# JOGADOR DENTRO DO ALCANCE DE ATAQUE
	# ==================================================

	if distancia <= alcance_ataque:

		velocity = Vector2.ZERO

		move_and_slide()

		if pode_atacar:

			iniciar_ataque()

		return


	# ==================================================
	# JOGADOR ESTÁ LONGE
	# ==================================================

	perseguir_ate_distancia_ideal()


# ==================================================
# PROCURAR JOGADOR
# ==================================================

func procurar_jogador() -> void:

	var encontrado: Node = get_tree().get_first_node_in_group("jogador")

	if encontrado != null:

		jogador = encontrado as CharacterBody2D


# ==================================================
# PERSEGUIR ATÉ A DISTÂNCIA IDEAL
# ==================================================

func perseguir_ate_distancia_ideal() -> void:

	if jogador == null:

		return


	var distancia: float = global_position.distance_to(
		jogador.global_position
	)


	var direcao: Vector2 = global_position.direction_to(
		jogador.global_position
	)


	if distancia > distancia_ideal:

		velocity = direcao * velocidade

	else:

		velocity = Vector2.ZERO


	move_and_slide()


# ==================================================
# AFASTAR DO JOGADOR
# ==================================================

func afastar_do_jogador() -> void:

	if jogador == null:

		return


	# Direção que aponta para longe do jogador
	var direcao: Vector2 = jogador.global_position.direction_to(
		global_position
	)


	velocity = direcao * velocidade

	move_and_slide()


# ==================================================
# INICIAR ATAQUE
# ==================================================

func iniciar_ataque() -> void:

	if atacando:

		return


	if not pode_atacar:

		return


	if jogador == null:

		return


	# --------------------------------------------------
	# Inicia ataque
	# --------------------------------------------------

	atacando = true
	pode_atacar = false

	# Fica parado
	velocity = Vector2.ZERO

	# Aponta a indicação para o jogador
	apontar_para_jogador()

	# Mostra a linha vermelha
	attack_area.visible = true


	# --------------------------------------------------
	# CARREGAMENTO
	# --------------------------------------------------

	await get_tree().create_timer(
		tempo_carregamento
	).timeout


	# --------------------------------------------------
	# ATIRA
	# --------------------------------------------------

	if jogador != null and is_instance_valid(jogador):

		atirar()


	# --------------------------------------------------
	# Finaliza carregamento
	# --------------------------------------------------

	attack_area.visible = false

	atacando = false


	# --------------------------------------------------
	# COOLDOWN
	# --------------------------------------------------

	await get_tree().create_timer(
		tempo_cooldown
	).timeout


	pode_atacar = true


# ==================================================
# ATIRAR
# ==================================================

func atirar() -> void:

	# --------------------------------------------------
	# Verifica se a cena foi configurada
	# --------------------------------------------------

	if projetil_cena == null:

		print("ERRO: Cena do projétil não foi configurada!")

		return


	# --------------------------------------------------
	# Cria o projétil
	# --------------------------------------------------

	var projetil: Area2D = projetil_cena.instantiate() as Area2D

	if projetil == null:

		print("ERRO: projetil.tscn não é um Area2D!")

		return


	# --------------------------------------------------
	# Adiciona o projétil ao mundo
	# --------------------------------------------------

	get_parent().add_child(projetil)


	# --------------------------------------------------
	# Define a posição inicial
	# --------------------------------------------------

	projetil.global_position = global_position


	# --------------------------------------------------
	# Calcula a direção
	# --------------------------------------------------

	# ATENÇÃO:
	# Essa direção é calculada UMA VEZ.
	#
	# Depois disso o projétil NÃO acompanha o jogador.

	var direcao: Vector2 = global_position.direction_to(
		jogador.global_position
	)


	# --------------------------------------------------
	# Configura o projétil
	# --------------------------------------------------

	projetil.configurar(
		direcao,
		dano
	)


	print("Inimigo atirou!")


# ==================================================
# APONTAR PARA O JOGADOR
# ==================================================

func apontar_para_jogador() -> void:

	if jogador == null:

		return


	if not is_instance_valid(jogador):

		return


	var direcao: Vector2 = global_position.direction_to(
		jogador.global_position
	)


	attack_area.rotation = direcao.angle()


# ==================================================
# CRIAR ÁREA VISUAL DO ATAQUE
# ==================================================

func criar_area_ataque() -> void:

	var comprimento: float = alcance_ataque
	var largura: float = 8.0

	var metade_largura: float = largura / 2.0


	var pontos := PackedVector2Array([
		Vector2(0, -metade_largura),
		Vector2(comprimento, -metade_largura),
		Vector2(comprimento, metade_largura),
		Vector2(0, metade_largura)
	])


	attack_area.polygon = pontos

	# Vermelho com transparência
	attack_area.color = Color(
		1.0,
		0.0,
		0.0,
		0.8
	)


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


	print(
		"Atirador recebeu ",
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

	print("Inimigo atirador morreu!")

	queue_free()
