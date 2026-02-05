extends SelectRegionState
class_name MapRegionSelected

func Enter():
	#return to normal pos and modulate
	print("select for :" + str(wrapper_node.wrapper_id))
	TweenControl.stop_all_tweens(main_wrapper_layer)
	#TweenControl.smooth_transition("position", main_wrapper_layer, wrapper_node.global_position + Vector2(0.0, -20.0), wrapper_node.animation_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	TweenControl.double_custom_smooth_transition(
		"modulate", main_wrapper_layer,
		Color(2.0 ,2.0 ,2.0 ,1.0), wrapper_node.animation_time / 4, Tween.TransitionType.TRANS_QUAD,
		0.0,
		Color(1.6, 1.6, 1.6, 1.0), wrapper_node.animation_time / 4, Tween.TransitionType.TRANS_QUAD, Tween.EaseType.EASE_OUT
		)
		
	TweenControl.double_custom_smooth_transition(
		"position", main_wrapper_layer,
		wrapper_node.global_position + Vector2(0.0, -12.0), wrapper_node.animation_time / 4, Tween.TransitionType.TRANS_QUAD,
		0.0,
		wrapper_node.global_position + Vector2(0.0, -20.0), wrapper_node.animation_time / 4, Tween.TransitionType.TRANS_QUAD, Tween.EaseType.EASE_OUT
	)
	wrapper_node.being_selected = true
func Exit():
	wrapper_node.being_selected = false
	
func Update(_delta: float):
	pass

func Physics_Update(_delta: float):
	pass
