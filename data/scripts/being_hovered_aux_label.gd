extends Label
@onready var select_region_wrapper: Node2D = $".."

func _process(delta: float) -> void:
	text = "H: " + str(select_region_wrapper.being_hovered)
