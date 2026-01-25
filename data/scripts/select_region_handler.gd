extends Node2D

@export var main_map_node : Node2D
@export var empty_hover_region_layer : TileMapLayer
@onready var select_region_wrapper_scene = preload("res://data/scenes/select_region_wrapper.tscn")
@onready var rm_locked_biome_popup_scene = preload("res://data/scenes/rm_locked_biome_popup.tscn")

var empty_hover_tiles := {} 
var hover_modulate_color : Color = Color(1.2, 1.2, 1.2, 1.0)
var select_modulate_color : Color = Color(1.5, 1.5, 1.5, 1.0)

@onready var hover_info_popup_scene = preload("res://data/scenes/rm_biome_info_popup.tscn")
var hover_info_popup: Node2D
var hover_popup_offset: Vector2 = Vector2(0.0, -16.0) # offset from mouse

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
var active_region_instances := {}
var selected_cluster_ids := []
var current_hovered_cluster_id : int = -1

# Store popup data per biome/cluster (you'll need to populate this)
var biome_population_data := {}  # cluster_id -> Array[String] of character portraits

func _ready():
	main_map_node.biome_hovered.connect(_on_biome_hovered)
	main_map_node.unhoverable_region_hovered.connect(_on_unhoverable_region_hovered)
	
	# Create popup instance
	hover_info_popup = hover_info_popup_scene.instantiate()
	hover_info_popup.visible = false
	hover_info_popup.z_index = 11  # Higher z-index to appear above everything
	add_child(hover_info_popup)

func _process(delta: float) -> void:
	if hover_info_popup.visible:
		# Position popup relative to mouse (or cluster center)
		var mouse_pos = get_global_mouse_position()
		hover_info_popup.global_position = mouse_pos + hover_popup_offset


func _input(event):
	# Check if left mouse button was pressed
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		
		# Check all active region instances for click
		for cluster_id in active_region_instances:
			var region_data = active_region_instances[cluster_id]
			var select_region_wrapper = region_data["instance"]
			var tiles_info = region_data["tiles_info"]
			var select_region_layer = select_region_wrapper.get_node("select_region_layer")
			
			# Convert mouse position to tile coordinates relative to this layer
			var local_mouse_pos = select_region_wrapper.to_local(mouse_pos)
			var tile_pos = select_region_layer.local_to_map(local_mouse_pos)
			
			# Check if the clicked tile is in this region
			for tile_data in tiles_info:
				if tile_data["position"] == tile_pos:
					toggle_region_selection(cluster_id, region_data)
					return  # Exit after first match
	
	# Right-click to deselect all
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		deselect_all_regions()

func toggle_region_selection(cluster_id: int, region_data: Dictionary) -> void:
	var select_region_wrapper = region_data["instance"]
	var select_region_layer = select_region_wrapper.get_node("select_region_layer")
	
	if cluster_id in selected_cluster_ids:
		# Deselect the region
		selected_cluster_ids.erase(cluster_id)
		select_region_layer.modulate = hover_modulate_color # Reset to hover color
		
		# Reset animation position if not hovering this cluster anymore
		if current_hovered_cluster_id != cluster_id:
			TweenControl.smooth_transition(
				"position",
				select_region_wrapper,
				Vector2.ZERO,
				0.3,
				Tween.TRANS_CUBIC,
				Tween.EASE_OUT
			)
		
		#print("Deselected cluster: ", cluster_id)
	else:
		# Select the region
		selected_cluster_ids.append(cluster_id)
		select_region_layer.modulate = select_modulate_color  # Brighter color for selection
		
		# Apply lift animation for selected region
		TweenControl.smooth_transition(
			"position",
			select_region_wrapper,
			Vector2(0, -28),
			0.3,
			Tween.TRANS_CUBIC,
			Tween.EASE_OUT
		)
		
		#print("Selected cluster: ", cluster_id)
	
	# Update current hover if we have selections
	if selected_cluster_ids.size() > 0:
		current_hovered_cluster_id = -1
	
	# Optional: Print all selected clusters
	#print("Selected clusters: ", selected_cluster_ids)

