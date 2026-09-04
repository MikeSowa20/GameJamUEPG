extends Control

const TEXTURA_FUNCIONARIO = preload("res://dialogo/personagem_texto.png")
const TEXTURA_CHEFE = preload("res://dialogo/personagem_chefe.png")
const FALAS: Array[Dictionary] = [
	{"personagem": "CHEFE", "texto": "Ei, preciso que você faça outra função na empresa."},
	{"personagem": "CHEFE", "texto": "Estamos falindo por conta de uma concorrente que usa IAs para trabalhar. Preciso que você vá à sede deles e destrua tudo."},
	{"personagem": "FUNCIONÁRIO", "texto": "Mas, chefe, como eu posso fazer isso? São IAs e eu sou um humano sem a força necessária..."},
	{"personagem": "CHEFE", "texto": "Sei lá, se vira, dê um jeito. Se não, você tá na rua, imprestável."},
	{"personagem": "CHEFE", "texto": "Ah... deixa eu te dar uma dica..."},
	{"personagem": "CHEFE", "texto": "Substitua o que te faz fraco."},
	{"personagem": "CHEFE", "texto": "Talvez assim você melhore, seu fracassado."}
]

@export_range(0.5, 2.0, 0.05) var tamanho_moldura: float = 1.8
@export_range(-1.0, 1.0, 0.01) var posicao_moldura_x: float = -0.1

var retrato: TextureRect
var balao: PanelContainer
var nome_personagem: Label
var texto_dialogo: Label
var botao_proximo: Button
var aviso_chamada: Label
var som_chamada: AudioStreamPlayer
var som_passagem: AudioStreamPlayer
var som_texto: AudioStreamPlayer
var indice_fala := -1
var digitacao_atual := 0
var chamada_ativa := true

func _ready() -> void:
	criar_interface()
	criar_sons()
	balao.visible = false
	botao_proximo.text = "ATENDER"
	botao_proximo.grab_focus()
	tocar_chamada()

func criar_interface() -> void:
	var fundo := ColorRect.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color.BLACK
	add_child(fundo)

	aviso_chamada = Label.new()
	aviso_chamada.anchor_left = 0.1
	aviso_chamada.anchor_top = 0.25
	aviso_chamada.anchor_right = 0.9
	aviso_chamada.anchor_bottom = 0.48
	aviso_chamada.text = "TELEFONE TOCANDO..."
	aviso_chamada.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso_chamada.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aviso_chamada.add_theme_font_size_override("font_size", 21)
	aviso_chamada.add_theme_color_override("font_color", Color("dad4ff"))
	add_child(aviso_chamada)

	retrato = TextureRect.new()
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retrato.anchor_left = 0.54
	retrato.anchor_top = 0.02
	retrato.anchor_right = 1.08
	retrato.anchor_bottom = 1.0
	retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	retrato.z_index = 2
	retrato.visible = false
	add_child(retrato)

	balao = PanelContainer.new()
	balao.anchor_left = 0.035
	balao.anchor_top = 0.40
	balao.anchor_right = 0.76
	balao.anchor_bottom = 0.95
	balao.z_index = 1
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("ece9e2")
	estilo.border_color = Color("8f2d24")
	estilo.set_border_width_all(3)
	estilo.corner_radius_top_left = 10
	estilo.corner_radius_top_right = 10
	estilo.corner_radius_bottom_left = 10
	estilo.corner_radius_bottom_right = 10
	estilo.shadow_color = Color(0, 0, 0, 0.7)
	estilo.shadow_size = 6
	balao.add_theme_stylebox_override("panel", estilo)
	add_child(balao)

	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 15)
	margem.add_theme_constant_override("margin_top", 11)
	margem.add_theme_constant_override("margin_right", 12)
	margem.add_theme_constant_override("margin_bottom", 9)
	balao.add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 3)
	margem.add_child(coluna)

	nome_personagem = Label.new()
	nome_personagem.add_theme_font_size_override("font_size", 15)
	coluna.add_child(nome_personagem)

	texto_dialogo = Label.new()
	texto_dialogo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	texto_dialogo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto_dialogo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto_dialogo.add_theme_color_override("font_color", Color("181818"))
	texto_dialogo.add_theme_font_size_override("font_size", 11)
	coluna.add_child(texto_dialogo)

	botao_proximo = Button.new()
	botao_proximo.anchor_left = 0.5
	botao_proximo.anchor_top = 0.68
	botao_proximo.anchor_right = 0.5
	botao_proximo.anchor_bottom = 0.68
	botao_proximo.offset_left = -60.0
	botao_proximo.offset_top = -14.0
	botao_proximo.offset_right = 60.0
	botao_proximo.offset_bottom = 14.0
	botao_proximo.custom_minimum_size = Vector2(98, 26)
	botao_proximo.pressed.connect(avancar)
	add_child(botao_proximo)

