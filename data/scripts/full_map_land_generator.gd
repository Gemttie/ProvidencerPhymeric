extends Node2D

@export_category("Esential Parameters")
@export var width: int = 500
@export var height: int = 500
@export var tilemap: TileMapLayer
@export var border_layer : TileMapLayer
@export var final_map_layer : TileMapLayer
@export var select_region_layer : TileMapLayer
@export var slice_map_layer : TileMapLayer
@export var camera : Camera2D

#noise parameters
@export_category("Noise Parameters")
@export var temp_period: float = 300.0
@export var temp_octaves: int = 5
@export var moist_period: float = 300.0
@export var moist_octaves: int = 5
@export var alt_period: float = 150.0
@export var alt_octaves: int = 5

@onready var rm_locked_biome_popup_scene = preload("res://data/scenes/rm_locked_biome_popup.tscn")

@onready var being_hovered_label: Label = $TopDown2DGenericCamera/fps_label/being_hovered_label

var cluster_by_tile: Dictionary = {} 
var cluster_info: Dictionary = {} 
var seen_clusters: Dictionary = {}

const MAP_DATA_PATH = "user://map_data.json"
const MAP_BORDERS_DATA_PATH = "user://map_borders_data.json"
const MAP_ADDITIONAL_DATA_PATH = "user://additional_map_data.json"

#tile atlas coords
var beach_ta: Vector2i = Vector2i(6,0)
var ocean_ta: Vector2i = Vector2i(0,0)
var plains_ta: Vector2i = Vector2i(1,0)
var temperate_forest_ta: Vector2i = Vector2i(2,0)
var jungle_ta: Vector2i = Vector2i(3,0)
var taiga_ta: Vector2i = Vector2i(4,0)
var mountains_ta: Vector2i = Vector2i(5,0)
var desert_ta: Vector2i = Vector2i(6,0)
var swamp_ta: Vector2i = Vector2i(7,0)
var red_forest_ta: Vector2i = Vector2i(8,0)
var snow_ta: Vector2i = Vector2i(9,0)
var lake_ta: Vector2i = Vector2i(0,0)
var border_ta: Vector2i = Vector2i(10,0)

var beach_darker_ta: Vector2i = Vector2i(6,1)
var ocean_darker_ta: Vector2i = Vector2i(0,1)
var plains_darker_ta: Vector2i = Vector2i(1,1)
var temperate_forest_darker_ta: Vector2i = Vector2i(2,1)
var jungle_darker_ta: Vector2i = Vector2i(3,1)
var taiga_darker_ta: Vector2i = Vector2i(4,1)
var mountains_darker_ta: Vector2i = Vector2i(5,1)
var desert_darker_ta: Vector2i = Vector2i(6,1)
var swamp_darker_ta: Vector2i = Vector2i(7,1)
var red_forest_darker_ta: Vector2i = Vector2i(8,1)
var snow_darker_ta: Vector2i = Vector2i(9,1)
var lake_darker_ta: Vector2i = Vector2i(0,1)
var border_darker_ta: Vector2i = Vector2i(10,1)

signal biome_hovered(cluster_id: int, biome_type: int, tiles_info: Array)
signal unhoverable_region_hovered(value : bool)
signal biome_unhovered(cluster_id: int)
signal biome_clicked(cluster_id: int)
signal biome_secondary_clicked(cluster_id: int)
var last_hovered_cluster_id: int = -1

enum BiomeID {
	OCEAN,
	BEACH,
	PLAINS,
	TEMPERATE_FOREST,
	JUNGLE,
	TAIGA,
	MOUNTAIN,
	DESERT,
	SWAMP,
	RED_FOREST,
	SNOW,
	LAKE
}

#map data
var temperature: Dictionary = {}
var moisture: Dictionary = {}
var altitude: Dictionary = {}
var biome_id: Dictionary = {}
var finished_first_pass_gen : bool = false

#noise generator
var open_noise := FastNoiseLite.new()

