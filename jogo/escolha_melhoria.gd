extends ColorRect

@onready var subtitulo: Label = $Centro/Janela/Conteudo/Subtitulo
@onready var descricao_tokens: Label = $Centro/Janela/Conteudo/Cards/CardTokens/Itens/Descricao
@onready var botao_velocidade: Button = $Centro/Janela/Conteudo/Cards/CardVelocidade/Itens/Escolher
@onready var botao_vida: Button = $Centro/Janela/Conteudo/Cards/CardVida/Itens/Escolher
@onready var botao_tokens: Button = $Centro/Janela/Conteudo/Cards/CardTokens/Itens/Escolher

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	botao_velocidade.pressed.connect(escolher.bind("velocidade"))
	botao_vida.pressed.connect(escolher.bind("vida"))
	botao_tokens.pressed.connect(escolher.bind("tokens"))

func configurar(sala_atual: int) -> void:
	subtitulo.text = "SALA %d CONCLUÍDA" % maxi(sala_atual - 1, 1)
	descricao_tokens.text = "+%d tokens\n(10 × dificuldade)" % (10 * sala_atual)

func escolher(tipo: String) -> void:
	botao_velocidade.disabled = true
	botao_vida.disabled = true
	botao_tokens.disabled = true
	DificuldadeGlobal.selecionar_melhoria(tipo)
