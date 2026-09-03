extends Area2D

const FILE_BEGIN = "res://rooms/sala"
var trocando_sala: bool = false


func _on_body_entered(body: Node2D) -> void:
	if trocando_sala:
		return

	if not body.is_in_group("Player") and not body.is_in_group("jogador"):
		return

	var cena_atual: String = get_tree().current_scene.scene_file_path
	var nome_sala: String = cena_atual.get_file().get_basename()
	var numero_atual: int = nome_sala.trim_prefix("sala").to_int()
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