var num_of_being_hovered : int = 0
var num_of_being_selected : int = 0
var wrappers_alive : int = 0
var popups_alive : int = 0

func _ready() -> void:
	#set camera pos
	var center_tile := Vector2i(width / 2, height / 2)
	var local_pos := tilemap.map_to_local(center_tile)
	var global_pos := tilemap.to_global(local_pos)
	camera.global_position = global_pos
	
	if FileAccess.file_exists(MAP_DATA_PATH):
		MapDataIntermediary.using_saved_map_data = true
		generate_map_from_saved_file()
	else:
		MapDataIntermediary.using_saved_map_data = false
		generate_map_from_scratch()
		

func _process(delta: float) -> void:
	if not finished_first_pass_gen:
		return

	var mouse_pos = get_global_mouse_position()
	var tile = tilemap.local_to_map(tilemap.to_local(mouse_pos))

	if tile.x < 0 or tile.x >= width or tile.y < 0 or tile.y >= height:
		#reset last hovered cluster when leaving the map
		last_hovered_cluster_id = -1
		return

	handle_hover(tile)
	
	if Input.is_action_just_pressed("primary_selection"):
		var click_pos = get_global_mouse_position()
		handle_click(tile, click_pos)
	
	if Input.is_action_just_pressed("secondary_selection"):
		var click_pos = get_global_mouse_position()
		handle_secondary_click(tile, click_pos)
	
	var general_children = get_children()
	num_of_being_hovered = 0
	num_of_being_selected = 0
	wrappers_alive = 0
	popups_alive = 0
	for children in general_children:
		if children.is_in_group("region_wrapper"):
			wrappers_alive += 1
			if children.being_hovered == true:
				num_of_being_hovered += 1
			if children.being_selected == true:
				num_of_being_selected += 1
		if children.is_in_group("biome_info_popup"):
			popups_alive += 1
				
	being_hovered_label.text = "Being hovered: " + str(num_of_being_hovered) + "\nBeing selected: " + str(num_of_being_selected) +"\nWrappers alive: " + str(wrappers_alive) + "\n Popups alive : " + str(popups_alive) + "\nTravel tags: " + str(MapDataIntermediary.travel_tag_display_info)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_MOUSE_EXIT:
			# Mouse left the window
			handle_mouse_exit()
		NOTIFICATION_WM_MOUSE_ENTER:
			# Window lost focus (Alt+Tab, click outside window, etc.)
			handle_mouse_exit()

func handle_mouse_exit() -> void:
	# Unhover any currently hovered cluster
	if last_hovered_cluster_id != -1:
		emit_signal("biome_unhovered", last_hovered_cluster_id)
		last_hovered_cluster_id = -1


func generate_map_from_scratch() -> void:
	print("Generating a new map from scratch")
	randomize()
	#generate noise maps
	temperature = generate_map(temp_period, temp_octaves)
	moisture = generate_map(moist_period, moist_octaves)
	altitude = generate_map(alt_period, alt_octaves)
	
	#calculate biomes by id, without touching the tilemap yet
	compute_all_biomes()
	var clusters = detect_biome_clusters()
	build_cluster_lookup(clusters)
	paint_biomes()
	paint_borders()
	#put_labels_on_biomes(clusters)
	finished_first_pass_gen = true

	#gen map
	create_map_data_file()

