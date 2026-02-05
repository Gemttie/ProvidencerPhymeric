extends SelectRegionState
class_name MapRegionHovered

func Enter():
	#return to normal pos and modulate
	print("hover for :" + str(wrapper_node.wrapper_id))
	TweenControl.stop_all_tweens(main_wrapper_layer)
	TweenControl.smooth_transition("position", main_wrapper_layer, wrapper_node.global_position + Vector2(0.0, -20.0), wrapper_node.animation_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	TweenControl.smooth_transition("modulate", main_wrapper_layer, Color(1.3 ,1.3 ,1.3 ,1.0), wrapper_node.animation_time)
	wrapper_node.being_hovered = true
func Exit():
	wrapper_node.being_hovered = false
	
func Update(_delta: float):
	pass

func Physics_Update(_delta: float):
	pass
