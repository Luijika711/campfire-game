extends Node

var current_map: MapData = null
var tile_map: TileMap = null

# Predefined maps
var available_maps: Dictionary = {}

signal map_loaded(map_data: MapData)
signal map_unloaded()

func _ready():
	_create_default_maps()

func register_map(map_id: String, map_data: MapData) -> void:
	available_maps[map_id] = map_data
	print("Registered map: %s" % map_id)

func get_available_maps() -> Dictionary:
	return available_maps.duplicate()

func load_map(map_id: String, target_tile_map: TileMap) -> bool:
	if not available_maps.has(map_id):
		push_error("Map not found: %s" % map_id)
		return false

	# Unload current map if any
	if current_map != null:
		unload_map()

	current_map = available_maps[map_id]
	tile_map = target_tile_map

	# Set tileset if provided
	if current_map.tile_set != null:
		tile_map.tile_set = current_map.tile_set
	
	# Check if tiles already exist (placed in editor) - preserve them
	var existing_tiles = tile_map.get_used_cells(0)
	if existing_tiles.size() > 0:
		print("Editor tiles detected (%d tiles), preserving them and adding map tiles on top..." % existing_tiles.size())
	else:
		# No editor tiles, clear and use programmatic tiles
		tile_map.clear()
		print("Placing %d programmatic tiles..." % current_map.tiles.size())
		for tile_data in current_map.tiles:
			var x = tile_data.get("x", 0)
			var y = tile_data.get("y", 0)
			var layer = tile_data.get("layer", 0)
			var atlas_coords = tile_data.get("atlas_coords", Vector2i(0, 0))
			tile_map.set_cell(layer, Vector2i(x, y), 0, atlas_coords)

	# Force tilemap update and rebuild collision
	tile_map.force_update(0)

	# Make sure the tileset has proper collision setup
	if tile_map.tile_set:
		print("TileSet has %d sources" % tile_map.tile_set.get_source_count())
		var source = tile_map.tile_set.get_source(0)
		if source:
			print("Source type: %s" % source.get_class())
			if source is TileSetAtlasSource:
				for coord in [Vector2i(0, 0), Vector2i(1, 0)]:
					if source.has_tile(coord):
						var data = source.get_tile_data(coord, 0)
						if data:
							print("Tile %s collision polygons: %d" % [coord, data.get_collision_polygons_count(0)])
						else:
							print("Tile %s has no data!" % coord)
					else:
						print("Tile %s doesn't exist!" % coord)

	map_loaded.emit(current_map)
	print("Loaded map: %s" % map_id)
	return true

func unload_map() -> void:
	if tile_map != null:
		tile_map.clear()

	current_map = null
	tile_map = null
	map_unloaded.emit()

func get_current_map() -> MapData:
	return current_map

func get_spawn_point(player_index: int) -> Vector2:
	if current_map == null:
		return Vector2(100, 400)
	return current_map.get_spawn_point(player_index)

