extends CharacterBody2D


# ============================================================
# MOVIMENTO
# ============================================================

@export var velocidade: float = 40.0

# Distância que o inimigo tenta manter do jogador
@export var distancia_ideal: float = 200.0

# Se o jogador chegar mais perto que isso, o inimigo foge
@export var distancia_fuga: float = 140.0

# Distância usada para o recuo
@export var distancia_recuo: float = 100.0


# ============================================================
# VIDA
# ============================================================

@export var vida_maxima: float = 30.0

var vida: float


# ============================================================
# JOGADOR
# ============================================================

var jogador: CharacterBody2D = null


# ============================================================
# ATAQUE
# ============================================================

@export var tempo_carregamento: float = 0.5
@export var tempo_cooldown: float = 1.5

# Distância máxima para poder atacar
@export var alcance_ataque: float = 300.0

@export var dano: float = 10.0


# ============================================================
# PROJÉTIL
# ============================================================

# Arraste o projetil.tscn para essa propriedade no Inspector
@export var projetil_cena: PackedScene


# ============================================================
# RECUO AO ATIRAR
# ============================================================

# Quantos pixels o inimigo recua ao disparar
@export var distancia_recuo_tiro: float = 18.0

# Duração do recuo
@export var duracao_recuo_tiro: float = 0.12


# ============================================================
# CHACOALHADA AO ATIRAR
# ============================================================

# Intensidade horizontal da chacoalhada
@export var intensidade_chacoalhada: float = 5.0

# Intensidade vertical da chacoalhada
@export var intensidade_chacoalhada_vertical: float = 2.0

# Quantidade de vezes que chacoalha
@export var quantidade_chacoalhadas: int = 4

# Velocidade da chacoalhada
@export var velocidade_chacoalhada: float = 0.04


# ============================================================
# ESTADO
# ============================================================

var atacando: bool = false
var pode_atacar: bool = true

var recuando_ao_atirar: bool = false
var chacoalhando: bool = false


# ============================================================
# ÁREA DE ATAQUE
# ============================================================

@onready var attack_area: Node2D = $AttackArea
@onready var attack_polygon: Polygon2D = $AttackArea/Polygon2D


# ============================================================
# SPRITE
# ============================================================

@onready var sprite: Sprite2D = $Sprite2D


# ============================================================
# ANIMAÇÃO DE MOVIMENTO
# ============================================================

@export var velocidade_pulo: float = 10.0
@export var altura_pulo: float = 3.0
@export var intensidade_balanco: float = 6.0
@export var movimento_lateral: float = 2.0

var tempo_movimento: float = 0.0

var sprite_posicao_original: Vector2
var sprite_rotacao_original: float


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	vida = vida_maxima

	# Coloca o inimigo no grupo dos inimigos
	add_to_group("inimigos")

	# Procura o jogador
	procurar_jogador()

	# Guarda posição original do sprite
	sprite_posicao_original = sprite.position

	# Guarda rotação original do sprite
	sprite_rotacao_original = sprite.rotation

	# Configura a área de ataque
	attack_polygon.visible = false

	attack_polygon.color.a = 0.2

	criar_area_ataque()


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:

	# ========================================================
	# CHACOALHADA
	# ========================================================

	# Se estiver chacoalhando, a função de chacoalhada
	# controla a posição do sprite.
	if chacoalhando:
		return


	# ========================================================
	# MOVIMENTO NORMAL
	# ========================================================

	# Enquanto estiver se movimentando,
	# o sprite faz pequenos pulos e balanços.

	if velocity.length() > 0.1 and not atacando:

		animar_movimento(delta)

	else:

		# Quando está parado, volta suavemente
		# para a posição original.

		sprite.position = sprite.position.lerp(
			sprite_posicao_original,
			delta * 12.0
		)

		sprite.rotation = lerp_angle(
			sprite.rotation,
			sprite_rotacao_original,
			delta * 12.0
		)


# ============================================================
# PHYSICS PROCESS
# ============================================================

func _physics_process(_delta: float) -> void:

	# ========================================================
	# PROCURAR JOGADOR
	# ========================================================

	if jogador == null or not is_instance_valid(jogador):

		attack_polygon.visible = false

		procurar_jogador()

		velocity = Vector2.ZERO

		return


	# ========================================================
	# VIRAR PARA O JOGADOR
	# ========================================================

	virar_para_jogador()


	# ========================================================
	# ESTÁ ATACANDO
	# ========================================================

	if atacando:

		# Durante o carregamento do tiro,
		# fica completamente parado.

		velocity = Vector2.ZERO

		# Atualiza a direção da área vermelha.

		apontar_para_jogador()

		return


	# ========================================================
	# ESTÁ RECUANDO APÓS O TIRO
	# ========================================================

	if recuando_ao_atirar:

		return


	# ========================================================
	# DISTÂNCIA ATÉ O JOGADOR
	# ========================================================

	var distancia: float = global_position.distance_to(
		jogador.global_position
	)


	# ========================================================
	# JOGADOR ESTÁ MUITO PERTO
	# ========================================================

	if distancia <= distancia_fuga:

		afastar_do_jogador()

		return


	# ========================================================
	# JOGADOR ESTÁ DENTRO DO ALCANCE DO ATAQUE
	# ========================================================

	if distancia <= alcance_ataque:

		velocity = Vector2.ZERO

		if pode_atacar:

			iniciar_ataque()

		return


	# ========================================================
	# JOGADOR ESTÁ LONGE
	# ========================================================

	perseguir_ate_distancia_ideal()


