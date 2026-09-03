class_name EfeitosVisuais
extends RefCounted


static func criar_onda(
	pai: Node,
	posicao_global: Vector2,
	cor: Color,
	raio: float = 32.0,
	duracao: float = 0.3
) -> void:
	if not is_instance_valid(pai):
		return
	var linha := Line2D.new()
	linha.z_index = 20
	linha.top_level = true
	linha.global_position = posicao_global
	linha.width = 4.0
	linha.default_color = cor
	linha.closed = true
	for indice: int in range(25):
		var angulo: float = TAU * indice / 24.0
		linha.add_point(Vector2.from_angle(angulo) * 8.0)
	pai.add_child(linha)
	var tween := linha.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(linha, "scale", Vector2.ONE * (raio / 8.0), duracao)
	tween.tween_property(linha, "width", 0.5, duracao)
	tween.tween_property(linha, "modulate:a", 0.0, duracao)
	tween.finished.connect(linha.queue_free)


static func criar_clarao(
	pai: Node,
	posicao_global: Vector2,
	cor: Color,
	tamanho: float = 16.0,
	duracao: float = 0.18
) -> void:
	if not is_instance_valid(pai):
		return
	var brilho := Polygon2D.new()
	brilho.z_index = 19
	brilho.top_level = true
	brilho.global_position = posicao_global
	brilho.color = cor
	var pontos := PackedVector2Array()
	for indice: int in range(16):
		var angulo: float = TAU * indice / 16.0
		var raio_ponto: float = tamanho if indice % 2 == 0 else tamanho * 0.45
		pontos.append(Vector2.from_angle(angulo) * raio_ponto)
	brilho.polygon = pontos
	brilho.scale = Vector2(0.25, 0.25)
	pai.add_child(brilho)
	var tween := brilho.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(brilho, "scale", Vector2.ONE, duracao)
	tween.tween_property(brilho, "modulate:a", 0.0, duracao)
	tween.finished.connect(brilho.queue_free)


static func criar_pos_imagem(
	sprite: AnimatedSprite2D,
	pai: Node,
	cor: Color = Color(0.35, 0.85, 1.0, 0.55),
	duracao: float = 0.22
) -> void:
	if not is_instance_valid(sprite) or not is_instance_valid(pai):
		return
	var fantasma := Sprite2D.new()
	fantasma.z_index = sprite.z_index - 1
	fantasma.texture = sprite.sprite_frames.get_frame_texture(
		sprite.animation,
		sprite.frame
	)
	fantasma.flip_h = sprite.flip_h
	fantasma.flip_v = sprite.flip_v
	fantasma.modulate = cor
	pai.add_child(fantasma)
	fantasma.global_transform = sprite.global_transform
	var tween := fantasma.create_tween()
	tween.set_parallel(true)
	tween.tween_property(fantasma, "modulate:a", 0.0, duracao)
	tween.tween_property(fantasma, "scale", fantasma.scale * 1.15, duracao)
	tween.finished.connect(fantasma.queue_free)
