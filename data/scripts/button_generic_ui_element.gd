extends Sprite2D

@export var deco1_sprite : CompressedTexture2D
@export var button_area_size : Vector2 = Vector2(9.0, 15.0) ##Use half the size of the area you want
@export var button_area_rot_degrees : float = 0.0

@onready var deco_1: Sprite2D = $deco1
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

var button_state : String = "unhovered"

func _ready() -> void:
	if deco1_sprite != null: deco_1.texture = deco1_sprite
	var shape = collision_shape_2d.shape.duplicate()
	shape.extents = button_area_size
	collision_shape_2d.shape = shape
	collision_shape_2d.rotation_degrees = button_area_rot_degrees

func _on_area_2d_mouse_entered() -> void:
	button_state = "hovered"
	var target_color = Color(2,2,2,1)
	TweenControl.smooth_transition("modulate", self, target_color, 0.14, Tween.TransitionType.TRANS_QUAD, Tween.EaseType.EASE_OUT)
	
	#smoothly change modulate to that value

func _on_area_2d_mouse_exited() -> void:
	button_state = "unhovered"
	var target_color = Color(1,1,1,1)
	TweenControl.smooth_transition("modulate", self, target_color, 0.14, Tween.TransitionType.TRANS_QUAD, Tween.EaseType.EASE_OUT)

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var return_color
		if button_state == "hovered":
			return_color = Color(2,2,2,1)
		else:
			return_color = Color(1,1,1,1)
		var click_color = Color(3,3,3,1)

		TweenControl.ping_pong_smooth_transition("modulate", self, click_color, 0.08, 0.04, Tween.TransitionType.TRANS_QUAD, Tween.EaseType.EASE_OUT)
