class_name DialogoVisualNovel
extends CanvasLayer

## Sistema de dialogo reutilizavel. Cada fala precisa apenas de "ator" e "texto".
## Exemplo: iniciar([{ "ator": "personagem", "texto": "Ola!" }])

signal dialogo_iniciado
signal fala_exibida(indice: int, ator: StringName, texto: String)
signal dialogo_finalizado

const ATORES := {
	&"personagem": {
		"nome": "PERSONAGEM",
		"retrato": preload("res://dialogo/personagem_texto.png"),
		"lado": "esquerda",
	},
	&"chefe": {
		"nome": "CHEFE",
		"retrato": preload("res://dialogo/personagem_chefe.png"),
		"lado": "direita",
	},
}

@export_range(0.0, 0.1, 0.001) var velocidade_texto: float = 0.025
@export var fechar_ao_terminar: bool = true
@export var pausar_jogo: bool = true

@onready var fundo: ColorRect = $Fundo
@onready var retrato_esquerdo: TextureRect = $Retratos/RetratoEsquerdo
@onready var retrato_direito: TextureRect = $Retratos/RetratoDireito
@onready var caixa: Control = $CaixaDialogo
@onready var nome_ator: Label = $CaixaDialogo/Nome
@onready var texto_fala: RichTextLabel = $CaixaDialogo/Texto
@onready var indicador: Label = $CaixaDialogo/Indicador

var _falas: Array[Dictionary] = []
var _indice: int = -1
var _revelando: bool = false
var _tween_texto: Tween
var _jogo_ja_estava_pausado: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	caixa.gui_input.connect(_ao_receber_input_na_caixa)


func iniciar(falas: Array[Dictionary]) -> void:
	var falas_validas: Array[Dictionary] = []
	for fala: Dictionary in falas:
		if not fala.has("ator") or not fala.has("texto"):
			push_warning("Fala ignorada: use {\"ator\": \"personagem\", \"texto\": \"...\"}.")
			continue
		var ator := StringName(str(fala["ator"]).to_lower())
		if not ATORES.has(ator):
			push_warning("Ator desconhecido '%s'. Use 'personagem' ou 'chefe'." % ator)
			continue
		falas_validas.append({"ator": ator, "texto": str(fala["texto"])})

	if falas_validas.is_empty():
		push_warning("O dialogo nao possui falas validas.")
		return

	_falas = falas_validas
	_indice = -1
	_jogo_ja_estava_pausado = get_tree().paused
	if pausar_jogo:
		get_tree().paused = true
	show()
	dialogo_iniciado.emit()
	_avancar()


func avancar() -> void:
	if not visible:
		return
	if _revelando:
		_exibir_texto_completo()
	else:
		_avancar()


func encerrar() -> void:
	if _tween_texto and _tween_texto.is_valid():
		_tween_texto.kill()
	_revelando = false
	hide()
	if pausar_jogo:
		get_tree().paused = _jogo_ja_estava_pausado
	dialogo_finalizado.emit()
	if fechar_ao_terminar:
		queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		avancar()


func _ao_receber_input_na_caixa(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		caixa.accept_event()
		avancar()


func _avancar() -> void:
	_indice += 1
	if _indice >= _falas.size():
		encerrar()
		return
	_exibir_fala(_falas[_indice])


func _exibir_fala(fala: Dictionary) -> void:
	var ator: StringName = fala["ator"]
	var dados: Dictionary = ATORES[ator]
	nome_ator.text = str(dados["nome"])
	texto_fala.text = str(fala["texto"])
	texto_fala.visible_ratio = 0.0
	_configurar_retratos(ator)
	_revelando = true
	indicador.hide()

	if _tween_texto and _tween_texto.is_valid():
		_tween_texto.kill()
	var duracao := maxf(texto_fala.get_total_character_count() * velocidade_texto, 0.01)
	_tween_texto = create_tween()
	_tween_texto.tween_property(texto_fala, "visible_ratio", 1.0, duracao)
	_tween_texto.finished.connect(_ao_terminar_revelacao)
	fala_exibida.emit(_indice, ator, texto_fala.text)


func _configurar_retratos(ator_ativo: StringName) -> void:
	retrato_esquerdo.texture = ATORES[&"personagem"]["retrato"]
	retrato_direito.texture = ATORES[&"chefe"]["retrato"]
	var esquerda_ativa := ator_ativo == &"personagem"
	retrato_esquerdo.modulate = Color.WHITE if esquerda_ativa else Color(0.32, 0.32, 0.38, 0.72)
	retrato_direito.modulate = Color.WHITE if not esquerda_ativa else Color(0.32, 0.32, 0.38, 0.72)
	retrato_esquerdo.z_index = 1 if esquerda_ativa else 0
	retrato_direito.z_index = 1 if not esquerda_ativa else 0


func _exibir_texto_completo() -> void:
	if _tween_texto and _tween_texto.is_valid():
		_tween_texto.kill()
	texto_fala.visible_ratio = 1.0
	_ao_terminar_revelacao()


func _ao_terminar_revelacao() -> void:
	_revelando = false
	indicador.show()