# ============================================================
# PROCURAR JOGADOR
# ============================================================

func procurar_jogador() -> void:

	var encontrado: Node = get_tree().get_first_node_in_group(
		"jogador"
	)

	if encontrado != null:

		jogador = encontrado as CharacterBody2D


# ============================================================
# PERSEGUIR JOGADOR
# ============================================================

func perseguir_ate_distancia_ideal() -> void:

	if jogador == null:
		return

	if not is_instance_valid(jogador):
		return


	var distancia: float = global_position.distance_to(
		jogador.global_position
	)

	var direcao: Vector2 = global_position.direction_to(
		jogador.global_position
	)


	# Se ainda está longe demais,
	# aproxima-se do jogador.

	if distancia > distancia_ideal:

		velocity = direcao * velocidade

	else:

		velocity = Vector2.ZERO


	move_and_slide()


# ============================================================
# AFASTAR DO JOGADOR
# ============================================================

func afastar_do_jogador() -> void:

	if jogador == null:
		return

	if not is_instance_valid(jogador):
		return


	# Direção que aponta do jogador para o inimigo

	var direcao: Vector2 = jogador.global_position.direction_to(
		global_position
	)


	velocity = direcao * velocidade

	move_and_slide()


# ============================================================
# VIRAR PARA O JOGADOR
# ============================================================

func virar_para_jogador() -> void:

	if jogador == null:
		return

	if not is_instance_valid(jogador):
		return


	var direcao: Vector2 = global_position.direction_to(
		jogador.global_position
	)


	if direcao == Vector2.ZERO:
		return


	# Faz o inimigo olhar para o jogador.
	#
	# O sprite original deve estar apontado para a direita.

	rotation = direcao.angle()


# ============================================================
# INICIAR ATAQUE
# ============================================================

func iniciar_ataque() -> void:

	if atacando:
		return

	if not pode_atacar:
		return

	if jogador == null:
		return

	if not is_instance_valid(jogador):
		return


	# ========================================================
	# COMEÇA O ATAQUE
	# ========================================================

	atacando = true

	pode_atacar = false

	velocity = Vector2.ZERO


	# Mostra a área vermelha

	attack_polygon.visible = true


	# Aponta para o jogador

	apontar_para_jogador()


	print("Atirador começou a carregar!")


	# ========================================================
	# ESPERA O CARREGAMENTO
	# ========================================================

	await get_tree().create_timer(
		tempo_carregamento
	).timeout


	# ========================================================
	# VERIFICA SE O JOGADOR AINDA EXISTE
	# ========================================================

	if jogador == null or not is_instance_valid(jogador):

		attack_polygon.visible = false

		atacando = false

		iniciar_cooldown()

		return


	# ========================================================
	# DISPARA
	# ========================================================

	atirar()


	# ========================================================
	# ESCONDE ÁREA VERMELHA
	# ========================================================

	attack_polygon.visible = false

	atacando = false


	print("Atirador disparou!")


	# ========================================================
	# EFEITO DE DISPARO
	# ========================================================

	efeito_disparo()


	# ========================================================
	# COOLDOWN
	# ========================================================

	iniciar_cooldown()


# ============================================================
# EFEITO DO DISPARO
# ============================================================

func efeito_disparo() -> void:

	if jogador == null:
		return

	if not is_instance_valid(jogador):
		return


	# Evita iniciar duas animações ao mesmo tempo

	if recuando_ao_atirar:
		return

	recuando_ao_atirar = true
	chacoalhando = true


	# ========================================================
	# DIREÇÃO DO TIRO
	# ========================================================

	var direcao: Vector2 = global_position.direction_to(
		jogador.global_position
	)


	if direcao == Vector2.ZERO:

		direcao = Vector2.RIGHT


	# ========================================================
	# DIREÇÃO DO RECUO
	# ========================================================

	# O inimigo vai para trás da direção do jogador.

	var direcao_recuo: Vector2 = -direcao


	# ========================================================
	# POSIÇÃO INICIAL
	# ========================================================

	var posicao_inicial: Vector2 = global_position

	var posicao_final: Vector2 = (
		posicao_inicial
		+ direcao_recuo * distancia_recuo_tiro
	)


	# ========================================================
	# RECUO DO INIMIGO
	# ========================================================

	var tween_recuo: Tween = create_tween()

	tween_recuo.set_trans(Tween.TRANS_QUAD)

	tween_recuo.set_ease(Tween.EASE_OUT)


	tween_recuo.tween_property(
		self,
		"global_position",
		posicao_final,
		duracao_recuo_tiro
	)


	# ========================================================
	# CHACOALHADA
	# ========================================================

	for i in range(quantidade_chacoalhadas):

		var lado: float

		if i % 2 == 0:
			lado = 1.0
		else:
			lado = -1.0


		var deslocamento: Vector2 = Vector2(
			intensidade_chacoalhada * lado,
			intensidade_chacoalhada_vertical * lado
		)


		var posicao_chacoalhada: Vector2 = (
			sprite_posicao_original
			+ deslocamento
		)


		var tween_sprite: Tween = create_tween()

		tween_sprite.set_trans(Tween.TRANS_SINE)

		tween_sprite.set_ease(Tween.EASE_IN_OUT)


		tween_sprite.tween_property(
			sprite,
			"position",
			posicao_chacoalhada,
			velocidade_chacoalhada
		)


		tween_sprite.tween_property(
			sprite,
			"position",
			sprite_posicao_original,
			velocidade_chacoalhada
		)


		await tween_sprite.finished


	# ========================================================
	# GARANTE POSIÇÃO ORIGINAL
	# ========================================================

	sprite.position = sprite_posicao_original


	# ========================================================
	# FINALIZA EFEITO
	# ========================================================

	chacoalhando = false
	recuando_ao_atirar = false