func generate_map_from_saved_file() -> void:
	print("Generating map from the saved map file")
	MapDataIntermediary.copy_map_data_from_disk()
	
	var source_id = 0
	var cluster_data_aux = MapDataIntermediary.clusters_data
	
	biome_id.clear()
	
	for cluster in cluster_data_aux:
		var biome_type = int(cluster.get("biome", 2.0))  # Convert float to int, default to PLAINS (2)
		var tiles_array = cluster.get("tiles", [])
		
		for tile_coords in tiles_array:
			# Convert float coordinates to int
			var pos = Vector2i(int(tile_coords[0]), int(tile_coords[1]))
			biome_id[pos] = biome_type #store biome type
			# Draw based on biome type
			match biome_type:
				0: # OCEAN
					tilemap.set_cell(pos, source_id, ocean_ta)
				1: # BEACH
					tilemap.set_cell(pos, source_id, beach_ta)
				2: # PLAINS
					tilemap.set_cell(pos, source_id, plains_ta)
				3: # TEMPERATE_FOREST
					tilemap.set_cell(pos, source_id, temperate_forest_ta)
				4: # JUNGLE
					tilemap.set_cell(pos, source_id, jungle_ta)
				5: # TAIGA
					tilemap.set_cell(pos, source_id, taiga_ta)
				6: # MOUNTAIN
					tilemap.set_cell(pos, source_id, mountains_ta)
				7: # DESERT
					tilemap.set_cell(pos, source_id, desert_ta)
				8: # SWAMP
					tilemap.set_cell(pos, source_id, swamp_ta)
				9: # RED_FOREST
					tilemap.set_cell(pos, source_id, red_forest_ta)
				10: # SNOW
					tilemap.set_cell(pos, source_id, snow_ta)
				11: # LAKE
					tilemap.set_cell(pos, source_id, lake_ta)
	
	finished_first_pass_gen = true
	
	#draw borders
	load_and_draw_borders()
	
	var clusters = detect_biome_clusters()
	build_cluster_lookup(clusters)
	
func generate_map(period: float, octaves: int) -> Dictionary:
	open_noise.seed = randi()
	open_noise.frequency = 1.0 / period
	open_noise.fractal_octaves = octaves
	open_noise.fractal_type = FastNoiseLite.FRACTAL_FBM

	var grid := {}
	for x in range(width):
		for y in range(height):
			# usar floats para ruido; podrías desplazar con offsets si quieres variedad
			var n: float = open_noise.get_noise_2d(float(x), float(y))
			# n en -1..1; lo pasamos a 0..1 y opcionalmente lo reajustamos
			var mapped: float = (n + 1.0) * 0.5
			# Para altitud podemos escalar más (ejemplo): mapped * 1.4 - 0.2
			grid[Vector2i(x, y)] = mapped
	return grid

func compute_biome_id(pos: Vector2i) -> int: #choose from 0.4 to 0.8
	var alt : float = altitude[pos]
	var temp : float = temperature[pos]
	var moist : float = moisture[pos]

	if alt < 0.40:
		return BiomeID.OCEAN
	if alt < 0.45:
		return BiomeID.BEACH

	if alt > 0.70 and temp < 0.5:
		return BiomeID.SNOW
		
	if alt > 0.60:
		return BiomeID.MOUNTAIN
		
	if moist < 0.3 and temp > 0.55:
		return BiomeID.DESERT

	if temp < 0.35 and moist < 0.6 and alt > 0.5:
		return BiomeID.TAIGA

	if temp > 0.63 and moist > 0.5 and alt > 0.5 and alt < 0.65:
		return BiomeID.RED_FOREST

	if moist > 0.7 and alt > 0.5:
		return BiomeID.SWAMP

	if moist > 0.45:
		return BiomeID.TEMPERATE_FOREST

	return BiomeID.PLAINS

func compute_all_biomes() -> void:
	for x in range(width):
		for y in range(height):
			var pos = Vector2i(x, y)
			biome_id[pos] = compute_biome_id(pos)

