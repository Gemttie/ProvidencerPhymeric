extends Node2D
@onready var population_portrait_scene = preload("res://data/scenes/population_portrait.tscn")
@onready var biome_map_num_displayer_scene = preload("res://data/scenes/biome_map_number_displayer.tscn")

@onready var main_info_body: AnimatedSprite2D = $main_info_body
@onready var portrait_timer: Timer = $main_info_body/portrait_timer
@onready var biome_info_text: Label = $main_info_body/biome_info_text
@onready var local_population_text: Label = $main_info_body/local_population_text
@onready var popup_anims: AnimationPlayer = $popup_anims
@onready var main_particle_gen: GPUParticles2D = $main_particle_gen
@onready var region_name_slate: Sprite2D = $main_info_body/region_name_slate
@onready var labels_arrow_anims: AnimationPlayer = $main_info_body/local_population_text/arrow_lp/labels_arrow_anims


@export var tween_and_part_delay : float = 0.2
@export var pop_up_origin_line : Line2D
@export var pop_up_origin_line_particle_gen : GPUParticles2D

var biome_id : int
var is_persistent : bool = false #wether this isntance stays when is not hovered

var k = 0
var portrait_list_aux : Array[String] = []
#var extended_portrait_list_aux : Array[String] = []
const PORTRAIT_GEN_LOCATIONS : Array[Vector2] = [
	(Vector2(-28.5,40.0)), #1
	(Vector2(-7.5,44.0)), #2
	(Vector2(13.5,43.0)), #3
	(Vector2(34.5,42.0)), #4
	(Vector2(55.5,38.0)), #5
	(Vector2(-50.5,42.0)), #6 (this is the weird one that goes to the left)
]

var aux_portrait_gen_loc : Array[Vector2] = []
var hover_popup_offset: Vector2 = Vector2(0.0, -260.0)


func _ready() -> void:
	visible = false
	z_index = 12
	#initialize line
	pop_up_origin_line.clear_points()
	pop_up_origin_line.add_point(Vector2.ZERO)
	pop_up_origin_line.add_point(Vector2.ZERO)
	pop_up_origin_line.visible = false
	pop_up_origin_line_particle_gen.emitting = false

func _process(delta: float) -> void:
	if visible:
		var mouse_pos
		var popup_pos
		if !is_persistent:
			mouse_pos = get_global_mouse_position()
			popup_pos = mouse_pos + hover_popup_offset
			
			global_position = popup_pos
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

func initiate_persistance() -> void:
	is_persistent = true
	var mouse_pos = get_global_mouse_position()
	var popup_pos = mouse_pos + hover_popup_offset

	global_position = popup_pos
	pop_up_origin_line_particle_gen.global_position = mouse_pos

	# Update origin line
	var smaller_popup_pos = mouse_pos + 0.45 * (popup_pos - mouse_pos)
	pop_up_origin_line.set_point_position(0, smaller_popup_pos)
	pop_up_origin_line.set_point_position(1, mouse_pos)
	pop_up_origin_line.visible = true
	pop_up_origin_line_particle_gen.emitting = true

func start_biome_info_gen(char_portait_list : Array[String]) -> void:
	reset_biome_info_popup() #delete all previous data
	portrait_list_aux = char_portait_list
	var signs := [-1, 1]
	var random_sign: int = signs[randi() % signs.size()]
	
	TweenControl.stop_all_tweens(main_info_body)
	main_info_body.rotation_degrees = 90.0 * random_sign 
	
	#always initialize aux_portrait_gen_loc
	aux_portrait_gen_loc = PORTRAIT_GEN_LOCATIONS.duplicate()
	
	#extra anims
	TweenControl.smooth_transition("rotation_degrees", main_info_body, 0.0, tween_and_part_delay * 4, Tween.TransitionType.TRANS_ELASTIC, Tween.EaseType.EASE_OUT)
	
	if portrait_list_aux.size() >= 6: #if the size of the char list is 6 or above, push_to_front the last pos of the pos array
		var last_loc = PORTRAIT_GEN_LOCATIONS.back()
		aux_portrait_gen_loc.push_front(last_loc)
		aux_portrait_gen_loc.remove_at(aux_portrait_gen_loc.size() - 1)
		
	gen_all_portraits(aux_portrait_gen_loc)