func deselect_all_regions():
	for cluster_id in active_region_instances:
		clear_empty_hover_tiles_for_cluster(cluster_id)
		active_region_instances[cluster_id]["instance"].queue_free()

	active_region_instances.clear()
	selected_cluster_ids.clear()
	current_hovered_cluster_id = -1


func _on_unhoverable_region_hovered(value: bool) -> void:
	if value != true: 
		return
	
	#hover_info_popup.hide_popup()
	
	# Only clear non-selected regions when hovering over unhoverable regions
	if selected_cluster_ids.size() == 0:
		# If nothing is selected, clear everything
		clear_all_region_instances()
	else:
		# If we have selections, only clear non-selected regions
		clear_non_selected_regions()

func _on_biome_hovered(cluster_id: int, biome_type: int, tiles_info: Array) -> void:
	# Ignore tiny regions
	if tiles_info.size() < 12:
		return

	# ─────────────────────────────────────────────
	# CASE 1: At least one region is SELECTED
	# ─────────────────────────────────────────────
	if selected_cluster_ids.size() > 0:
		# Never hover a selected region
		if cluster_id in selected_cluster_ids:
			return

		# Unhover previous hover (with animation + auto delete)
		if current_hovered_cluster_id != -1 and current_hovered_cluster_id != cluster_id:
			animate_back_and_maybe_delete(current_hovered_cluster_id)

		current_hovered_cluster_id = cluster_id

		# Already exists → just update visuals
		if cluster_id in active_region_instances:
			var region_data = active_region_instances[cluster_id]
			var wrapper = region_data["instance"]
			var layer = wrapper.get_node("select_region_layer")

			layer.modulate = hover_modulate_color
			TweenControl.smooth_transition(
				"position",
				wrapper,
				Vector2(0, -28),
				0.3,
				Tween.TRANS_CUBIC,
				Tween.EASE_OUT
			)
			
			update_hover_label(cluster_id)
			return

		# Otherwise create new hover instance
		create_region_instance(cluster_id, biome_type, tiles_info, true)
		update_hover_label(cluster_id)
		return

	# ─────────────────────────────────────────────
	# CASE 2: NO selected regions (single-hover mode)
	# ─────────────────────────────────────────────
	if current_hovered_cluster_id != -1 and current_hovered_cluster_id != cluster_id:
		animate_back_and_maybe_delete(current_hovered_cluster_id)

	current_hovered_cluster_id = cluster_id

	# Already exists → just animate hover
	if cluster_id in active_region_instances:
		var region_data = active_region_instances[cluster_id]
		var wrapper = region_data["instance"]

		TweenControl.smooth_transition(
			"position",
			wrapper,
			Vector2(0, -28),
			0.3,
			Tween.TRANS_CUBIC,
			Tween.EASE_OUT
		)
		update_hover_label(cluster_id)
		return

	# Clear everything (single-hover mode safety)
	clear_all_region_instances()

	# Create new hover
	create_region_instance(cluster_id, biome_type, tiles_info, true)
	update_hover_label(cluster_id)

func create_region_instance(cluster_id: int, biome_type: int, tiles_info: Array, is_hovered: bool = false):
	var select_region_wrapper = instantiate_select_wrapper()
	var select_region_layer = select_region_wrapper.get_node("select_region_layer")

	select_region_layer.clear()
	select_region_wrapper.position = Vector2.ZERO

	# Color
	if cluster_id in selected_cluster_ids:
		select_region_layer.modulate = select_modulate_color
	else:
		select_region_layer.modulate = hover_modulate_color

	# Store instance
	active_region_instances[cluster_id] = {
		"instance": select_region_wrapper,
		"tiles_info": tiles_info,
		"biome_type": biome_type
	}

	# Init empty tile ownership
	empty_hover_tiles[cluster_id] = []

	# Draw tiles
	for tile_data in tiles_info:
		var position = tile_data["position"]
		var atlas_coords = tile_data["atlas_coords"]

		select_region_layer.set_cell(position, 0, atlas_coords)

		# Fake empty hover mask
		empty_hover_region_layer.set_cell(position, 0, Vector2(12, 0))
		empty_hover_tiles[cluster_id].append(position)

	# Hover animation
	if is_hovered:
		TweenControl.smooth_transition(
			"position",
			select_region_wrapper,
			Vector2(0, -28),
			0.3,
			Tween.TRANS_CUBIC,
			Tween.EASE_OUT
		)


