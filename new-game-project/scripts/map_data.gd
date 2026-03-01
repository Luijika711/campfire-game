extends Resource
class_name MapData

@export var map_name: String = "Default Map"
@export var description: String = "A simple platforming map"
@export var tile_set: TileSet
@export var background_texture: Texture2D

@export var tiles: Array[Dictionary] = []
@export var spawn_points: Array[Vector2] = [Vector2(100, 400)]
@export var coin_positions: Array[Vector2] = []
@export var background_color: Color = Color(0.5, 0.7, 1, 1)

func get_spawn_point(index: int) -> Vector2:
	if spawn_points.is_empty():
		return Vector2(100, 400)
	return spawn_points[index % spawn_points.size()]
