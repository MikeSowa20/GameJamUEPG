extends SceneTree

const CENA_DIALOGO := preload("res://dialogo/dialogo_visual_novel.tscn")


func _initialize() -> void:
	call_deferred("_executar")


func _executar() -> void:
	var dialogo: DialogoVisualNovel = CENA_DIALOGO.instantiate()
	dialogo.fechar_ao_terminar = false
	dialogo.pausar_jogo = false
	root.add_child(dialogo)
	await process_frame

	dialogo.iniciar([
		{"ator": "personagem", "texto": "Primeira fala"},
		{"ator": "chefe", "texto": "Segunda fala"},
	])
	if not dialogo.visible or dialogo.nome_ator.text != "PERSONAGEM" or dialogo.texto_fala.text != "Primeira fala":
		_falhar("A primeira fala nao foi exibida corretamente.")
		return

	dialogo.avancar()
	dialogo.avancar()
	if dialogo.nome_ator.text != "CHEFE" or dialogo.texto_fala.text != "Segunda fala":
		_falhar("A troca para o chefe nao funcionou.")
		return

	dialogo.avancar()
	dialogo.avancar()
	if dialogo.visible:
		_falhar("O dialogo nao encerrou depois da ultima fala.")
		return

	print("TESTE_DIALOGO_OK: instancia, atores, textos, avancos e encerramento validados.")
	quit(0)


func _falhar(mensagem: String) -> void:
	push_error("TESTE_DIALOGO_FALHOU: " + mensagem)
	quit(1)
