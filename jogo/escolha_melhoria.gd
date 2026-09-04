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
	var sala_concluida := maxi(sala_atual - 1, 1)
	subtitulo.text = "SALA %d CONCLUÍDA" % sala_concluida
	descricao_tokens.text = "+%d tokens\n(5 × sala %d)" % [5 * sala_concluida, sala_concluida]

func escolher(tipo: String) -> void:
	botao_velocidade.disabled = true
	botao_vida.disabled = true
	botao_tokens.disabled = true
	DificuldadeGlobal.selecionar_melhoria(tipo)
