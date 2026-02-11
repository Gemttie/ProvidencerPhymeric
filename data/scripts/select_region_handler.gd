extends Node2D

@export var main_map_node : Node2D
@export var empty_hover_region_layer : TileMapLayer
@onready var select_region_wrapper_scene = preload("res://data/scenes/select_region_wrapper.tscn")
@onready var hover_info_popup_scene = preload("res://data/scenes/rm_biome_info_popup.tscn")
@onready var biome_map_num_displayer_scene = preload("res://data/scenes/biome_map_number_displayer.tscn")

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
	main_map_node.biome_clicked.connect(_on_biome_clicked)
	main_map_node.biome_secondary_clicked.connect(_on_biome_secondary_clicked)


func _on_biome_hovered(cluster_id: int, biome_type: int, tiles_info: Array) -> void:
	# Ignore tiny regions
	if tiles_info.size() < 12:
		#hover_info_popup.visible = false
		return
	
	#only generate another wrapper of that id if there is not another one existing there, aka when we have a selected wwrapper
	var node_children = main_map_node.get_children()
	for child_e in node_children:
		if child_e.is_in_group("region_wrapper") and child_e.being_selected and child_e.wrapper_id == cluster_id:
			return
		if child_e.is_in_group("biome_info_popup") and child_e.biome_id == cluster_id:
			return
	
	#instantiate rm_biome_info_popup
	var rm_biome_info_popup_instance = hover_info_popup_scene.instantiate()
	rm_biome_info_popup_instance.biome_id = cluster_id
	main_map_node.add_child(rm_biome_info_popup_instance)
	
	#instatiate wrapper
	var select_region_wrapper_instance = select_region_wrapper_scene.instantiate()
	main_map_node.add_child(select_region_wrapper_instance)
	select_region_wrapper_instance.z_index = 5
	select_region_wrapper_instance.set_wrapper_id(cluster_id)
	select_region_wrapper_instance.draw_tilemap_from_data(tiles_info)
	select_region_wrapper_instance.turn_region_state_to("MapRegionHovered")
	
	update_biome_popup(cluster_id, rm_biome_info_popup_instance)

func _on_biome_unhovered(cluster_id: int) -> void:
	var main_node_children = main_map_node.get_children()
	for m_child in main_node_children:
		if m_child.is_in_group("biome_info_popup") and m_child.biome_id == cluster_id:
			if !m_child.is_persistent:
				m_child.hide_and_delete()


func _on_biome_clicked(cluster_id: int) -> void:
	var main_node_children = main_map_node.get_children()
	for children in main_node_children:
		if children.is_in_group("region_wrapper") and children.wrapper_id == cluster_id:
			#switch selected on and off depending if the biome was already being selected
			if !children.being_selected:
				children.turn_region_state_to("MapRegionSelected")
			else:
				children.turn_region_state_to("MapRegionHovered")
		
		#turn on persistence for biome info popup so it doesnt disapear when clicked and unhovered
		if children.is_in_group("biome_info_popup") and children.biome_id == cluster_id:
			#switch on and off the persistance
			if !children.is_persistent:
				children.initiate_persistance()
			else:
				children.is_persistent = false


func _on_biome_secondary_clicked(cluster_id: int) -> void:
	var m_children = main_map_node.get_children()
	for children_nodes in m_children:
		if children_nodes.is_in_group("biome_info_popup") and children_nodes.biome_id == cluster_id:
			var main_info_body_sprite = children_nodes.get_node_or_null("main_info_body")
			instantiate_travel_tag_displayer_at(main_info_body_sprite, cluster_id)

func instantiate_travel_tag_displayer_at(parent_node, biome_id : int) -> void:
	var num_displayer_offset = Vector2(0, -66)
	var biome_map_num_displayer_instance = biome_map_num_displayer_scene.instantiate()
	#look for the corresponding wrapper and attach the number displayer to it's main info body node
	parent_node.add_child(biome_map_num_displayer_instance)
	biome_map_num_displayer_instance.position = num_displayer_offset
	biome_map_num_displayer_instance.set_number(MapDataIntermediary.get_travel_tag_index(biome_id) + 1)
	biome_map_num_displayer_instance.biome_id = biome_id
	biome_map_num_displayer_instance.z_index = -1


func update_biome_popup(cluster_id: int, rm_biome_popup : Node2D) -> void:
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
		rm_biome_popup.show_biome_info(biome_name, tiles_count, cluster_id, population_data)
		rm_biome_popup.visible = true
	else:
		rm_biome_popup.visible = false



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
