extends Area2D


# ==================================================
# CONFIGURAÇÕES
# ==================================================

@export var velocidade: float = 250.0
@export var tempo_vida: float = 5.0


# ==================================================
# VARIÁVEIS
# ==================================================

var direcao: Vector2 = Vector2.ZERO
var dano: float = 10.0


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	# Coloca o projétil no grupo
	add_to_group("projeteis")

	# Detecta quando entra em um CharacterBody2D
	body_entered.connect(_quando_entrou_em_corpo)

	# Depois de alguns segundos, destrói o projétil
	await get_tree().create_timer(
		tempo_vida
	).timeout


	# Evita erro caso já tenha sido destruído
	if is_instance_valid(self):

		queue_free()


# ==================================================
# CONFIGURAR PROJÉTIL
# ==================================================

func configurar(
	nova_direcao: Vector2,
	novo_dano: float
) -> void:

	# Guarda a direção do tiro
	direcao = nova_direcao.normalized()

	# Guarda o dano
	dano = novo_dano

	# Gira o projétil para a direção do movimento
	rotation = direcao.angle()


# ==================================================
# MOVIMENTO
# ==================================================

func _physics_process(delta: float) -> void:

	# Se ainda não recebeu uma direção,
	# não faz nada.
	if direcao == Vector2.ZERO:

		return


	# --------------------------------------------------
	# Movimento em linha reta
	# --------------------------------------------------
	#
	# IMPORTANTE:
	# A direção NÃO é recalculada.
	#
	# Portanto, se o jogador se mover depois do tiro,
	# o projétil continua seguindo a direção original.

	global_position += direcao * velocidade * delta


# ==================================================
# COLISÃO
# ==================================================

func _quando_entrou_em_corpo(
	corpo: Node2D
) -> void:

	# --------------------------------------------------
	# Verifica se acertou o jogador
	# --------------------------------------------------

	if corpo.is_in_group("jogador"):

		if corpo.has_method("receber_dano"):

			corpo.receber_dano(dano)

			print("Projétil acertou o jogador!")


		# Destrói o projétil
		queue_free()

		return


	# --------------------------------------------------
	# Se bateu em qualquer outro corpo
	# --------------------------------------------------

	queue_free()
