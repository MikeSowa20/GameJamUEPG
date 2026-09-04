extends Control

@onready var botao_start: Button = $Centro/Conteudo/Margem/Itens/BotaoStart
var iniciando: bool = false


func _ready() -> void:
	get_tree().paused = false
	botao_start.grab_focus()
	botao_start.pressed.connect(iniciar_jogo)

	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(botao_start, "modulate", Color(1.0, 0.82, 0.35, 1.0), 0.65)
	tween.tween_property(botao_start, "modulate", Color.WHITE, 0.65)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		iniciar_jogo()


func iniciar_jogo() -> void:
	if iniciando:
		return
	iniciando = true
	botao_start.disabled = true
	DificuldadeGlobal.iniciar_nova_partida()
	var erro: Error = get_tree().change_scene_to_file("res://loja.tscn")
	if erro != OK:
		iniciando = false
		botao_start.disabled = false
		push_error("Não foi possível abrir a loja.")
