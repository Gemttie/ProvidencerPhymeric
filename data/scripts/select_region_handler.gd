extends Node2D

@export var main_map_node : Node2D
@export var empty_hover_region_layer : TileMapLayer
@export var pop_up_origin_line : Line2D
@export var pop_up_origin_line_particle_gen : GPUParticles2D
@onready var select_region_wrapper_scene = preload("res://data/scenes/select_region_wrapper.tscn")

@onready var hover_info_popup_scene = preload("res://data/scenes/rm_biome_info_popup.tscn")
var hover_info_popup: Node2D
var hover_popup_offset: Vector2 = Vector2(0.0, -260.0)

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

var biome_names := BiomeID.keys()
var current_hovered_cluster_id : int = -1
var current_region_instance : Node2D = null
var biome_population_data := {}

func _ready():
	main_map_node.biome_hovered.connect(_on_biome_hovered)
	main_map_node.biome_unhovered.connect(_on_biome_unhovered)
	
	# Create popup instance
	hover_info_popup = hover_info_popup_scene.instantiate()
	hover_info_popup.visible = false
	hover_info_popup.z_index = 12
	add_child(hover_info_popup)
	
	# Initialize line
	pop_up_origin_line.clear_points()
	pop_up_origin_line.add_point(Vector2.ZERO)
	pop_up_origin_line.add_point(Vector2.ZERO)
	pop_up_origin_line.visible = false
	pop_up_origin_line_particle_gen.emitting = false
	

func _process(delta: float) -> void:
	if hover_info_popup.visible:
		var mouse_pos = get_global_mouse_position()
		var popup_pos = mouse_pos + hover_popup_offset
		
		hover_info_popup.global_position = popup_pos
		pop_up_origin_line_particle_gen.global_position = mouse_pos
		
		# Update origin line
		var smaller_popup_pos = mouse_pos + 0.45 * (popup_pos - mouse_pos)
		pop_up_origin_line.set_point_position(0, smaller_popup_pos)
		pop_up_origin_line.set_point_position(1, mouse_pos)
		pop_up_origin_line.visible = true
		pop_up_origin_line_particle_gen.emitting = true
	else:
		pop_up_origin_line.visible = false
		pop_up_origin_line_particle_gen.emitting = false
		
	if Input.is_action_just_pressed("ui_accept"):
		print("biome pop data :" + str(MapDataIntermediary.additional_map_data))

func _on_biome_hovered(cluster_id: int, biome_type: int, tiles_info: Array) -> void:
	# Ignore tiny regions
	if tiles_info.size() < 12:
		hover_info_popup.visible = false
		return
	
	var select_region_wrapper_instance = select_region_wrapper_scene.instantiate()
	main_map_node.add_child(select_region_wrapper_instance)
	select_region_wrapper_instance.z_index = 5
	select_region_wrapper_instance.set_wrapper_id(cluster_id)
	select_region_wrapper_instance.draw_tilemap_from_data(tiles_info)
	select_region_wrapper_instance.turn_region_state_to("MapRegionHovered")
	
	update_biome_popup(cluster_id)

func _on_biome_unhovered(cluster_id: int) -> void:
	hover_info_popup.hide_popup()


func update_biome_popup(cluster_id: int) -> void:
	# Search for cluster with matching id
	var cluster_info = null
	for cluster in MapDataIntermediary.clusters_data:
		if cluster["id"] == cluster_id:
			cluster_info = cluster
			break
	
	if cluster_info:
		var biome_type_aux = cluster_info["biome"]
		var cluster_size = cluster_info["size"]
		var tiles_count = cluster_info["tiles"].size()
		
		# Get biome name
		var biome_name = biome_names[biome_type_aux]
		
		# Get population data (you need to implement this based on your game)
		var population_data = get_population_for_cluster(cluster_id)
		
		# Show popup
		hover_info_popup.show_biome_info(biome_name, tiles_count, cluster_id, population_data)
		hover_info_popup.visible = true
	else:
		hover_info_popup.visible = false