func paint_biomes() -> void:
	var source_id = 0
	tilemap.clear()

	for x in range(width):
		for y in range(height):
			var pos = Vector2i(x, y)
			var b = biome_id.get(pos, BiomeID.PLAINS)
			match b:
				BiomeID.OCEAN:
					tilemap.set_cell(pos, source_id, ocean_ta)
				BiomeID.BEACH:
					tilemap.set_cell(pos, source_id, beach_ta)
				BiomeID.PLAINS:
					tilemap.set_cell(pos, source_id, plains_ta)
				BiomeID.TEMPERATE_FOREST:
					tilemap.set_cell(pos, source_id, temperate_forest_ta)
				BiomeID.JUNGLE:
					tilemap.set_cell(pos, source_id, jungle_ta)
				BiomeID.TAIGA:
					tilemap.set_cell(pos, source_id, taiga_ta)
				BiomeID.MOUNTAIN:
					tilemap.set_cell(pos, source_id, mountains_ta)
				BiomeID.DESERT:
					tilemap.set_cell(pos, source_id, desert_ta)
				BiomeID.SWAMP:
					tilemap.set_cell(pos, source_id, swamp_ta)
				BiomeID.RED_FOREST:
					tilemap.set_cell(pos, source_id, red_forest_ta)
				BiomeID.SNOW:
					tilemap.set_cell(pos, source_id, snow_ta)
				BiomeID.LAKE:
					tilemap.set_cell(pos, source_id, lake_ta)

func get_darker_tile_for_biome(b: int) -> Vector2i:
	match b:
		BiomeID.OCEAN:
			return ocean_ta #so we don't outline oceans
		BiomeID.BEACH:
			return beach_darker_ta
		BiomeID.PLAINS:
			return plains_darker_ta
		BiomeID.TEMPERATE_FOREST:
			return temperate_forest_darker_ta
		BiomeID.JUNGLE:
			return jungle_darker_ta
		BiomeID.TAIGA:
			return taiga_darker_ta
		BiomeID.MOUNTAIN:
			return mountains_darker_ta
		BiomeID.DESERT:
			return desert_darker_ta
		BiomeID.SWAMP:
			return swamp_darker_ta
		BiomeID.RED_FOREST:
			return red_forest_darker_ta
		BiomeID.SNOW:
			return snow_darker_ta
		BiomeID.LAKE:
			return ocean_ta
		_:
			return border_ta  # fallback

func paint_borders(threshold: int = 500) -> void:
	var source_id = 0
	border_layer.clear()

	var clusters = detect_biome_clusters()

	#filter cluster by size threshold
	var big_clusters := []
	for cluster in clusters:
		if cluster.size() >= threshold:
			big_clusters.append(cluster)


	#paint outer borders
	for cluster in big_clusters:
		var cluster_set := {}
		for pos in cluster:
			cluster_set[pos] = true

		for pos in cluster:
			var is_outer_border := false

			var neighbors = [
				pos + Vector2i(1, 0),
				pos + Vector2i(-1, 0),
				pos + Vector2i(0, 1),
				pos + Vector2i(0, -1)
			]

			for n in neighbors:
				if n.x < 0 or n.x >= width or n.y < 0 or n.y >= height:
					is_outer_border = true
					break

				if not cluster_set.has(n):
					is_outer_border = true
					break

			if is_outer_border:
				var b : int = biome_id.get(pos, BiomeID.PLAINS)
				var darker_ta := get_darker_tile_for_biome(b)
				border_layer.set_cell(pos, source_id, darker_ta)

func flood_biome(start: Vector2i, biome_type: int, visited: Dictionary) -> Array:
	var q: Array = [start]
	var cluster: Array = []
	while q.size() > 0:
		var pos: Vector2i = q.pop_front()
		if visited.has(pos):
			continue
		visited[pos] = true
		cluster.append(pos)

		var neighbors = [
			pos + Vector2i(1,0),
			pos + Vector2i(-1,0),
			pos + Vector2i(0,1),
			pos + Vector2i(0,-1)
		]
		for n in neighbors:
			if n.x < 0 or n.x >= width or n.y < 0 or n.y >= height:
				continue
			if biome_id.get(n, -1) == biome_type and not visited.has(n):
				q.append(n)
	return cluster

func detect_biome_clusters() -> Array:
	var clusters: Array = []
	var visited := {}
	for x in range(width):
		for y in range(height):
			var pos = Vector2i(x, y)
			if visited.has(pos):
				continue
			var b = biome_id.get(pos, -1)
			if b == -1:
				continue
			var cluster = flood_biome(pos, b, visited)
			clusters.append(cluster)
	return clusters

