extends Area2D

const FILE_BEGIN = "res://rooms/sala"
const ULTIMA_SALA: int = 4
var trocando_sala: bool = false
var bloqueada: bool = true

@onready var sprite: Sprite2D = $Sprite2D

var textura_bloqueada = preload("res://elevador-fechado.png")
var textura_aberta = preload("res://elevador-aberto.png")

func _ready() -> void:
	monitoring = false
	sprite.texture = textura_bloqueada
	sprite.modulate = Color(0.45, 0.5, 0.58, 0.8)
	await get_tree().process_frame
	atualizar_estado_porta()


func _process(_delta: float) -> void:
	if bloqueada:
		atualizar_estado_porta()


func atualizar_estado_porta() -> void:
	var restantes: int = 0
	for inimigo: Node in get_tree().get_nodes_in_group("inimigos"):
		if is_instance_valid(inimigo) and not bool(inimigo.get("morrendo")):
			restantes += 1

	if restantes <= 0:
		abrir_porta()


func abrir_porta() -> void:
	if not bloqueada:
		return
	bloqueada = false
	sprite.texture = textura_aberta
	sprite.modulate = Color.WHITE
	set_deferred("monitoring", true)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.35)
	tween.tween_property(sprite, "scale", sprite.scale * 1.18, 0.22)
	await tween.finished
	if is_instance_valid(sprite):
		sprite.scale /= 1.18


func _on_body_entered(body: Node2D) -> void:
	if trocando_sala or bloqueada:
		return

	if not body.is_in_group("Player") and not body.is_in_group("jogador"):
		return

	var cena_atual: String = get_tree().current_scene.scene_file_path
	var nome_sala: String = cena_atual.get_file().get_basename()
	var numero_atual: int = nome_sala.trim_prefix("sala").to_int()
	if numero_atual >= ULTIMA_SALA:
		trocando_sala = true
		set_deferred("monitoring", false)
		call_deferred("_finalizar_run")
		return
	var proxima_sala: String = FILE_BEGIN + str(numero_atual + 1) + ".tscn"

	if not ResourceLoader.exists(proxima_sala):
		push_error("A próxima sala não existe: " + proxima_sala)
		return

	trocando_sala = true
	set_deferred("monitoring", false)
	call_deferred("_trocar_para_proxima_sala", proxima_sala)


func _trocar_para_proxima_sala(caminho: String) -> void:
	var erro: Error = get_tree().change_scene_to_file(caminho)
	if erro != OK:
		trocando_sala = false
		monitoring = true
		push_error("Não foi possível abrir a sala: " + caminho)
	else:
		DificuldadeGlobal.call_deferred("mostrar_escolha_melhoria")


func _finalizar_run() -> void:
	get_tree().paused = false
	var erro: Error = get_tree().change_scene_to_file("res://loja.tscn")
	if erro != OK:
		trocando_sala = false
		monitoring = true
		push_error("Não foi possível voltar à loja após a sala final.")
