extends Control

const CENA_DIALOGO := preload("res://dialogo/dialogo_visual_novel.tscn")

var dialogo: DialogoVisualNovel


func _ready() -> void:
	dialogo = CENA_DIALOGO.instantiate()
	dialogo.fechar_ao_terminar = false
	dialogo.pausar_jogo = false
	add_child(dialogo)
	dialogo.iniciar([
		{"ator": "personagem", "texto": "Chefe, os relatórios já estão prontos."},
		{"ator": "chefe", "texto": "Ótimo. Agora precisamos conversar sobre a próxima tarefa."},
		{"ator": "personagem", "texto": "Pode falar. Estou ouvindo."},
	])
