extends Sprite2D

@onready var char_image: Sprite2D = $char_image
@onready var particle_gen: GPUParticles2D = $particle_gen
@onready var part_gen_delay: Timer = $part_gen_delay

var portrait_offset : Dictionary = {
	"gotau" : Vector2(0.0, -0.5)
}

func set_char_portrait(char_name: String) -> void:
	# Set random portrait for the main sprite (XIL portraits)
	var portrait_textures: Array[Texture2D] = []
	var base_path = "res://assets/game_sprites/ui/region_map/biome_info_popup/simple/region_map_biome_info_popup_simple_xil_portrait_"
	
	# Try to load portraits 1-6 for XIL
	for i in range(1, 7):
		var path = base_path + str(i) + ".png"
		if ResourceLoader.exists(path):
			portrait_textures.append(load(path))
		else:
			break
	
	#assign random XIL portrait to frame
	if portrait_textures.size() > 0:
		var texture_index = randi() % portrait_textures.size()
		texture = portrait_textures[texture_index]
	
	# Set character-specific portrait for char_image
	var char_portrait_image_path = "res://assets/game_sprites/ui/misc/character_tiny_c_portraits/" + char_name.to_lower() + "_tiny_c_portrait.png"
	
	if ResourceLoader.exists(char_portrait_image_path):
		char_image.texture = load(char_portrait_image_path)
		
		var char_key = char_name.to_lower()
		if portrait_offset.has(char_key):
			char_image.position = portrait_offset[char_key]
		else:
			char_image.position = Vector2.ZERO
		
	else:
		print("Character portrait not found: ", char_portrait_image_path)
		# You could set a default texture here if needed

func gen_particles_with_delay(delay : float) -> void:
	part_gen_delay.start(delay)

func _on_part_gen_delay_timeout() -> void:
	particle_gen.restart()
