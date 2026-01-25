extends Node2D
@export var grab_particle_gen : GPUParticles2D
@export var anim_player : AnimationPlayer

func _ready() -> void:
	#play poup anim when this node is created
	pass
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		anim_player.play("popup")
	
func gen_particles() -> void:
	grab_particle_gen.restart()
