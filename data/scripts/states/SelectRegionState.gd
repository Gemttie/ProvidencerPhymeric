extends Node
class_name SelectRegionState

@export var wrapper_node : Node2D
signal Transitioned

func Enter():
	pass
func Exit():
	pass
	
func Update(_delta: float):
	pass

func Physics_Update(_delta: float):
	pass
	
func transition_state_to(stateName : String) -> void:
	Transitioned.emit(self,stateName)
