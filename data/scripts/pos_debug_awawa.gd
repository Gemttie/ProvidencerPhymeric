extends TextureRect

var direction: int = 0
var speed: int = 100

func _physics_process(delta: float) -> void:
	direction = 0
	
	if Input.is_action_pressed("ui_left"):
		direction = -1
	elif Input.is_action_pressed("ui_right"):
		direction = 1
	
	position.x += speed * direction * delta
