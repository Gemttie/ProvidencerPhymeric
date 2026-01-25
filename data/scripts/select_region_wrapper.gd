extends Node2D
@export var unhovered_state : Node

func turn_region_state_to(stateName : String) -> void:
	unhovered_state.transition_state_to(stateName)