func avancar() -> void:
	if chamada_ativa:
		chamada_ativa = false
		som_chamada.stop()
		aviso_chamada.visible = false
		balao.visible = true
		retrato.visible = true
		botao_proximo.reparent(balao.get_child(0).get_child(0))
		botao_proximo.size_flags_horizontal = Control.SIZE_SHRINK_END
		botao_proximo.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		som_passagem.play()
		indice_fala = 0
		mostrar_fala()
		return

	som_passagem.play()
	indice_fala += 1
	if indice_fala >= FALAS.size():
		botao_proximo.disabled = true
		var erro := get_tree().change_scene_to_file("res://loja.tscn")
		if erro != OK:
			botao_proximo.disabled = false
			push_error("Não foi possível abrir a loja.")
		return
	mostrar_fala()

func mostrar_fala() -> void:
	var fala: Dictionary = FALAS[indice_fala]
	var chefe: bool = fala["personagem"] == "CHEFE"
	nome_personagem.text = fala["personagem"]
	nome_personagem.add_theme_color_override("font_color", Color("176b9e") if chefe else Color("6a3f82"))
	# A arte do chefe ocupa menos espaço dentro do arquivo. A moldura dele recebe
	# um pequeno aumento para ficar visualmente próxima da moldura do CLT.
	var esquerda_base := 0.82 if chefe else 0.84
	var topo_base := -0.02 if chefe else 0.02
	var direita_base := 1.10 if chefe else 1.08
	var base_base := 1.04 if chefe else 1.0
	var centro := Vector2(
		(esquerda_base + direita_base) * 0.5 + posicao_moldura_x,
		(topo_base + base_base) * 0.5
	)
	var metade := Vector2(
		(direita_base - esquerda_base) * 0.5,
		(base_base - topo_base) * 0.5
	) * tamanho_moldura
	retrato.anchor_left = centro.x - metade.x
	retrato.anchor_top = centro.y - metade.y
	retrato.anchor_right = centro.x + metade.x
	retrato.anchor_bottom = centro.y + metade.y
	retrato.texture = TEXTURA_CHEFE if chefe else TEXTURA_FUNCIONARIO
	texto_dialogo.text = fala["texto"]
	botao_proximo.text = "IR PARA A LOJA" if indice_fala == FALAS.size() - 1 else "PRÓXIMO  >"
	digitar_fala()

func digitar_fala() -> void:
	digitacao_atual += 1
	var esta_digitacao := digitacao_atual
	texto_dialogo.visible_characters = 0
	botao_proximo.disabled = true
	for indice: int in range(texto_dialogo.text.length()):
		if esta_digitacao != digitacao_atual:
			return
		texto_dialogo.visible_characters = indice + 1
		var caractere := texto_dialogo.text.substr(indice, 1)
		if indice % 3 == 0 and caractere != " " and caractere != "\n":
			som_texto.pitch_scale = randf_range(0.93, 1.07)
			som_texto.play()
		await get_tree().create_timer(0.025).timeout
	if esta_digitacao == digitacao_atual:
		botao_proximo.disabled = false
		botao_proximo.grab_focus()

func tocar_chamada() -> void:
	while chamada_ativa:
		som_chamada.play()
		await get_tree().create_timer(0.85).timeout

func criar_sons() -> void:
	som_chamada = AudioStreamPlayer.new()
	som_chamada.stream = criar_tom(520.0, 680.0, 0.32, 0.3)
	som_chamada.volume_db = -9.0
	add_child(som_chamada)
	som_passagem = AudioStreamPlayer.new()
	som_passagem.stream = criar_tom(620.0, 420.0, 0.09, 0.24)
	som_passagem.volume_db = -10.0
	add_child(som_passagem)
	som_texto = AudioStreamPlayer.new()
	som_texto.stream = criar_tom(760.0, 690.0, 0.025, 0.11)
	som_texto.volume_db = -19.0
	add_child(som_texto)

func criar_tom(frequencia_inicial: float, frequencia_final: float, duracao: float, volume: float) -> AudioStreamWAV:
	const TAXA_AMOSTRAGEM := 22050
	var quantidade := int(TAXA_AMOSTRAGEM * duracao)
	var dados := PackedByteArray()
	dados.resize(quantidade * 2)
	var fase := 0.0
	for indice: int in range(quantidade):
		var progresso := float(indice) / float(maxi(quantidade - 1, 1))
		var frequencia := lerpf(frequencia_inicial, frequencia_final, progresso)
		fase += TAU * frequencia / TAXA_AMOSTRAGEM
		var envelope := sin(PI * progresso) * (1.0 - progresso * 0.35)
		var amostra := sin(fase) + sin(fase * 2.01) * 0.18
		var valor := clampi(int(amostra * envelope * volume * 32767.0), -32768, 32767)
		dados.encode_s16(indice * 2, valor)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = TAXA_AMOSTRAGEM
	audio.stereo = false
	audio.data = dados
	return audio
