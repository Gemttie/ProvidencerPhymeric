extends Camera2D
class_name TopDown2DGenericCamera

@export var zoom_val : Vector2 = Vector2(1.0, 1.0)
@export var edge_size: int = 20
@export var scroll_speed: float = 700.0
@export var tilemap_to_clamp_to : TileMapLayer
@export var main_node : Node2D

var view_size : Vector2
var half_screen
var tile_size : Vector2
var map_pixel_size

func _ready() -> void:
	zoom = zoom_val
	if tilemap_to_clamp_to:
		tile_size = tilemap_to_clamp_to.tile_set.tile_size
		map_pixel_size = Vector2(main_node.get_width(), main_node.get_height()) * tile_size


func _process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport_rect().size
	var move_dir := Vector2.ZERO

	# --- SCREEN SIZE ---
	view_size = get_viewport().get_visible_rect().size / zoom
	half_screen = view_size * 0.5

	# --- CURRENT LIMIT VALUES ---
	var min_x = half_screen.x
	var max_x = map_pixel_size.x - half_screen.x
	var min_y = half_screen.y
	var max_y = map_pixel_size.y - half_screen.y

	# --- FIND MOVEMENT DIR FROM MOUSE ---
	if mouse_pos.x <= edge_size:
		move_dir.x = -1
	elif mouse_pos.x >= viewport_size.x - edge_size:
		move_dir.x = 1

	if mouse_pos.y <= edge_size:
		move_dir.y = -1
	elif mouse_pos.y >= viewport_size.y - edge_size:
		move_dir.y = 1

	# --- PREVENT MOVEMENT IF AT LIMIT ---
	if global_position.x <= min_x and move_dir.x < 0:
		move_dir.x = 0
	if global_position.x >= max_x and move_dir.x > 0:
		move_dir.x = 0

	if global_position.y <= min_y and move_dir.y < 0:
		move_dir.y = 0
	if global_position.y >= max_y and move_dir.y > 0:
		move_dir.y = 0

	# --- APPLY MOVEMENT ---
	if move_dir != Vector2.ZERO:
		global_position += move_dir.normalized() * scroll_speed * delta

	# --- FINAL SAFETY CLAMP ---
	global_position.x = clampf(global_position.x, min_x, max_x)
	global_position.y = clampf(global_position.y, min_y, max_y)
