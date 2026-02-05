extends SelectRegionState
class_name MapRegionUnhovered

func Enter():
	#return to normal pos and modulate
	print("uhover for :" + str(wrapper_node.wrapper_id))
	TweenControl.stop_all_tweens(main_wrapper_layer)
	TweenControl.smooth_transition("position",main_wrapper_layer,Vector2.ZERO,wrapper_node.animation_time,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	TweenControl.smooth_transition("modulate", main_wrapper_layer, Color(1,1,1,1), wrapper_node.animation_time)
	#wrapper_node.modulate = Color(1,1,1,1)
	wrapper_node.being_hovered = false
		
func Exit():
	pass
	
func Update(_delta: float):
	pass

func Physics_Update(_delta: float):
	pass
