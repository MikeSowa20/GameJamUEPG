extends CharacterBody2D


# ==================================================
# CONFIGURAÇÕES
# ==================================================

@export var velocidade: float = 50.0
@export var vida_maxima: float = 30.0
@export var dano: float = 10.0
@export var distancia_ataque: float = 40.0


# ==================================================
# VARIÁVEIS
# ==================================================

var vida: float
var jogador: CharacterBody2D = null


# ==================================================
# REFERÊNCIAS
# ==================================================

@onready var barra_vida: ProgressBar = $CanvasLayer/BarraVidaInimigo


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	# ==================================================
	# VIDA
	# ==================================================

	# Inicializa a vida
	vida = vida_maxima


	# Configura a barra de vida
	barra_vida.max_value = vida_maxima
	barra_vida.value = vida


	# ==================================================
	# GRUPO
	# ==================================================

	# Adiciona ao grupo dos inimigos
	add_to_group("inimigos")


	# ==================================================
	# JOGADOR
	# ==================================================

	# Procura o jogador
	procurar_jogador()


# ==================================================
# FÍSICA
# ==================================================

func _physics_process(_delta: float) -> void:

	# --------------------------------------------------
	# VERIFICA JOGADOR
	# --------------------------------------------------

	if not is_instance_valid(jogador):

		procurar_jogador()

		velocity = Vector2.ZERO

		return


	# --------------------------------------------------
	# CALCULA DISTÂNCIA
	# --------------------------------------------------

	var distancia := global_position.distance_to(
		jogador.global_position
	)


	# --------------------------------------------------
	# PERSEGUE O JOGADOR
	# --------------------------------------------------

	if distancia > distancia_ataque:

		var direcao := global_position.direction_to(
			jogador.global_position
		)

		velocity = direcao * velocidade

		move_and_slide()

	else:

		# Chegou perto do jogador.
		#
		# NÃO causa dano.
		# Apenas para.

		velocity = Vector2.ZERO


# ==================================================
# PROCURAR JOGADOR
# ==================================================

func procurar_jogador() -> void:

	var encontrado := get_tree().get_first_node_in_group(
		"jogador"
	)


	if encontrado != null:

		jogador = encontrado as CharacterBody2D


# ==================================================
# RECEBER DANO
# ==================================================

func receber_dano(valor: float) -> void:

	# --------------------------------------------------
	# DIMINUI A VIDA
	# --------------------------------------------------

	vida -= valor


	# Impede que a vida fique abaixo de zero
	vida = clamp(
		vida,
		0.0,
		vida_maxima
	)


	# --------------------------------------------------
	# ATUALIZA BARRA DE VIDA
	# --------------------------------------------------

	barra_vida.value = vida


	# --------------------------------------------------
	# DEBUG
	# --------------------------------------------------

	print(
		"Inimigo recebeu dano: ",
		valor
	)

	print(
		"Vida do inimigo: ",
		vida,
		"/",
		vida_maxima
	)


	# --------------------------------------------------
	# MORTE
	# --------------------------------------------------

	if vida <= 0:

		morrer()


# ==================================================
# MORRER
# ==================================================

func morrer() -> void:

	print("Inimigo morreu!")


	# Remove o inimigo da cena
	queue_free()
