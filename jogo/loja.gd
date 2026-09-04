extends Control

const RETRO_GUI := "res://RetroWindowsGUI/"

var texto_moedas: Label
var mensagem: Label
var botao_braco: Button
var botao_perna: Button
var botao_cabeca: Button


func _ready() -> void:
	get_tree().paused = false
	criar_interface()
	atualizar_interface()


func criar_interface() -> void:
	var fundo := ColorRect.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color("000000")
	add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var janela := PanelContainer.new()
	janela.custom_minimum_size = Vector2(458, 258)
	janela.add_theme_stylebox_override("panel", criar_estilo_textura("Window_Base.png", 3))
	centro.add_child(janela)

	var estrutura := VBoxContainer.new()
	estrutura.add_theme_constant_override("separation", 0)
	janela.add_child(estrutura)

	var cabecalho := PanelContainer.new()
	cabecalho.custom_minimum_size = Vector2(0, 27)
	cabecalho.add_theme_stylebox_override("panel", criar_estilo_cabecalho())
	estrutura.add_child(cabecalho)

	var titulo := Label.new()
	titulo.text = "  OFICINA DE MODIFICAÇÕES"
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 16)
	titulo.add_theme_color_override("font_color", Color.WHITE)
	titulo.add_theme_color_override("font_shadow_color", Color("000000"))
	titulo.add_theme_constant_override("shadow_offset_x", 1)
	titulo.add_theme_constant_override("shadow_offset_y", 1)
	cabecalho.add_child(titulo)

	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 10)
	margem.add_theme_constant_override("margin_right", 10)
	margem.add_theme_constant_override("margin_top", 5)
	margem.add_theme_constant_override("margin_bottom", 7)
	estrutura.add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.custom_minimum_size = Vector2(430, 215)
	coluna.add_theme_constant_override("separation", 7)
	margem.add_child(coluna)

	texto_moedas = Label.new()
	texto_moedas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_moedas.add_theme_font_size_override("font_size", 16)
	texto_moedas.add_theme_color_override("font_color", Color("000080"))
	coluna.add_child(texto_moedas)

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 10)
	coluna.add_child(cards)

	botao_braco = criar_botao(cards, "BRAÇO\nMODIFICADO", "30 MOEDAS\n\nDisparo com o\nbotão direito", "braco", 30)
	botao_perna = criar_botao(cards, "PERNA\nMODIFICADA", "90 MOEDAS\n\nDash duplo e\n+1 coração", "perna", 90)
	botao_cabeca = criar_botao(cards, "CABEÇA\nMODIFICADA", "150 MOEDAS\n\n+2 corações\npermanentes", "cabeca", 150)

	mensagem = Label.new()
	mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mensagem.add_theme_color_override("font_color", Color("ff9f8f"))
	coluna.add_child(mensagem)

	var jogar := Button.new()
	jogar.custom_minimum_size = Vector2(240, 38)
	jogar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	jogar.text = "CONTINUAR"
	jogar.add_theme_font_size_override("font_size", 17)
	aplicar_estilo_botao(jogar)
	jogar.pressed.connect(comecar_run)
	coluna.add_child(jogar)


func criar_botao(pai: HBoxContainer, titulo: String, descricao: String, tipo: String, preco: int) -> Button:
	var botao := Button.new()
	botao.custom_minimum_size = Vector2(135, 135)
	botao.size_flags_vertical = Control.SIZE_EXPAND_FILL
	botao.text = titulo + "\n" + descricao
	botao.add_theme_font_size_override("font_size", 12)
	aplicar_estilo_botao(botao)
	botao.pressed.connect(comprar.bind(tipo, preco))
	pai.add_child(botao)
	return botao


func criar_estilo_textura(arquivo: String, margem: int) -> StyleBoxTexture:
	var estilo := StyleBoxTexture.new()
	estilo.texture = load(RETRO_GUI + arquivo)
	estilo.texture_margin_left = margem
	estilo.texture_margin_top = margem
	estilo.texture_margin_right = margem
	estilo.texture_margin_bottom = margem
	return estilo


func criar_estilo_cabecalho() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("000080")
	estilo.border_width_left = 2
	estilo.border_width_top = 2
	estilo.border_width_right = 2
	estilo.border_width_bottom = 2
	estilo.border_color = Color.WHITE
	return estilo


func aplicar_estilo_botao(botao: Button) -> void:
	botao.add_theme_stylebox_override("normal", criar_estilo_textura("Windows_Button.png", 4))
	botao.add_theme_stylebox_override("hover", criar_estilo_textura("Windows_Button_Focus.png", 4))
	botao.add_theme_stylebox_override("focus", criar_estilo_textura("Windows_Button_Focus_Outlined.png", 4))
	botao.add_theme_stylebox_override("pressed", criar_estilo_textura("Windows_Button_Pressed.png", 4))
	botao.add_theme_stylebox_override("disabled", criar_estilo_textura("Windows_Button_Inactive.png", 4))
	botao.add_theme_color_override("font_color", Color("101010"))
	botao.add_theme_color_override("font_hover_color", Color("000080"))
	botao.add_theme_color_override("font_pressed_color", Color("101010"))
	botao.add_theme_color_override("font_disabled_color", Color("777777"))


func comprar(tipo: String, preco: int) -> void:
	if DificuldadeGlobal.comprar_melhoria(tipo, preco):
		mensagem.text = "Modificação instalada!"
	else:
		mensagem.text = "Moedas insuficientes. Jogue outra run para acumular mais."
	atualizar_interface()


func atualizar_interface() -> void:
	texto_moedas.text = "MOEDAS: %d" % DificuldadeGlobal.moedas
	configurar_botao(botao_braco, DificuldadeGlobal.braco_robotico_ativo, true, 30)
	configurar_botao(botao_perna, DificuldadeGlobal.perna_robotica_ativa, DificuldadeGlobal.braco_robotico_ativo, 90)
	configurar_botao(botao_cabeca, DificuldadeGlobal.cabeca_robotica_ativa, DificuldadeGlobal.perna_robotica_ativa, 150)


func configurar_botao(botao: Button, comprado: bool, liberado: bool, preco: int) -> void:
	botao.visible = liberado or comprado
	botao.disabled = comprado or not liberado or DificuldadeGlobal.moedas < preco
	if comprado:
		botao.text = botao.text.get_slice("\n", 0) + "\n\n✓ INSTALADO"


func comecar_run() -> void:
	DificuldadeGlobal.preparar_nova_run()
	var erro := get_tree().change_scene_to_file("res://rooms/sala1.tscn")
	if erro != OK:
		push_error("Não foi possível iniciar a run.")
