extends SelectRegionState
class_name MapRegionSelected

func Enter():
	#return to normal pos and modulate
	TweenControl.smooth_transition("position", wrapper_node, wrapper_node.global_position + Vector2(0.0, 20.0), 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	wrapper_node.modulate = Color(1.6, 1.6, 1.6, 1)
	#Transitioned.emit(self,"EnemyShipFormation")
func Exit():
	pass
	
func Update(_delta: float):
	pass

func Physics_Update(_delta: float):
	pass
