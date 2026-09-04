extends Area2D

const EFEITOS = preload("res://efeitos_visuais.gd")


# ==================================================
# CONFIGURAÇÕES
# ==================================================

@export var velocidade: float = 250.0
@export var tempo_vida: float = 5.0


# ==================================================
# VARIÁVEIS
# ==================================================

var direcao: Vector2 = Vector2.ZERO
const DANO_AO_JOGADOR: int = 1

# Inimigo que criou o projétil
var dono: Node = null
var tempo_animacao := 0.0
@onready var brilho: Polygon2D = $Brilho


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	# Coloca o projétil no grupo
	add_to_group("projeteis")

	# Detecta colisões com corpos
	body_entered.connect(_quando_entrou_em_corpo)

	# Tempo máximo de vida
	await get_tree().create_timer(
		tempo_vida
	).timeout

	# Se ainda existir, destrói
	if is_instance_valid(self):
		queue_free()


# ==================================================
# CONFIGURAR PROJÉTIL
# ==================================================

func configurar(
	nova_direcao: Vector2,
	_novo_dano: float,
	novo_dono: Node = null
) -> void:

	# Guarda a direção
	direcao = nova_direcao.normalized()

	# Todo projétil inimigo remove exatamente um coração.

	# Guarda quem disparou
	dono = novo_dono

	# Gira o projétil para a direção
	rotation = direcao.angle()


# ==================================================
# MOVIMENTO
# ==================================================

func _physics_process(delta: float) -> void:
	tempo_animacao += delta
	brilho.scale = Vector2.ONE * (1.55 + sin(tempo_animacao * 18.0) * 0.22)

	# Ainda não recebeu uma direção
	if direcao == Vector2.ZERO:
		return

	# Move em linha reta
	global_position += direcao * velocidade * delta


# ==================================================
# COLISÃO
# ==================================================

func _quando_entrou_em_corpo(
	corpo: Node2D
) -> void:

	# ==================================================
	# IGNORAR O DONO
	# ==================================================

	if corpo == dono:
		return

	# Tiros da impressora atravessam outros inimigos. Sem isso, formações de
	# inimigos bloqueavam o disparo antes que ele alcançasse o jogador.
	if corpo.is_in_group("inimigos"):
		return

	# O piso isométrico possui formas de colisão usadas pelo mapa. Ele não deve
	# bloquear tiros; somente paredes/obstáculos continuam destruindo o projétil.
	if corpo is TileMapLayer and corpo.name == "chaolayer":
		return


	# ==================================================
	# JOGADOR
	# ==================================================

	if corpo.is_in_group("jogador"):

		print("================================")
		print("PROJÉTIL ATINGIU O JOGADOR!")
		print("Dano: ", DANO_AO_JOGADOR)
		print("================================")

		# Verifica se o jogador possui receber_dano()
		if corpo.has_method("receber_dano"):

			corpo.receber_dano(DANO_AO_JOGADOR)

		criar_impacto()
		# Destrói o projétil
		queue_free()

		return


	# ==================================================
	# OUTRO CORPO
	# ==================================================

	print(
		"Projétil colidiu com: ",
		corpo.name
	)

	criar_impacto()
	# Destrói ao bater em parede/obstáculo
	queue_free()


func criar_impacto() -> void:
	EFEITOS.criar_clarao(get_parent(), global_position, Color(0.65, 0.95, 1.0, 1.0), 15.0, 0.14)
	EFEITOS.criar_onda(get_parent(), global_position, Color(0.15, 0.75, 1.0, 0.9), 24.0, 0.22)
	EFEITOS.criar_faiscas(get_parent(), global_position, Color(0.4, 0.9, 1.0, 1.0), 8, 22.0, 0.2)
