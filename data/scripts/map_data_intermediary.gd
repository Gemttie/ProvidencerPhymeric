extends Node

var clusters_data
var additional_map_data
const MAP_DATA_PATH = "user://map_data.json"
const MAP_ADDITIONAL_DATA_PATH = "user://additional_map_data.json"
var using_saved_map_data : bool = false
var travel_tag_display_info : Array = []


func _ready() -> void:
	initialize_additional_map_data_file()
	additional_map_data = load_additional_map_data()
	

func copy_map_data_from_disk() -> void:
	clusters_data = load_clusters_data_full()["clusters"]

func load_clusters_data_full() -> Dictionary:
	if not FileAccess.file_exists(MAP_DATA_PATH):
		return {}  # empty if no file

	var file := FileAccess.open(MAP_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open map data")
		return {}

	var json := JSON.new()
	var text := file.get_as_text()
	file.close()

	if json.parse(text) != OK:
		push_error("Failed to parse map data")
		return {}

	var data : Dictionary = json.get_data()
	return data


#===========================
#ADDITIONAL MAP DATA HANDLER
#===========================

func initialize_additional_map_data_file() -> void:
	if not FileAccess.file_exists(MAP_ADDITIONAL_DATA_PATH):
		var initial_data = {"id_data": {}, "global_modifiers": {}}
		save_additional_map_data(initial_data)

func save_additional_map_data(data: Dictionary) -> void:
	var file = FileAccess.open(MAP_ADDITIONAL_DATA_PATH, FileAccess.WRITE)
	if not file:
		push_error("Failed to save additional map data")
		return
	
	file.store_var(data)
	file.close()

func load_additional_map_data() -> Dictionary:
	if not FileAccess.file_exists(MAP_ADDITIONAL_DATA_PATH):
		# Create initial structure if file doesn't exist
		return {"id_data": {}, "global_modifiers": {}}

	var file = FileAccess.open(MAP_ADDITIONAL_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open additional map data")
		return {"id_data": {}, "global_modifiers": {}}

	var data = file.get_var()
	file.close()
	
	# Ensure the data has the expected structure
	if data is Dictionary:
		if not data.has("id_data"):
			data["id_data"] = {}
		if not data.has("global_modifiers"):
			data["global_modifiers"] = {}
		return data
	else:
		# If data isn't a dictionary, return default structure
		return {"id_data": {}, "global_modifiers": {}}

# SETTERS
func set_biome_population_data(id_number: String, population_data: Array) -> void:
	additional_map_data = load_additional_map_data()
	if not additional_map_data["id_data"].has(id_number):
		additional_map_data["id_data"][id_number] = {}
	additional_map_data["id_data"][id_number]["biome_population_data"] = population_data
	save_additional_map_data(additional_map_data)

func set_active_events(id_number: String, events: Array) -> void:
	additional_map_data = load_additional_map_data()
	if not additional_map_data["id_data"].has(id_number):
		additional_map_data["id_data"][id_number] = {}
	additional_map_data["id_data"][id_number]["active_events"] = events
	save_additional_map_data(additional_map_data)

func set_resource_count(id_number: String, count: int) -> void:
	additional_map_data = load_additional_map_data()
	if not additional_map_data["id_data"].has(id_number):
		additional_map_data["id_data"][id_number] = {}
	additional_map_data["id_data"][id_number]["resource_count"] = count
	save_additional_map_data(additional_map_data)

func set_is_explored(id_number: String, explored: bool) -> void:
	additional_map_data = load_additional_map_data()
	if not additional_map_data["id_data"].has(id_number):
		additional_map_data["id_data"][id_number] = {}
	additional_map_data["id_data"][id_number]["is_explored"] = explored
	save_additional_map_data(additional_map_data)

func set_hazard_level(id_number: String, level: int) -> void:
	additional_map_data = load_additional_map_data()
	if not additional_map_data["id_data"].has(id_number):
		additional_map_data["id_data"][id_number] = {}
	additional_map_data["id_data"][id_number]["hazard_level"] = level
	save_additional_map_data(additional_map_data)

# GETTERS
func get_biome_population_data(id_number: String) -> Array:
	additional_map_data = load_additional_map_data()
	if additional_map_data["id_data"].has(id_number) and additional_map_data["id_data"][id_number].has("biome_population_data"):
		return additional_map_data["id_data"][id_number]["biome_population_data"]
	return []

func get_active_events(id_number: String) -> Array:
	additional_map_data = load_additional_map_data()
	if additional_map_data["id_data"].has(id_number) and additional_map_data["id_data"][id_number].has("active_events"):
		return additional_map_data["id_data"][id_number]["active_events"]
	return []

func get_resource_count(id_number: String) -> int:
	additional_map_data = load_additional_map_data()
	if additional_map_data["id_data"].has(id_number) and additional_map_data["id_data"][id_number].has("resource_count"):
		return additional_map_data["id_data"][id_number]["resource_count"]
	return 0

func get_is_explored(id_number: String) -> bool:
	additional_map_data = load_additional_map_data()
	if additional_map_data["id_data"].has(id_number) and additional_map_data["id_data"][id_number].has("is_explored"):
		return additional_map_data["id_data"][id_number]["is_explored"]
	return false

func get_hazard_level(id_number: String) -> int:
	additional_map_data = load_additional_map_data()
	if additional_map_data["id_data"].has(id_number) and additional_map_data["id_data"][id_number].has("hazard_level"):
		return additional_map_data["id_data"][id_number]["hazard_level"]
	return 0

# SPECIFIC ITEM GETTERS FROM ARRAYS
func get_specific_biome_population(id_number: String, index: int):
	var population_array = get_biome_population_data(id_number)
	if index >= 0 and index < population_array.size():
		return population_array[index]
	return null

func get_specific_active_event(id_number: String, index: int):
	var events_array = get_active_events(id_number)
	if index >= 0 and index < events_array.size():
		return events_array[index]
	return null

# ARRAY MODIFICATION FUNCTIONS
func add_biome_population(id_number: String, population_item) -> void:
	var current = get_biome_population_data(id_number)
	current.append(population_item)
	set_biome_population_data(id_number, current)

func add_active_event(id_number: String, event) -> void:
	var current = get_active_events(id_number)
	current.append(event)
	set_active_events(id_number, current)

func remove_biome_population(id_number: String, index: int) -> void:
	var current = get_biome_population_data(id_number)
	if index >= 0 and index < current.size():
		current.remove_at(index)
		set_biome_population_data(id_number, current)

func remove_active_event(id_number: String, index: int) -> void:
	var current = get_active_events(id_number)
	if index >= 0 and index < current.size():
		current.remove_at(index)
		set_active_events(id_number, current)

# BULK GETTER FOR ALL DATA
func get_all_id_data(id_number: String) -> Dictionary:
	additional_map_data = load_additional_map_data()
	if additional_map_data["id_data"].has(id_number):
		return additional_map_data["id_data"][id_number].duplicate(true)  # Return a copy
	return {}


func add_travel_tag_display_info(id_value : int) -> void:
	if !travel_tag_display_info.has(id_value):
		travel_tag_display_info.append(id_value)

func get_travel_tag_index(id_value: int) -> int:
	var index_val : int = travel_tag_display_info.find(id_value)
	return index_val


func get_biome_anchor_global(biome_id: int, tilemap : TileMapLayer) -> Vector2:
	for cluster in clusters_data:
		if cluster.get("id", -1) == biome_id:
			var anchor_tile = Vector2(cluster["anchor"][0], cluster["anchor"][1])
			
			#convert tile position to global coordinates
			var local_pos := tilemap.map_to_local(anchor_tile)
			var global_pos := tilemap.to_global(local_pos)
			
			return global_pos
	
	#return null Vector2 if biome not found
	return Vector2.ZERO