func put_labels_on_biomes(clusters, threshold: int = 12) -> void:
	for cluster in clusters:
		if cluster.size() < threshold:
			continue

		# --- compute average center (float, not tile) ---
		var sum: Vector2 = Vector2.ZERO
		for pos in cluster:
			sum += Vector2(pos)

		var avg_center: Vector2 = sum / float(cluster.size())

		# --- find closest tile INSIDE the cluster ---
		var best_tile: Vector2i = cluster[0]
		var best_dist: float = INF

		for pos in cluster:
			var d := avg_center.distance_squared_to(Vector2(pos))
			if d < best_dist:
				best_dist = d
				best_tile = pos

		# --- convert to world position ---
		var local_pos := tilemap.map_to_local(best_tile)
		var global_pos := tilemap.to_global(local_pos)

		# --- create label ---
		var label := Label.new()
		var b_type: int = biome_id[best_tile]

		label.text = "Biome: %s\nSize: %d\nCenter: (%d,%d)" % [
			BiomeID.keys()[b_type],
			cluster.size(),
			best_tile.x,
			best_tile.y
		]

		label.position = global_pos
		label.z_index = 9
		#label.z_as_relative = false

		var rm_locked_b_popup_instance = rm_locked_biome_popup_scene.instantiate()
		rm_locked_b_popup_instance.position = global_pos
		rm_locked_b_popup_instance.z_index = 9
		add_child(rm_locked_b_popup_instance)
		add_child(label)
		


func convert_small_oceans_to_lakes(clusters: Array, threshold: int = 2000) -> void:
	for cluster in clusters:
		var first_pos: Vector2i = cluster[0]
		var b_type: int = biome_id[first_pos]

		#only convert oceans
		if b_type != BiomeID.OCEAN:
			continue

		# Si el cluster de océano es pequeño → lago
		if cluster.size() < threshold:
			for pos in cluster:
				biome_id[pos] = BiomeID.LAKE