func reset_biome_info_popup() -> void:
	k = 0
	portrait_list_aux = []
	aux_portrait_gen_loc = []
	var child_del = main_info_body.get_children()
	for c in child_del:
		if c.is_in_group("tiny_c_portrait_ui"):
			c.queue_free()
			
	#biome_info_text.text = ""
	#popup_anims.play_backwards("popup")

func gen_all_portraits(gen_locations_list : Array[Vector2]) -> void:
	popup_anims.play("popup")
	gen_next_portrait(gen_locations_list)

func _on_portrait_timer_timeout() -> void:
	if k < portrait_list_aux.size():
		gen_next_portrait(aux_portrait_gen_loc)

func gen_next_portrait(gen_loc_list : Array[Vector2]) -> void:
	var population_portrait_instance = population_portrait_scene.instantiate()
	main_info_body.add_child(population_portrait_instance)
	
	population_portrait_instance.modulate = Color(1,1,1,0)
	population_portrait_instance.scale = Vector2(0.0,0.0) 
	population_portrait_instance.position = gen_loc_list[k] + Vector2(0, 10)
	population_portrait_instance.gen_particles_with_delay(tween_and_part_delay)
	population_portrait_instance.set_char_portrait(portrait_list_aux[k])
	
	TweenControl.smooth_transition("modulate", population_portrait_instance, Color(1,1,1,1), tween_and_part_delay,Tween.TransitionType.TRANS_CIRC, Tween.EaseType.EASE_IN)
	TweenControl.smooth_transition("scale", population_portrait_instance, Vector2(1, 1), tween_and_part_delay * 2, Tween.TransitionType.TRANS_BACK, Tween.EaseType.EASE_IN_OUT)
	TweenControl.smooth_transition("position", population_portrait_instance, gen_loc_list[k])
	portrait_timer.start(0.06)
	aux_portrait_gen_loc = gen_loc_list
	
	k += 1


func gen_particles() -> void:
	main_particle_gen.restart()
	
# Add these to rm_biome_info_popup.gd
func show_biome_info(biome_name: String, biome_tile_count, cluster_id: int, population: Array[String] = []) -> void:
	# Clear previous data
	reset_biome_info_popup()
	var size_desc = get_size_description(biome_tile_count)
	# Set biome name (you'll need to add this to your scene)
	biome_info_text.text = "HAZZARD : %s\nREGION SIZE : %s (%d tiles)\nCLIMATE : " % [biome_name, size_desc, biome_tile_count]
	biome_info_text.visible = true
	
	
	# Show population portraits if available
	if population.size() > 0:
		start_biome_info_gen(population)
	else:
		# Just show the popup without portraits
		popup_anims.play("popup")
		await get_tree().create_timer(1.0).timeout
		popup_anims.play_backwards("popup")


func hide_and_delete() -> void:
	reset_biome_info_popup()
	popup_anims.play_backwards("popup_aux")
	popup_anims.speed_scale = 2.0
	
	#right before deleting, generate a cosmetic instance of the travel tag displayer
	var body_children = main_info_body.get_children()
	for b_children in body_children:
		if b_children.is_in_group("travel_tag_displayer") and b_children.biome_id == biome_id:
			#save the pose and make a cosmetic clone
			var displayer_pos = b_children.global_position
			clone_aux_travel_tag_displayer_at(get_parent(), biome_id, displayer_pos, get_parent().get_main_tilemap())
			
	
	await popup_anims.animation_finished
	queue_free()
	
