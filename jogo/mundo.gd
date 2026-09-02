extends CharacterBody2D

@export var velocidade: float = 120.0

func _physics_process(_delta: float) -> void:
	# Pega o movimento direto da tela (W = Cima, S = Baixo, A = Esquerda, D = Direita)
	var direcao_input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direcao_input != Vector2.ZERO:
		# Usa a direção direta sem converter para o ângulo do mapa
		velocity = direcao_input * velocidade
	else:
		velocity = Vector2.ZERO

	move_and_slide()
