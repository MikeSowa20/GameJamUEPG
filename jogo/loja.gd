extends Control

const TEXTURA_PERSONAGEM_DIALOGO = preload("res://dialogo/personagem_texto.png")
const FALAS_INICIAIS: Array[String] = [
	"Então esta é a oficina... Aqui posso usar os tokens que encontro para instalar modificações.",
	"As peças são liberadas em sequência: primeiro o braço, depois a perna e, por fim, a cabeça.",
	"Quando estiver pronto, é só continuar. Melhor não desperdiçar nenhum token."
]

@onready var texto_tokens: Label = $Centro/Janela/Estrutura/Margem/Conteudo/TextoTokens
@onready var mensagem: Label = $Centro/Janela/Estrutura/Margem/Conteudo/Mensagem
@onready var card_braco: PanelContainer = $Centro/Janela/Estrutura/Margem/Conteudo/Cards/CardBraco
@onready var card_perna: PanelContainer = $Centro/Janela/Estrutura/Margem/Conteudo/Cards/CardPerna
@onready var card_cabeca: PanelContainer = $Centro/Janela/Estrutura/Margem/Conteudo/Cards/CardCabeca
@onready var botao_braco: Button = $Centro/Janela/Estrutura/Margem/Conteudo/Cards/CardBraco/Itens/Comprar
@onready var botao_perna: Button = $Centro/Janela/Estrutura/Margem/Conteudo/Cards/CardPerna/Itens/Comprar
@onready var botao_cabeca: Button = $Centro/Janela/Estrutura/Margem/Conteudo/Cards/CardCabeca/Itens/Comprar
@onready var estado_braco: Label = $Centro/Janela/Estrutura/Margem/Conteudo/Cards/CardBraco/Itens/Estado
@onready var estado_perna: Label = $Centro/Janela/Estrutura/Margem/Conteudo/Cards/CardPerna/Itens/Estado
@onready var estado_cabeca: Label = $Centro/Janela/Estrutura/Margem/Conteudo/Cards/CardCabeca/Itens/Estado
@onready var botao_continuar: Button = $Centro/Janela/Estrutura/Margem/Conteudo/Continuar

var dialogo_inicial: Control = null
var texto_dialogo: Label = null
var botao_proximo: Button = null
var indice_fala: int = 0
var som_abertura: AudioStreamPlayer = null
var som_passagem: AudioStreamPlayer = null
var som_texto: AudioStreamPlayer = null
var digitacao_atual: int = 0

func _ready() -> void:
	get_tree().paused = false
	botao_braco.pressed.connect(comprar.bind("braco", 30))
	botao_perna.pressed.connect(comprar.bind("perna", 90))
	botao_cabeca.pressed.connect(comprar.bind("cabeca", 150))
	botao_continuar.pressed.connect(comecar_run)
	atualizar_interface()
	if not DificuldadeGlobal.dialogo_inicial_loja_exibido:
		mostrar_dialogo_inicial()
	else:
		botao_continuar.grab_focus()

func mostrar_dialogo_inicial() -> void:
	DificuldadeGlobal.dialogo_inicial_loja_exibido = true
	indice_fala = 0
	criar_sons_dialogo()

	dialogo_inicial = Control.new()
	dialogo_inicial.name = "DialogoInicial"
	dialogo_inicial.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogo_inicial.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogo_inicial.z_index = 20
	add_child(dialogo_inicial)

	var escurecer := ColorRect.new()
	escurecer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	escurecer.color = Color(0.02, 0.02, 0.04, 0.78)
	escurecer.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogo_inicial.add_child(escurecer)

	var personagem := TextureRect.new()
	personagem.texture = TEXTURA_PERSONAGEM_DIALOGO
	personagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	personagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	personagem.anchor_left = 0.70
	personagem.anchor_top = 0.03
	personagem.anchor_right = 1.13
	personagem.anchor_bottom = 0.98
	personagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	personagem.z_index = 2
	dialogo_inicial.add_child(personagem)

	var balao := PanelContainer.new()
	balao.anchor_left = 0.035
	balao.anchor_top = 0.40
	balao.anchor_right = 0.76
	balao.anchor_bottom = 0.94
	balao.z_index = 1
	var estilo_balao := StyleBoxFlat.new()
	estilo_balao.bg_color = Color("ece9e2")
	estilo_balao.border_color = Color("8f2d24")
	estilo_balao.set_border_width_all(3)
	estilo_balao.corner_radius_top_left = 10
	estilo_balao.corner_radius_top_right = 10
	estilo_balao.corner_radius_bottom_left = 10
	estilo_balao.corner_radius_bottom_right = 10
	estilo_balao.shadow_color = Color(0, 0, 0, 0.45)
	estilo_balao.shadow_size = 5
	balao.add_theme_stylebox_override("panel", estilo_balao)
	dialogo_inicial.add_child(balao)

	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 15)
	margem.add_theme_constant_override("margin_top", 12)
	margem.add_theme_constant_override("margin_right", 12)
	margem.add_theme_constant_override("margin_bottom", 10)
	balao.add_child(margem)

	var conteudo := VBoxContainer.new()
	conteudo.add_theme_constant_override("separation", 4)
	margem.add_child(conteudo)

	var nome := Label.new()
	nome.text = "CLT"
	nome.add_theme_color_override("font_color", Color("8f2d24"))
	nome.add_theme_font_size_override("font_size", 15)
	conteudo.add_child(nome)

	texto_dialogo = Label.new()
	texto_dialogo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	texto_dialogo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto_dialogo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto_dialogo.add_theme_color_override("font_color", Color("181818"))
	texto_dialogo.add_theme_font_size_override("font_size", 11)
	conteudo.add_child(texto_dialogo)

	botao_proximo = Button.new()
	botao_proximo.custom_minimum_size = Vector2(88, 24)
	botao_proximo.size_flags_horizontal = Control.SIZE_SHRINK_END
	botao_proximo.text = "PRÓXIMO  >"
	botao_proximo.pressed.connect(avancar_dialogo)
	conteudo.add_child(botao_proximo)

	atualizar_fala_dialogo()
	botao_proximo.grab_focus()
	som_abertura.play()