func second_gen_pass_rescan_map() -> void:
	if !finished_first_pass_gen:
		push_warning("Main generation code hasn't run yet, first pass generation incomplete")
		return
	
	print("Running second gen pass")
	
	#wipe data
	temperature.clear()
	moisture.clear()
	altitude.clear()
	biome_id.clear()
	cluster_by_tile.clear()
	cluster_info.clear()
	seen_clusters.clear()
	
	#delete all existing biome labels
	for child in get_children():
		if child is Label:
			child.queue_free()
	
	tilemap.clear()
	border_layer.clear()
	
	var source_id = 0
	for x in range(width):
		for y in range(height):
			var pos := Vector2i(x, y)
			var tile := final_map_layer.get_cell_atlas_coords(pos)
			if tile != Vector2i(-1, -1): # tile exists
				tilemap.set_cell(pos, source_id, tile)
				#rebuild biome_id from the actual visual tiles
				biome_id[pos] = biome_from_tile(tile)
	
	#this ensures temperature/moisture/altitude data matches what's displayed
	temperature = generate_map(temp_period, temp_octaves)
	moisture = generate_map(moist_period, moist_octaves)
	altitude = generate_map(alt_period, alt_octaves)
	
	var clusters = detect_biome_clusters()#detect clusters from the ACTUAL visual biomes
	build_cluster_lookup(clusters)
	convert_small_oceans_to_lakes(clusters, 7000)
	paint_borders() #repaint borders based on new clusters
	#put_labels_on_biomes(clusters) #put fresh biome labels
	
	#save cluster data into a file so its persistent data, if it doesn't exist yet

	if FileAccess.file_exists(MAP_DATA_PATH):
		var file = FileAccess.open(MAP_DATA_PATH, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			# Check if file has content (not just whitespace)
			if content.strip_edges().is_empty():
				print("Map data file exists and is empty - saving new data")
				save_clusters_data(clusters)
			else:
				print("Map data file already exists with content - skipping")
		else:
			print("Couldn't open existing file - saving new data")
			save_clusters_data(clusters)
	else:
		print("Creating new map data file")
		save_clusters_data(clusters)

		
	MapDataIntermediary.copy_map_data_from_disk()
	#print(MapDataIntermediary.clusters_data)
	
	fill_all_empty_tiles() #fill empty tiles
	save_map_border_data() #save all the data from the borders so it can be re-drawn later if needed
	
	#eliminate unescesary layers
	slice_map_layer.queue_free()
	final_map_layer.queue_free()

func biome_from_tile(ta: Vector2i) -> int:
	match ta:
		ocean_ta: return BiomeID.OCEAN
		beach_ta: return BiomeID.BEACH
		plains_ta: return BiomeID.PLAINS
		temperate_forest_ta: return BiomeID.TEMPERATE_FOREST
		jungle_ta: return BiomeID.JUNGLE
		taiga_ta: return BiomeID.TAIGA
		mountains_ta: return BiomeID.MOUNTAIN
		desert_ta: return BiomeID.DESERT
		swamp_ta: return BiomeID.SWAMP
		red_forest_ta: return BiomeID.RED_FOREST
		snow_ta: return BiomeID.SNOW
		lake_ta: return BiomeID.LAKE
		_: return BiomeID.PLAINS # fallback
		
func fill_empty_tiles_with_darker_adjacent() -> bool:
	var source_id = 0
	var empty_tiles_found := false

	var directions = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1),
		Vector2i(1, -1), Vector2i(-1, -1)
	]

	for x in range(width):
		for y in range(height):
			var pos = Vector2i(x, y)

			var cell = tilemap.get_cell_atlas_coords(pos)
			if cell != null and cell != Vector2i(-1, -1):
				continue  # not empty

			var candidates := []
			for dir in directions:
				var npos = pos + dir
				if npos.x < 0 or npos.x >= width or npos.y < 0 or npos.y >= height:
					continue

				var nt = tilemap.get_cell_atlas_coords(npos)
				if nt == null or nt == Vector2i(-1, -1):
					continue

				# skip plains donors (both normal and darker) to avoid plains spreading
				if nt == plains_ta or nt == plains_darker_ta:
					continue

				var btype = biome_from_tile(nt)
				candidates.append(btype)

			# if we have candidates, pick the most frequent biome among them
			if candidates.size() > 0:
				var freq := {}
				for b in candidates:
					freq[b] = freq.get(b, 0) + 1

				# find highest frequency key
				var best_biome := -1
				var best_count := -1
				for k in freq.keys():
					if freq[k] > best_count:
						best_count = freq[k]
						best_biome = k

				var darker = get_darker_tile_for_biome(best_biome)
				border_layer.set_cell(pos, source_id, darker)
				biome_id[pos] = best_biome
				empty_tiles_found = true

			else:
				#fallback only if no valid neighbor donors found
				#set plains darker to avoid leaving empties
				border_layer.set_cell(pos, source_id, plains_darker_ta)
				biome_id[pos] = BiomeID.PLAINS
				empty_tiles_found = false

	return empty_tiles_found

func fill_all_empty_tiles() -> void:
	#this is the last function that touches the borders tilemap
	var max_iterations = 30
	var iteration = 0
	
	while iteration < max_iterations:
		var empty_tiles_remaining = fill_empty_tiles_with_darker_adjacent()
		
		if not empty_tiles_remaining:
			print("All empty tiles filled after %d iterations" % (iteration + 1))
			break
			
		iteration += 1
	
	if iteration >= max_iterations:
		print("Reached maximum iterations (%d), some empty tiles may remain" % max_iterations)

func build_cluster_lookup(clusters: Array) -> void:
	var id := 0
	for cluster in clusters:
		var biome = biome_id[cluster[0]]
		var info = {
			"biome": biome,
			"size": cluster.size(),
			"tiles": cluster
		}
		cluster_info[id] = info

		for pos in cluster:
			cluster_by_tile[pos] = id
		
		id += 1

