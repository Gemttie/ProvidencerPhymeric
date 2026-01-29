extends Node

var clusters_data
const MAP_DATA_PATH = "user://map_data.json"
var using_saved_map_data : bool = false


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