# ============================================================
# COOLDOWN
# ============================================================

func iniciar_cooldown() -> void:

	await get_tree().create_timer(
		tempo_cooldown
	).timeout


	if not is_instance_valid(self):
		return


	pode_atacar = true


	print("Atirador pode disparar novamente!")


# ============================================================
# ATIRAR
# ============================================================

func atirar() -> void:

	# Verifica se o projetil foi configurado

	if projetil_cena == null:

		print(
			"ERRO: projetil_cena não foi configurada!"
		)

		return


	# ========================================================
	# CRIA O PROJÉTIL
	# ========================================================

	var projetil: Area2D = (
		projetil_cena.instantiate()
		as Area2D
	)


	if projetil == null:

		print(
			"ERRO: projetil.tscn precisa ter Area2D como raiz!"
		)

		return


	# Coloca o projétil no mesmo nível do inimigo

	get_parent().add_child(projetil)


	# ========================================================
	# DIREÇÃO DO TIRO
	# ========================================================

	var direcao: Vector2 = global_position.direction_to(
		jogador.global_position
	)


	# ========================================================
	# POSIÇÃO INICIAL
	# ========================================================

	var distancia_inicial: float = 25.0


	projetil.global_position = (
		global_position
		+ direcao * distancia_inicial
	)


	# ========================================================
	# CONFIGURA O PROJÉTIL
	# ========================================================

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


	# ========================================================
	# DEBUG
	# ========================================================

	print("================================")
	print("PROJÉTIL DISPARADO!")
	print("Direção: ", direcao)
	print("Dano: ", dano)
	print("================================")


# ============================================================
# APONTAR ÁREA VERMELHA
# ============================================================

func apontar_para_jogador() -> void:

	if jogador == null:
		return

	if not is_instance_valid(jogador):
		return


	var direcao: Vector2 = global_position.direction_to(
		jogador.global_position
	)


	if direcao == Vector2.ZERO:
		return


	# Usa rotação global para evitar dupla rotação

	attack_area.global_rotation = direcao.angle()


	# Transparência da área

	attack_polygon.color.a = 0.2


# ============================================================
# CRIAR ÁREA DE ATAQUE
# ============================================================

func criar_area_ataque() -> void:

	var comprimento: float = alcance_ataque

	var largura: float = 8.0

	var metade_largura: float = largura / 2.0


	# Retângulo comprido apontando para a direita.

	var pontos: PackedVector2Array = PackedVector2Array([

		Vector2(
			0.0,
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
			0.0,
			metade_largura
		)
	])


	attack_polygon.polygon = pontos


	# Vermelho transparente

	attack_polygon.color = Color(
		1.0,
		0.0,
		0.0,
		0.2
	)


# ============================================================
# ANIMAÇÃO DE MOVIMENTO
# ============================================================

func animar_movimento(delta: float) -> void:

	tempo_movimento += delta * velocidade_pulo


	# ========================================================
	# PULO
	# ========================================================

	var pulo: float = abs(
		sin(tempo_movimento)
	)


	sprite.position.y = (
		sprite_posicao_original.y
		- pulo * altura_pulo
	)


	# ========================================================
	# BALANÇO
	# ========================================================

	var balanco: float = sin(
		tempo_movimento * 1.5
	)


	# Inclinação para os lados

	sprite.rotation = (
		sprite_rotacao_original
		+ deg_to_rad(
			balanco * intensidade_balanco
		)
	)


	# Movimento lateral

	sprite.position.x = (
		sprite_posicao_original.x
		+ balanco * movimento_lateral
	)


# ============================================================
# RECEBER DANO
# ============================================================

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


# ============================================================
# MORRER
# ============================================================

func morrer() -> void:

	print("Inimigo atirador morreu!")

	queue_free()