#I'm using main tile map here because we need the settings and tiles of the tilemap to handle the anchor position
func clone_aux_travel_tag_displayer_at(parent_node, biome_id : int, g_pos : Vector2, main_tilemap : TileMapLayer) -> void:
	var biome_map_num_displayer_instance = biome_map_num_displayer_scene.instantiate()
	#look for the corresponding wrapper and attach the number displayer to it's main info body node
	parent_node.add_child(biome_map_num_displayer_instance)
	biome_map_num_displayer_instance.global_position = g_pos
	biome_map_num_displayer_instance.set_number(MapDataIntermediary.get_travel_tag_index(biome_id) + 1)
	biome_map_num_displayer_instance.biome_id = biome_id
	biome_map_num_displayer_instance.z_index = 9
	biome_map_num_displayer_instance.scale = Vector2(4.0, 4.0)
	
	#get anchor pos for that biome and tween animate to it
	var tag_displayer_anchor_pos = MapDataIntermediary.get_biome_anchor_global(biome_id, main_tilemap)
	TweenControl.stop_all_tweens(biome_map_num_displayer_instance)
	TweenControl.smooth_transition_then_node_function(
		"global_position", biome_map_num_displayer_instance, tag_displayer_anchor_pos, biome_map_num_displayer_instance, "grow_and_change_visuals", [], 0.4, Tween.TransitionType.TRANS_QUAD, Tween.EaseType.EASE_OUT
		)
	TweenControl.smooth_transition("scale", biome_map_num_displayer_instance, Vector2.ZERO, 0.4, Tween.TransitionType.TRANS_QUAD, Tween.EaseType.EASE_OUT)

func get_size_description(cluster_size: int) -> String:
	if cluster_size <= 0: return "EMPTY"
	if cluster_size > 0 and cluster_size <= 40: return "MINUSCULE"
	if cluster_size > 40 and cluster_size <= 160: return "SMALL"
	if cluster_size > 160 and cluster_size <= 640: return "MODERATE"
	if cluster_size > 640 and cluster_size <= 2560: return "LARGE"
	if cluster_size > 2560 and cluster_size <= 10240: return "VERY LARGE"
	if cluster_size > 10240 and cluster_size <= 40960: return "HUGE"
	if cluster_size > 40960 and cluster_size <= 163840: return "ENORMOUS"
	if cluster_size > 163840 and cluster_size <= 655360: return "COLOSSAL"
	return "CONTINENT SIZED"


func _on_area_2d_area_entered(area: Area2D) -> void:
	if is_persistent:
		var anim_time : float = 0.4
		labels_arrow_anims.stop()
		TweenControl.stop_all_tweens(biome_info_text)
		TweenControl.stop_all_tweens(local_population_text)
		TweenControl.smooth_transition_for_node_only("modulate", biome_info_text, Color(3.0, 3.0, 3.0, 0.0), anim_time)
		TweenControl.smooth_transition_for_node_only("modulate", local_population_text, Color(3.0, 3.0, 3.0, 0.0), anim_time)
		TweenControl.smooth_transition("material:shader_parameter/progress", main_info_body, 1.0, anim_time)
		TweenControl.smooth_transition("material:shader_parameter/progress", region_name_slate, 1.0, anim_time)
		
		#affect the portraits visually as well
		var main_info_body_children = main_info_body.get_children()
		for mib_child in main_info_body_children:
			if mib_child.is_in_group("tiny_c_portrait_ui"):
				TweenControl.stop_all_tweens(mib_child)
				TweenControl.smooth_transition("modulate", mib_child, Color(0.0, 0.0, 1.0, 0.5), anim_time)				
				TweenControl.smooth_transition("scale", mib_child, Vector2(0.25, 0.25), anim_time)
		

func _on_area_2d_area_exited(area: Area2D) -> void:
	if is_persistent:
		var anim_time : float = 0.4
		TweenControl.smooth_transition_for_node_only("modulate", biome_info_text, Color(1,1,1,1), anim_time)
		TweenControl.smooth_transition_for_node_only("modulate", local_population_text, Color(1,1,1,1), anim_time)
		TweenControl.smooth_transition("material:shader_parameter/progress", main_info_body, 0.0, anim_time)
		TweenControl.smooth_transition("material:shader_parameter/progress", region_name_slate, 0.0, anim_time)
		labels_arrow_anims.play("up_and_down")
		
		#affect the portraits visually as well
		var main_info_body_children = main_info_body.get_children()
		for mib_child in main_info_body_children:
			if mib_child.is_in_group("tiny_c_portrait_ui"):
				TweenControl.stop_all_tweens(mib_child)
				TweenControl.smooth_transition("modulate", mib_child, Color(1.0, 1.0, 1.0, 1.0), anim_time)
				TweenControl.smooth_transition("scale", mib_child, Vector2(1.0, 1.0), anim_time)
