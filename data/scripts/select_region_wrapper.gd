extends Node2D
@export var unhovered_state : Node
@export var select_region_layer : TileMapLayer
@export var wrapper_shadow_layer : TileMapLayer
@export var delete_timer : Timer

var being_hovered : bool
var wrapper_id
var animation_time : float = 0.3

func _ready() -> void:
	get_parent().biome_unhovered.connect(_on_biome_unhovered)

func _process(delta: float) -> void:
	#fix visual errors when the biome is unhovered
	if being_hovered: return
	
	if select_region_layer.position != Vector2.ZERO:
		TweenControl.smooth_transition("position",select_region_layer,Vector2.ZERO,animation_time,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	if select_region_layer.modulate != Color(1.0, 1.0, 1.0, 1.0):
		TweenControl.smooth_transition("modulate", select_region_layer, Color(1.0,1.0,1.0,1.0), animation_time)


func draw_tilemap_from_data(tiles_info: Array) -> void:
	select_region_layer.clear()
	
	for tile_data in tiles_info:
		var position = tile_data["position"]
		
		#convert position to Vector2i
		var tile_position: Vector2i
		if position is Array:
			#convert from array format [x, y] to Vector2i
			tile_position = Vector2i(position[0], position[1])
		elif position is Dictionary:
			#convert from dictionary format {x: value, y: value} to Vector2i
			tile_position = Vector2i(position.get("x", 0), position.get("y", 0))
		else:
			#assume it's already a Vector2 or Vector2i
			tile_position = Vector2i(position.x, position.y)
		
		var atlas_coords = tile_data["atlas_coords"]
		
		#convert atlas_coords to Vector2i
		var tile_atlas_coords: Vector2i
		if atlas_coords is Array:
			#convert from array format [u, v] to Vector2i
			tile_atlas_coords = Vector2i(atlas_coords[0], atlas_coords[1])
		elif atlas_coords is Dictionary:
			#convert from dictionary format to Vector2i
			tile_atlas_coords = Vector2i(atlas_coords.get("x", 0), atlas_coords.get("y", 0))
		else:
			#assume it's already a Vector2 or Vector2i
			tile_atlas_coords = Vector2i(atlas_coords.x, atlas_coords.y)
		
		#set tiles for main wrapper layer
		select_region_layer.set_cell(tile_position, 0, tile_atlas_coords, 0)
		#set same tiles for wrapper shadow layer, vector2i(12,0) is for that brown tile
		wrapper_shadow_layer.set_cell(tile_position, 0, Vector2i(12,0), 0)
	

func turn_region_state_to(stateName : String) -> void:
	unhovered_state.transition_state_to(stateName)
	
func _on_biome_unhovered(cluster_id) -> void:
	if cluster_id == wrapper_id:
		being_hovered = false
		delete_timer.start(animation_time)

func set_wrapper_id(value) -> void: wrapper_id = value
func get_wrapper_id() -> int: return wrapper_id


func _on_count_down_to_destruction_timeout() -> void:
	queue_free()