func instantiate_select_wrapper() -> Node2D:
	var select_region_wrapper_instance = select_region_wrapper_scene.instantiate()
	main_map_node.add_child(select_region_wrapper_instance)
	return select_region_wrapper_instance

func clear_all_region_instances():
	hide_hover_popup()
	for cluster_id in active_region_instances:
		clear_empty_hover_tiles_for_cluster(cluster_id)
		active_region_instances[cluster_id]["instance"].queue_free()

	active_region_instances.clear()
	selected_cluster_ids.clear()
	current_hovered_cluster_id = -1


func clear_non_selected_regions():
	var clusters_to_remove := []

	for cluster_id in active_region_instances:
		if cluster_id not in selected_cluster_ids:
			clusters_to_remove.append(cluster_id)

	for cluster_id in clusters_to_remove:
		clear_empty_hover_tiles_for_cluster(cluster_id)

		active_region_instances[cluster_id]["instance"].queue_free()
		active_region_instances.erase(cluster_id)

	if current_hovered_cluster_id not in active_region_instances:
		current_hovered_cluster_id = -1


func clear_previous_hover(except_cluster_id: int = -1):
	if current_hovered_cluster_id == -1:
		return
	if current_hovered_cluster_id == except_cluster_id:
		return
	if current_hovered_cluster_id not in active_region_instances:
		current_hovered_cluster_id = -1
		return
	
	var region_data = active_region_instances[current_hovered_cluster_id]
	var wrapper = region_data["instance"]
	var layer = wrapper.get_node("select_region_layer")
	
	# Reset visuals ONLY if not selected
	animate_back_and_maybe_delete(current_hovered_cluster_id)
	current_hovered_cluster_id = -1

func animate_back_and_maybe_delete(cluster_id: int):
	if cluster_id not in active_region_instances:
		return

	var region_data = active_region_instances[cluster_id]
	var wrapper: Node2D = region_data["instance"]
	var layer: TileMapLayer = wrapper.get_node("select_region_layer")
	
	if current_hovered_cluster_id == cluster_id:
		hide_hover_popup()
	
	#IMMEDIATELY remove hover-blocking if not selected
	if cluster_id not in selected_cluster_ids:
		clear_empty_hover_tiles_for_cluster(cluster_id)

	# Visual settle animation (purely cosmetic)
	TweenControl.smooth_transition(
		"position",
		wrapper,
		Vector2.ZERO,
		0.25,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	)

	TweenControl.smooth_transition(
		"modulate",
		layer,
		Color(1.0, 1.0, 1.0, 0.0),
		0.25,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	)

	await get_tree().create_timer(0.26).timeout

	# Safety checks
	if not is_instance_valid(wrapper):
		return
	if cluster_id in selected_cluster_ids:
		return
	if wrapper.position != Vector2.ZERO:
		return

	# Now delete visuals
	wrapper.queue_free()
	active_region_instances.erase(cluster_id)

	if current_hovered_cluster_id == cluster_id:
		current_hovered_cluster_id = -1
		#if hover_info_label:
			#hover_info_label.visible = false


func clear_empty_hover_tiles_for_cluster(cluster_id: int) -> void:
	if cluster_id not in empty_hover_tiles:
		return

	for pos in empty_hover_tiles[cluster_id]:
		empty_hover_region_layer.erase_cell(pos)

	empty_hover_tiles.erase(cluster_id)

func update_hover_label(cluster_id: int) -> void:
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
		var sorted_population_data = group_same_portraits(population_data)
		
		# Show popup
		hover_info_popup.show_biome_info(biome_name, tiles_count, cluster_id, sorted_population_data)
		hover_info_popup.visible = true
	else:
		hover_info_popup.visible = false


func get_population_for_cluster(cluster_id: int) -> Array[String]:
	if cluster_id in biome_population_data:
		return biome_population_data[cluster_id]
	
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
		return generate_weighted_population(xil_pool_chance)
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


func hide_hover_popup():
	if hover_info_popup:
		#hover_info_popup.visible = false
		if hover_info_popup.has_method("hide_popup"):
			hover_info_popup.hide_popup()


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
