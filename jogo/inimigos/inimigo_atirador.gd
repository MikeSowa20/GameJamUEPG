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

# Tempo que fica carregando antes de atirar
@export var tempo_carregamento: float = 0.5

# Tempo de espera entre os tiros
@export var tempo_cooldown: float = 1.5

# Distância máxima para atacar
@export var alcance_ataque: float = 300.0

# Dano causado pelo projétil
@export var dano: float = 10.0


# ==================================================
# PROJÉTIL
# ==================================================

# Arraste projetil.tscn para esta propriedade
# no Inspector
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

	# Inicializa a vida
	vida = vida_maxima

	# Adiciona o inimigo ao grupo
	add_to_group("inimigos")

	# Procura o jogador
	procurar_jogador()

	# Esconde a mira inicialmente
	attack_area.visible = false
	attack_area.color.a = 0.2

	# Cria a linha vermelha
	criar_area_ataque()


# ==================================================
# FÍSICA
# ==================================================

func _physics_process(_delta: float) -> void:

	# ==================================================
	# PROCURAR JOGADOR
	# ==================================================

	if jogador == null or not is_instance_valid(jogador):
		attack_area.color.a = 0.2
		procurar_jogador()

		velocity = Vector2.ZERO

		return


	# ==================================================
	# ESTÁ CARREGANDO O ATAQUE
	# ==================================================

	if atacando:

		# Fica completamente parado
		velocity = Vector2.ZERO

		# IMPORTANTE:
		# Atualiza a direção da mira a cada frame.
		#
		# Assim a linha vermelha acompanha
		# o jogador enquanto ele se movimenta.
		apontar_para_jogador()

		return


	# ==================================================
	# DISTÂNCIA ATÉ O JOGADOR
	# ==================================================

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

		# Fica parado
		velocity = Vector2.ZERO

		# Inicia o ataque
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

	var encontrado: Node = get_tree().get_first_node_in_group(
		"jogador"
	)

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


	# Se estiver longe demais, aproxima
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

	# Impede múltiplos ataques simultâneos
	if atacando:

		return


	# Verifica cooldown
	if not pode_atacar:

		return


	# Verifica jogador
	if jogador == null:

		return


	if not is_instance_valid(jogador):

		return


	# ==================================================
	# COMEÇA A CARREGAR
	# ==================================================

	atacando = true

	pode_atacar = false

	# Para o inimigo
	velocity = Vector2.ZERO

	# Mostra a mira
	attack_area.visible = true

	# Aponta inicialmente para o jogador
	apontar_para_jogador()


	print("Atirador começou a carregar!")


	# ==================================================
	# TEMPO DE CARREGAMENTO
	# ==================================================

	await get_tree().create_timer(
		tempo_carregamento
	).timeout


	# ==================================================
	# VERIFICAR JOGADOR
	# ==================================================

	if jogador == null or not is_instance_valid(jogador):

		attack_area.visible = false

		atacando = false

		iniciar_cooldown()

		return


	# ==================================================
	# ATIRAR
	# ==================================================

	atirar()


	# ==================================================
	# FINALIZAR ATAQUE
	# ==================================================

	attack_area.visible = false

	atacando = false

	print("Atirador disparou!")


	# ==================================================
	# INICIAR COOLDOWN
	# ==================================================

	iniciar_cooldown()


# ==================================================
# COOLDOWN
# ==================================================

func iniciar_cooldown() -> void:

	await get_tree().create_timer(
		tempo_cooldown
	).timeout


	# Se o inimigo ainda existir
	if not is_instance_valid(self):

		return


	pode_atacar = true

	print("Atirador pode disparar novamente!")


# ==================================================
# ATIRAR
# ==================================================

func atirar() -> void:

	# ==================================================
	# VERIFICAR CENA DO PROJÉTIL
	# ==================================================

	if projetil_cena == null:

		print(
			"ERRO: projetil_cena não foi configurada!"
		)

		return


	# ==================================================
	# CRIAR PROJÉTIL
	# ==================================================

	var projetil: Area2D = (
		projetil_cena.instantiate()
		as Area2D
	)


	if projetil == null:

		print(
			"ERRO: projetil.tscn precisa ter Area2D como raiz!"
		)

		return


	# ==================================================
	# ADICIONAR AO MUNDO
	# ==================================================

	get_parent().add_child(projetil)


	# ==================================================
	# CALCULAR DIREÇÃO
	# ==================================================

	# A direção é calculada NO MOMENTO DO DISPARO.
	#
	# Portanto, se o jogador se movimentou durante
	# o carregamento, o tiro será direcionado para
	# a posição atual dele.

	var direcao: Vector2 = global_position.direction_to(
		jogador.global_position
	)


	# ==================================================
	# POSIÇÃO INICIAL
	# ==================================================

	# Faz o projétil nascer um pouco à frente
	# do inimigo.

	var distancia_inicial: float = 25.0

	projetil.global_position = (
		global_position
		+ direcao * distancia_inicial
	)


	# ==================================================
	# CONFIGURAR PROJÉTIL
	# ==================================================

	if projetil.has_method("configurar"):

		projetil.configurar(
			direcao,
			dano,
			self
		)

	else:

		print(
			"ERRO: projetil não possui a função configurar()!"
		)

		projetil.queue_free()

		return


	print("================================")
	print("PROJÉTIL DISPARADO!")
	print("Direção: ", direcao)
	print("Dano: ", dano)
	print("================================")


# ==================================================
# APONTAR PARA O JOGADOR
# ==================================================

func apontar_para_jogador() -> void:
	
	attack_area.color.a = 0.2
	
	if jogador == null:

		return


	if not is_instance_valid(jogador):

		return


	# Calcula a direção atual até o jogador
	var direcao: Vector2 = global_position.direction_to(
		jogador.global_position
	)


	# Rotaciona a linha vermelha
	attack_area.rotation = direcao.angle()


# ==================================================
# CRIAR ÁREA VISUAL DO ATAQUE
# ==================================================

func criar_area_ataque() -> void:

	# Comprimento da linha
	var comprimento: float = alcance_ataque

	# Espessura da linha
	var largura: float = 8.0

	var metade_largura: float = largura / 2.0


	# Cria um retângulo começando no inimigo
	var pontos := PackedVector2Array([

		Vector2(
			0,
			-metade_largura
		),

		Vector2(
			comprimento,
			-metade_largura
		),

		Vector2(
			comprimento,
			metade_largura
		),

		Vector2(
			0,
			metade_largura
		)
	])


	attack_area.polygon = pontos


	# Vermelho semi-transparente
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


	# ==================================================
	# MORTE
	# ==================================================

	if vida <= 0.0:

		morrer()


# ==================================================
# MORRER
# ==================================================

func morrer() -> void:

	print("Inimigo atirador morreu!")

	queue_free()
