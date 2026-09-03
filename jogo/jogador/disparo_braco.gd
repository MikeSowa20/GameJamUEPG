extends Area2D

const EFEITOS = preload("res://efeitos_visuais.gd")

@export var velocidade: float = 360.0
@export var dano: float = 10.0
@export var tempo_vida: float = 2.0

var direcao: Vector2 = Vector2.RIGHT
var dono: Node = null
var destruindo: bool = false


func _ready() -> void:
	body_entered.connect(_ao_atingir_corpo)
	await get_tree().create_timer(tempo_vida).timeout
	if is_instance_valid(self):
		queue_free()


func configurar(nova_direcao: Vector2, novo_dono: Node) -> void:
	direcao = nova_direcao.normalized()
	if direcao == Vector2.ZERO:
		direcao = Vector2.RIGHT
	dono = novo_dono
	rotation = direcao.angle()


func _physics_process(delta: float) -> void:
	global_position += direcao * velocidade * delta


func _ao_atingir_corpo(corpo: Node2D) -> void:
	if destruindo or corpo == dono:
		return
	if corpo.is_in_group("jogador") or corpo.is_in_group("Player"):
		return

	destruindo = true
	if corpo.is_in_group("inimigos") and corpo.has_method("receber_dano"):
		corpo.receber_dano(dano)
	efeitos_impacto()
	queue_free()


func efeitos_impacto() -> void:
	EFEITOS.criar_clarao(
		get_parent(),
		global_position,
		Color(0.3, 0.85, 1.0, 1.0),
		10.0,
		0.14
	)
	EFEITOS.criar_onda(
		get_parent(),
		global_position,
		Color(0.1, 0.65, 1.0, 0.85),
		18.0,
		0.18
	)