func handle_hover(tile: Vector2i):
	#handle mouse hover over tiles, emitting cluster data only when entering a new cluster
	if not biome_id.has(tile):
		# Mouse left the map or is on invalid tile
		if last_hovered_cluster_id != -1:
			# Unhover the currently hovered cluster
			emit_signal("biome_unhovered", last_hovered_cluster_id)
			last_hovered_cluster_id = -1
		return

	var cluster_id = cluster_by_tile.get(tile, -1)
	if cluster_id == -1:
		# Mouse is on a tile without a cluster
		if last_hovered_cluster_id != -1:
			emit_signal("biome_unhovered", last_hovered_cluster_id)
			last_hovered_cluster_id = -1
		return
	
	#only emit if we entered a new cluster
	if cluster_id != last_hovered_cluster_id:
		# First, unhover the previous cluster
		if last_hovered_cluster_id != -1:
			emit_signal("biome_unhovered", last_hovered_cluster_id)
		
		# Update to the new cluster
		last_hovered_cluster_id = cluster_id
		
		if cluster_info.has(cluster_id):
			var info = cluster_info[cluster_id]
			var cluster_tiles = info["tiles"]
			var biome_type = info["biome"]
			
			if biome_type == BiomeID.OCEAN or biome_type == BiomeID.LAKE:
				emit_signal("unhoverable_region_hovered", true)
				return
			
			#get all tile positions and their atlas coordinates
			var tiles_data = get_cluster_tiles_info(cluster_tiles)
			#emit the signal with comprehensive cluster data
			emit_signal("biome_hovered", cluster_id, biome_type, tiles_data)
		
func unhover_previous_cluster(cluster_id) -> void:
	# Find and unhover the previous cluster's wrapper
	for child in get_children():
		if child.is_in_group("region_wrapper"):
			if child.get_wrapper_id() == last_hovered_cluster_id:
				# delete wrapper when hunhovered
				emit_signal("biome_unhovered", cluster_id)
				return
			
			
func get_cluster_tiles_info(cluster: Array) -> Array:
	#returns array of tile data for the entire cluster
	var out: Array = []
	for pos in cluster:
		var atlas = tilemap.get_cell_atlas_coords(pos)
		if atlas != Vector2i(-1, -1):  #only include valid tiles
			out.append({
				"position": pos,
				"atlas_coords": atlas,
				"biome_id": biome_id[pos],
				"temperature": temperature.get(pos, 0.0),
				"moisture": moisture.get(pos, 0.0),
				"altitude": altitude.get(pos, 0.0)
			})
	return out
	

func handle_click(tile: Vector2i, click_pos : Vector2) -> void:
	if not biome_id.has(tile):
		return
		
	var cluster_id = cluster_by_tile.get(tile, -1)
	if cluster_id == -1:
		return
		
	if cluster_info.has(cluster_id):
		var info = cluster_info[cluster_id]
		var biome_type = info["biome"]
		
		# Skip ocean and lake clicks if desired (optional)
		if biome_type == BiomeID.OCEAN or biome_type == BiomeID.LAKE:
			return
		
		# Emit the simple click signal with just the cluster ID
		emit_signal("biome_clicked", cluster_id)
		

func handle_secondary_click(tile: Vector2i, click_pos : Vector2) -> void:
	if not biome_id.has(tile):
		return
		
	var cluster_id = cluster_by_tile.get(tile, -1)
	if cluster_id == -1:
		return
		
	if cluster_info.has(cluster_id):
		var info = cluster_info[cluster_id]
		var biome_type = info["biome"]
		
		#skip ocean and lake clicks
		if biome_type == BiomeID.OCEAN or biome_type == BiomeID.LAKE:
			return
			
		MapDataIntermediary.add_travel_tag_display_info(cluster_id)
		emit_signal("biome_secondary_clicked", cluster_id)



