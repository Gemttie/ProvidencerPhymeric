extends Node2D

@export var slice_map_layer: TileMapLayer
@export var main_biome_map_layer: TileMapLayer
@export var final_map_layer: TileMapLayer
@export var main_generator_node: Node2D

var border_ta: Vector2i = Vector2i(10, 0)
var border_2_ta: Vector2i = Vector2i(11, 0)
var border_3_ta: Vector2i = Vector2i(11, 1)

func _ready() -> void:
	#wait a frame to ensure both maps are generated
	await get_tree().process_frame
	#dont call the second rescan gen if we're using saved map data for the tilemap drawing
	if MapDataIntermediary.using_saved_map_data == false:
		copy_biomes_using_slice_mask()

func copy_biomes_using_slice_mask() -> void:
	if not slice_map_layer or not main_biome_map_layer or not final_map_layer:
		push_error("One or more required TileMapLayers are not set!")
		return
	
	final_map_layer.clear()
	
	var slice_cells = slice_map_layer.get_used_cells()
	
	for cell_pos in slice_cells:
		var slice_tile_coords: Vector2i = slice_map_layer.get_cell_atlas_coords(cell_pos)
		
		#check if this is one of the border_ta tiles (not the darker borders)
		if slice_tile_coords == border_ta or slice_tile_coords == border_2_ta or slice_tile_coords == border_3_ta:
			var biome_tile_coords: Vector2i = main_biome_map_layer.get_cell_atlas_coords(cell_pos)
			
			# copy it to the final map layer
			if biome_tile_coords != Vector2i(-1, -1): #make sure there's actually a tile
				final_map_layer.set_cell(cell_pos, 0, biome_tile_coords)
	
	#start the second gen pass on the main generator
	main_generator_node.second_gen_pass_rescan_map()