func _create_default_maps() -> void:
	# Create tileset with textures
	var tile_set = _create_tileset()

	# Map 1: Basic Platformer
	var map1 = MapData.new()
	map1.map_name = "Basic Platformer"
	map1.description = "A simple map with platforms and coins"
	map1.tile_set = tile_set
	var spawn_points1: Array[Vector2] = [Vector2(100, 400), Vector2(150, 400), Vector2(200, 400)]
	map1.spawn_points = spawn_points1
	var coin_positions1: Array[Vector2] = [
		Vector2(300, 400),
		Vector2(600, 300),
		Vector2(900, 200),
		Vector2(500, 550),
		Vector2(800, 550)
	]
	map1.coin_positions = coin_positions1
	map1.goal_position = Vector2(1050, 186)

	# Create platform tiles for map1
	# Ground
	for x in range(-10, 40):
		map1.tiles.append({"x": x, "y": 18, "layer": 0, "atlas_coords": Vector2i(0, 0)})

	# Platform 1
	for x in range(10, 15):
		map1.tiles.append({"x": x, "y": 12, "layer": 0, "atlas_coords": Vector2i(1, 0)})

	# Platform 2
	for x in range(22, 28):
		map1.tiles.append({"x": x, "y": 9, "layer": 0, "atlas_coords": Vector2i(1, 0)})

	# Platform 3 (angled/sloped)
	for x in range(35, 40):
		map1.tiles.append({"x": x, "y": 8, "layer": 0, "atlas_coords": Vector2i(1, 0)})

	register_map("basic", map1)

	# Map 2: Tower Climb
	var map2 = MapData.new()
	map2.map_name = "Tower Climb"
	map2.description = "Climb to the top!"
	map2.tile_set = tile_set
	var spawn_points2: Array[Vector2] = [Vector2(100, 500)]
	map2.spawn_points = spawn_points2
	var coin_positions2: Array[Vector2] = [
		Vector2(200, 450),
		Vector2(400, 350),
		Vector2(300, 250),
		Vector2(500, 150),
		Vector2(700, 100)
	]
	map2.coin_positions = coin_positions2
	map2.goal_position = Vector2(900, 50)
	map2.background_color = Color(0.2, 0.3, 0.5, 1)

	# Ground
	for x in range(-5, 15):
		map2.tiles.append({"x": x, "y": 20, "layer": 0, "atlas_coords": Vector2i(0, 0)})

	# Ascending platforms
	for i in range(8):
		var y = 18 - i * 2
		var x = 10 + i * 4
		for px in range(x, x + 3):
			map2.tiles.append({"x": px, "y": y, "layer": 0, "atlas_coords": Vector2i(1, 0)})

	# Top platform with goal
	for x in range(40, 50):
		map2.tiles.append({"x": x, "y": 2, "layer": 0, "atlas_coords": Vector2i(0, 0)})

	register_map("tower", map2)

	# Map 3: Sky Islands
	var map3 = MapData.new()
	map3.map_name = "Sky Islands"
	map3.description = "Jump between floating islands"
	map3.tile_set = tile_set
	var spawn_points3: Array[Vector2] = [Vector2(100, 300)]
	map3.spawn_points = spawn_points3
	var coin_positions3: Array[Vector2] = [
		Vector2(300, 250),
		Vector2(500, 200),
		Vector2(700, 250),
		Vector2(900, 150),
		Vector2(400, 400)
	]
	map3.coin_positions = coin_positions3
	map3.goal_position = Vector2(1000, 100)
	map3.background_color = Color(0.6, 0.8, 1, 1)

	# Starting island
	for x in range(2, 8):
		map3.tiles.append({"x": x, "y": 15, "layer": 0, "atlas_coords": Vector2i(0, 0)})

	# Island 2
	for x in range(12, 18):
		map3.tiles.append({"x": x, "y": 12, "layer": 0, "atlas_coords": Vector2i(0, 0)})

	# Island 3
	for x in range(22, 28):
		map3.tiles.append({"x": x, "y": 10, "layer": 0, "atlas_coords": Vector2i(0, 0)})

	# Island 4
	for x in range(32, 38):
		map3.tiles.append({"x": x, "y": 8, "layer": 0, "atlas_coords": Vector2i(0, 0)})

	# Final island
	for x in range(42, 50):
		map3.tiles.append({"x": x, "y": 6, "layer": 0, "atlas_coords": Vector2i(0, 0)})

	register_map("sky_islands", map3)

func _create_tileset() -> TileSet:
	var tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(32, 32)

	# Create atlas texture (2x1 grid of tiles)
	var atlas_image = Image.create(64, 32, false, Image.FORMAT_RGBA8)

	# Ground tile (0,0) - green with darker border
	var ground_color = Color(0.2, 0.5, 0.2, 1)
	var ground_border = Color(0.15, 0.4, 0.15, 1)
	for x in range(32):
		for y in range(32):
			if x == 0 or x == 31 or y == 0 or y == 31:
				atlas_image.set_pixel(x, y, ground_border)
			else:
				atlas_image.set_pixel(x, y, ground_color)

	# Platform tile (1,0) - brown wood style
	var platform_color = Color(0.4, 0.3, 0.2, 1)
	var platform_border = Color(0.3, 0.22, 0.15, 1)
	for x in range(32):
		for y in range(32):
			if x == 0 or x == 31 or y == 0 or y == 31:
				atlas_image.set_pixel(x + 32, y, platform_border)
			else:
				atlas_image.set_pixel(x + 32, y, platform_color)

	var atlas_texture = ImageTexture.create_from_image(atlas_image)

	# Add physics layer first
	tile_set.add_physics_layer(0)
	tile_set.set_physics_layer_collision_layer(0, 2)
	tile_set.set_physics_layer_collision_mask(0, 0)

	# Create atlas source
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = atlas_texture
	atlas_source.texture_region_size = Vector2i(32, 32)

	# Create tiles BEFORE adding to tileset
	for tile_coord in [Vector2i(0, 0), Vector2i(1, 0)]:
		if not atlas_source.has_tile(tile_coord):
			atlas_source.create_tile(tile_coord)

	# Add source to tileset
	tile_set.add_source(atlas_source)

	# Add collision to tiles
	for tile_coord in [Vector2i(0, 0), Vector2i(1, 0)]:
		var tile_data = atlas_source.get_tile_data(tile_coord, 0)
		if tile_data:
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-16, -16), Vector2(16, -16),
				Vector2(16, 16), Vector2(-16, 16)
			]))

	return tile_set