func get_population_for_cluster(cluster_id: int) -> Array[String]:
	var existing_population = MapDataIntermediary.get_biome_population_data(str(cluster_id))
	#
	#if we already have saved population data, return it
	if not existing_population.is_empty():
		return existing_population as Array[String]
	
	#generate mock data based on biome type
	var cluster_info = null
	for cluster in MapDataIntermediary.clusters_data:
		if cluster["id"] == cluster_id:
			cluster_info = cluster
			break
	
	if cluster_info:
		var biome_type = int(cluster_info["biome"])
		
		#xil spawn weight pool for this biome
		var xil_pool_chance = {
			"eping" : 0,
			"gotau" : 0,
			"soth" : 0,
			"gerniche" : 0,
			"afebora" : 0,
			"nerbumo" : 0,
			"mangur" : 0,
			"steinflog" : 0,
		}
		
		match biome_type:
			BiomeID.BEACH:
				xil_pool_chance["afebora"] += 2
				xil_pool_chance["soth"] += 1
			
			BiomeID.PLAINS:
				xil_pool_chance["eping"] += 1
				xil_pool_chance["gerniche"] += 1
				xil_pool_chance["nerbumo"] += 1
				xil_pool_chance["steinflog"] += 1
			
			BiomeID.TEMPERATE_FOREST:
				xil_pool_chance["gotau"] += 1
				xil_pool_chance["eping"] += 3
				xil_pool_chance["gerniche"] += 1
			
			BiomeID.JUNGLE:
				xil_pool_chance["soth"] += 1
				xil_pool_chance["eping"] += 1
				xil_pool_chance["mangur"] += 3
			
			BiomeID.TAIGA:
				xil_pool_chance["eping"] += 1
				xil_pool_chance["steinflog"] += 1
				xil_pool_chance["gotau"] += 3
				xil_pool_chance["gerniche"] += 1
			
			BiomeID.MOUNTAIN:
				xil_pool_chance["steinflog"] += 3
				xil_pool_chance["gotau"] += 1
			
			BiomeID.DESERT:
				xil_pool_chance["soth"] += 3
			
			BiomeID.SWAMP:
				xil_pool_chance["afebora"] += 3
			
			BiomeID.RED_FOREST:
				xil_pool_chance["gotau"] += 1
				xil_pool_chance["soth"] += 1
				xil_pool_chance["eping"] += 2
				xil_pool_chance["gerniche"] += 1
				xil_pool_chance["steinflog"] += 1
			
			BiomeID.SNOW:
				xil_pool_chance["eping"] += 1
				xil_pool_chance["gotau"] += 3
				xil_pool_chance["gerniche"] += 1
			
			BiomeID.OCEAN:
				xil_pool_chance["afebora"] += 3
			
			BiomeID.LAKE:
				xil_pool_chance["afebora"] += 1
			
			_:
				# Default for any unhandled biome
				xil_pool_chance["eping"] += 2
		
		#generate weighted random population
		var weighted_population = generate_weighted_population(xil_pool_chance)
		var organized_population = group_same_portraits(weighted_population)
		#save population in peristent data file
		MapDataIntermediary.set_biome_population_data(str(cluster_id), organized_population)
		return organized_population
	return []


func generate_weighted_population(weights: Dictionary) -> Array[String]:
	var result: Array[String] = []
	
	# Create weighted array (simple approach)
	var weighted_array: Array[String] = []
	for species in weights:
		var weight = weights[species]
		for i in range(weight):
			weighted_array.append(species)
	
	# If no weights or empty array, return default
	if weighted_array.size() == 0:
		return ["eping"]
	
	# Determine population size (fixed or random)
	var population_size = randi_range(0, 6)
	
	# Generate random population
	for i in range(population_size):
		var random_index = randi() % weighted_array.size()
		result.append(weighted_array[random_index])
	
	# Optional: Shuffle for more natural distribution
	result.shuffle()
	
	return result


func group_same_portraits(population: Array[String]) -> Array[String]:
	# Count occurrences of each portrait type
	var portrait_counts = {}
	
	for portrait in population:
		portrait_counts[portrait] = portrait_counts.get(portrait, 0) + 1
	
	# Create a new array with portraits grouped together
	var grouped_result: Array[String] = []
	
	# Sort by count (most common first) for better visual grouping
	var sorted_portraits = portrait_counts.keys()
	sorted_portraits.sort_custom(func(a, b): return portrait_counts[b] < portrait_counts[a])
	
	# Add portraits to result, grouped by type
	for portrait_type in sorted_portraits:
		var count = portrait_counts[portrait_type]
		for i in range(count):
			grouped_result.append(portrait_type)
	
	return grouped_result
