extends Area2D

var valor: int = 1
var direcao_inicial: Vector2 = Vector2.ZERO
var tempo: float = 0.0
var coletada: bool = false


func _ready() -> void:
	body_entered.connect(_ao_jogador_entrar)
	queue_redraw()


func configurar(posicao_inicial: Vector2, novo_valor: int, direcao: Vector2) -> void:
	global_position = posicao_inicial
	valor = maxi(novo_valor, 1)
	direcao_inicial = direcao.normalized()
	var destino: Vector2 = position + direcao_inicial * 14.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", destino, 0.22)


func _process(delta: float) -> void:
	tempo += delta
	rotation = sin(tempo * 5.0) * 0.12


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color("9b5f00"))
	draw_circle(Vector2.ZERO, 4.8, Color("ffd166"))
	draw_circle(Vector2(-1.5, -1.5), 1.4, Color("fff2a8"))


func _ao_jogador_entrar(corpo: Node2D) -> void:
	if coletada:
		return
	if not corpo.is_in_group("Player") and not corpo.is_in_group("jogador"):
		return
	coletada = true
	DificuldadeGlobal.adicionar_moedas(valor)
	monitoring = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	await tween.finished
	queue_free()