func atualizar_fala_dialogo() -> void:
	texto_dialogo.text = FALAS_INICIAIS[indice_fala]
	botao_proximo.text = "ENTENDI" if indice_fala == FALAS_INICIAIS.size() - 1 else "PRÓXIMO  >"
	digitar_fala()

func digitar_fala() -> void:
	digitacao_atual += 1
	var esta_digitacao := digitacao_atual
	texto_dialogo.visible_characters = 0
	botao_proximo.disabled = true
	for indice: int in range(texto_dialogo.text.length()):
		if esta_digitacao != digitacao_atual or not is_instance_valid(texto_dialogo):
			return
		texto_dialogo.visible_characters = indice + 1
		var caractere := texto_dialogo.text.substr(indice, 1)
		if indice % 3 == 0 and caractere != " " and caractere != "\n":
			som_texto.pitch_scale = randf_range(0.94, 1.06)
			som_texto.play()
		await get_tree().create_timer(0.025).timeout
	if esta_digitacao == digitacao_atual and is_instance_valid(botao_proximo):
		botao_proximo.disabled = false
		botao_proximo.grab_focus()

func avancar_dialogo() -> void:
	som_passagem.play()
	indice_fala += 1
	if indice_fala < FALAS_INICIAIS.size():
		atualizar_fala_dialogo()
		return
	dialogo_inicial.queue_free()
	dialogo_inicial = null
	texto_dialogo = null
	botao_proximo = null
	botao_continuar.grab_focus()

func criar_sons_dialogo() -> void:
	som_abertura = AudioStreamPlayer.new()
	som_abertura.name = "SomAbertura"
	som_abertura.stream = criar_tom(360.0, 720.0, 0.18, 0.32)
	som_abertura.volume_db = -8.0
	add_child(som_abertura)

	som_passagem = AudioStreamPlayer.new()
	som_passagem.name = "SomPassagem"
	som_passagem.stream = criar_tom(620.0, 420.0, 0.09, 0.24)
	som_passagem.volume_db = -10.0
	add_child(som_passagem)

	som_texto = AudioStreamPlayer.new()
	som_texto.name = "SomTexto"
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

func comprar(tipo: String, preco: int) -> void:
	mensagem.text = "Modificação instalada." if DificuldadeGlobal.comprar_melhoria(tipo, preco) else "Tokens insuficientes."
	atualizar_interface()

func atualizar_interface() -> void:
	texto_tokens.text = "TOKENS DISPONÍVEIS: %d" % DificuldadeGlobal.tokens
	configurar_card(botao_braco, estado_braco, DificuldadeGlobal.braco_robotico_ativo, true, 30)
	configurar_card(botao_perna, estado_perna, DificuldadeGlobal.perna_robotica_ativa, DificuldadeGlobal.braco_robotico_ativo, 90)
	configurar_card(botao_cabeca, estado_cabeca, DificuldadeGlobal.cabeca_robotica_ativa, DificuldadeGlobal.perna_robotica_ativa, 150)
	card_braco.visible = true
	card_perna.visible = DificuldadeGlobal.braco_robotico_ativo or DificuldadeGlobal.perna_robotica_ativa
	card_cabeca.visible = DificuldadeGlobal.perna_robotica_ativa or DificuldadeGlobal.cabeca_robotica_ativa

func configurar_card(botao: Button, estado: Label, comprado: bool, liberado: bool, preco: int) -> void:
	botao.disabled = comprado or not liberado or DificuldadeGlobal.tokens < preco
	if comprado:
		estado.text = "✓ INSTALADO"
		botao.text = "COMPRADO"
	elif not liberado:
		estado.text = "BLOQUEADO"
		botao.text = "BLOQUEADO"
	elif DificuldadeGlobal.tokens < preco:
		estado.text = "SALDO INSUFICIENTE"
		botao.text = "COMPRAR"
	else:
		estado.text = "DISPONÍVEL"
		botao.text = "COMPRAR"

func comecar_run() -> void:
	botao_continuar.disabled = true
	DificuldadeGlobal.preparar_nova_run()
	var erro := get_tree().change_scene_to_file("res://rooms/sala1.tscn")
	if erro != OK:
		botao_continuar.disabled = false
		push_error("Não foi possível iniciar a run.")
