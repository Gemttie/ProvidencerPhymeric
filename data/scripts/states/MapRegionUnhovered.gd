extends SelectRegionState
class_name MapRegionUnhovered

func Enter():
	#return to normal pos and modulate
	TweenControl.smooth_transition(
	"position",
	wrapper_node,
	Vector2.ZERO,
	0.3,
	Tween.TRANS_CUBIC,
	Tween.EASE_OUT
	)
	wrapper_node.modulate = Color(1,1,1,1)
	#Transitioned.emit(self,"EnemyShipFormation")
func Exit():
	pass
	
func Update(_delta: float):
	pass

func Physics_Update(_delta: float):
	pass
