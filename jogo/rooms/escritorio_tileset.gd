@tool
extends Node2D

const ROOM_BUILDER: Texture2D = preload(
	"res://Modern_Interiors_Free_v2.2/Modern tiles_Free/Interiors_free/16x16/Room_Builder_free_16x16.png"
)
const INTERIORES: Texture2D = preload(
	"res://Modern_Interiors_Free_v2.2/Modern tiles_Free/Interiors_free/16x16/Interiors_free_16x16.png"
)

const TAMANHO_TILE: float = 32.0
const ORIGEM: Vector2 = Vector2(-160, 0)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Base escura sob os tiles para não deixar frestas transparentes.
	draw_rect(Rect2(ORIGEM, Vector2(480, 320)), Color("1a2230"))

	# Piso montado tile a tile com o Room Builder 16x16.
	for y: int in range(1, 10):
		for x: int in range(15):
			var origem_tile := Vector2(224, 128)
			if (x + y) % 5 == 0:
				origem_tile = Vector2(240, 128)
			draw_texture_rect_region(
				ROOM_BUILDER,
				Rect2(ORIGEM + Vector2(x, y) * TAMANHO_TILE, Vector2.ONE * TAMANHO_TILE),
				Rect2(origem_tile, Vector2(16, 16))
			)

	# Paredes e rodapés do mesmo pacote.
	for x: int in range(15):
		desenhar_tile_room(Vector2(x, 0), Vector2(0, 0))
		if x not in [7, 8]:
			desenhar_tile_room(Vector2(x, 9), Vector2(0, 48))
	for y: int in range(1, 9):
		desenhar_tile_room(Vector2(0, y), Vector2(16, 0))
		desenhar_tile_room(Vector2(14, y), Vector2(32, 0))

	# Quadros corporativos na parede superior.
	desenhar_objeto(Rect2(0, 272, 32, 16), Rect2(-105, 17, 64, 32))
	desenhar_objeto(Rect2(32, 272, 32, 16), Rect2(-15, 17, 64, 32))
	desenhar_objeto(Rect2(64, 272, 32, 16), Rect2(75, 17, 64, 32))
	desenhar_objeto(Rect2(96, 272, 32, 16), Rect2(165, 17, 64, 32))

	# Estações de trabalho extraídas do atlas Interiors_free.
	desenhar_objeto(Rect2(112, 448, 64, 32), Rect2(-145, 50, 96, 48))
	desenhar_objeto(Rect2(112, 480, 64, 32), Rect2(-145, 132, 96, 48))
	desenhar_objeto(Rect2(112, 448, 64, 32), Rect2(209, 50, 96, 48))
	desenhar_objeto(Rect2(112, 480, 64, 32), Rect2(209, 132, 96, 48))

	# Armários, plantas e pequenos objetos deixam a sala com aspecto de escritório.
	desenhar_objeto(Rect2(128, 672, 48, 32), Rect2(-142, 215, 72, 48))
	desenhar_objeto(Rect2(176, 672, 48, 32), Rect2(230, 215, 72, 48))
	desenhar_objeto(Rect2(192, 400, 48, 32), Rect2(56, 42, 72, 48))
	desenhar_objeto(Rect2(192, 768, 32, 32), Rect2(-42, 254, 48, 48))
	desenhar_objeto(Rect2(208, 768, 32, 32), Rect2(155, 250, 48, 48))


func desenhar_tile_room(celula: Vector2, origem_atlas: Vector2) -> void:
	draw_texture_rect_region(
		ROOM_BUILDER,
		Rect2(ORIGEM + celula * TAMANHO_TILE, Vector2.ONE * TAMANHO_TILE),
		Rect2(origem_atlas, Vector2(16, 16))
	)


func desenhar_objeto(origem_atlas: Rect2, destino: Rect2) -> void:
	draw_texture_rect_region(INTERIORES, destino, origem_atlas)
