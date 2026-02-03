extends SelectRegionState
class_name MapRegionSelected

func Enter():
	#return to normal pos and modulate
	TweenControl.stop_all_tweens(main_wrapper_layer)
	TweenControl.smooth_transition("position", main_wrapper_layer, wrapper_node.global_position + Vector2(0.0, -20.0), wrapper_node.animation_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	main_wrapper_layer.modulate = Color(1.6, 1.6, 1.6, 1)
	#Transitioned.emit(self,"EnemyShipFormation")
func Exit():
	pass
	
func Update(_delta: float):
	pass

func Physics_Update(_delta: float):
	pass