func create_map_data_file() -> void:
	#gen map data file if it doesn't exist yet
	if FileAccess.file_exists(MAP_DATA_PATH): return
	
	var file = FileAccess.open(MAP_DATA_PATH, FileAccess.WRITE)
	file.store_var({})
	file.close()
	
func debug_print_map_data() -> void:
	if !FileAccess.file_exists(MAP_DATA_PATH): return
	var file = FileAccess.open(MAP_DATA_PATH, FileAccess.READ)
	var data =file.get_var()
	file.close()
	#print(data)

func save_clusters_data(clusters: Array) -> void:
	var save_data := {
		"version": "1.0",
		"width": width,
		"height": height,
		"clusters": []
	}

	var cluster_id := 0
	var lp_pool := []

	for cluster in clusters:
		if cluster.is_empty():
			continue

		var biome : int = biome_id[cluster[0]]
		var anchor := compute_cluster_anchor(cluster)

		var tiles := []
		for pos in cluster:
			tiles.append([pos.x, pos.y])

		save_data["clusters"].append({
			"id": cluster_id,
			"biome": biome,
			"size": cluster.size(),
			"anchor": [anchor.x, anchor.y],
			"tiles": tiles,
			"local_population_pool": lp_pool
		})

		cluster_id += 1

	var file := FileAccess.open(MAP_DATA_PATH, FileAccess.WRITE)
	if not file:
		push_error("Failed to save cluster data")
		return

	file.store_string(JSON.stringify(save_data))
	file.close()

	print("Saved %d clusters with full metadata" % cluster_id)

func compute_cluster_anchor(cluster: Array) -> Vector2i:
	var sum := Vector2.ZERO
	for pos in cluster:
		sum += Vector2(pos)
	var avg := sum / cluster.size()

	var best_tile: Vector2i = cluster[0]
	var best_dist := INF

	for pos in cluster:
		var d := avg.distance_squared_to(Vector2(pos))
		if d < best_dist:
			best_dist = d
			best_tile = pos

	return best_tile


func save_map_border_data() -> void:
	var save_data := {
		"version": "1.0",
		"width": width,
		"height": height,
		"border_tiles": []
	}

	var used_cells = border_layer.get_used_cells()
	
	for cell_pos in used_cells:
		var atlas_coords = border_layer.get_cell_atlas_coords(cell_pos)
		
		if atlas_coords != Vector2i(-1, -1):
			save_data["border_tiles"].append({
				"position": [cell_pos.x, cell_pos.y],
				"atlas_coords": [atlas_coords.x, atlas_coords.y]
			})

	var file := FileAccess.open(MAP_BORDERS_DATA_PATH, FileAccess.WRITE)
	if not file:
		push_error("Failed to save border data")
		return

	file.store_string(JSON.stringify(save_data))
	file.close()

	print("Saved %d border tiles" % save_data["border_tiles"].size())
	

func load_border_data_from_file() -> Dictionary:
	if not FileAccess.file_exists(MAP_BORDERS_DATA_PATH):
		push_warning("Border data file doesn't exist")
		return {}
	
	var file = FileAccess.open(MAP_BORDERS_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open border data file")
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("Failed to parse border data JSON")
		return {}
	
	var save_data = json.get_data() as Dictionary
	return save_data

func draw_border_tiles_nogen(border_data: Dictionary) -> void:
	var source_id = 0
	
	# Clear existing border tiles
	border_layer.clear()
	
	# Draw each border tile from the data
	for tile_data in border_data.get("border_tiles", []):
		var pos = Vector2i(tile_data["position"][0], tile_data["position"][1])
		var atlas_coords = Vector2i(tile_data["atlas_coords"][0], tile_data["atlas_coords"][1])
		
		border_layer.set_cell(pos, source_id, atlas_coords)
	
	
# Load and draw borders in one go
func load_and_draw_borders() -> void:
	var border_data = load_border_data_from_file()
	if border_data.size() > 0:
		draw_border_tiles_nogen(border_data)


func get_width() -> int: return width
func get_height() -> int: return height
func get_main_tilemap() -> TileMapLayer: return tilemap
