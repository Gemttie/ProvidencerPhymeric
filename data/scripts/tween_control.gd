extends Node
#one time self deleting timer for the color modulation
#get_tree().create_timer(1.0).timeout.connect(_on_modulation_timer_timeout.bind(Color(1.0, 1.0, 1.0, 1.0), 0.5), CONNECT_ONE_SHOT)
func smooth_transition(
	property : String, #what kind of transition will we be doing
	target_node : Node2D, # the node to apply scaling to
	target_value, #vector2 for scale, Color for modulate
	duration: float = 0.5, # tween duration in seconds (default: 0.5)
	transition_type: Tween.TransitionType = Tween.TRANS_QUAD, # easing type (e.g., QUAD, ELASTIC)
	ease_type: Tween.EaseType = Tween.EASE_OUT, # ease mode (e.g., EASE_OUT, EASE_IN_OUT)
	delay: float = 0.0 # delay before tween starts (default: 0)
) -> void:
	var tween = target_node.create_tween()
	tween.tween_property(target_node, property, target_value, duration)\
		.set_trans(transition_type)\
		.set_ease(ease_type)\
		.set_delay(delay)


#tween to a value, stay for some time and tween back to the original value
func ping_pong_smooth_transition(
	property: String,
	target_node: Node2D,
	to_value,
	duration: float = 0.125,
	delay_between: float = 0.05,
	transition_type: Tween.TransitionType = Tween.TRANS_QUAD,
	ease_type: Tween.EaseType = Tween.EASE_OUT
) -> void:
	var original_value = target_node.get(property)
	var tween = target_node.create_tween()
	
	# first go to the hover value
	tween.tween_property(target_node, property, to_value, duration)\
		.set_trans(transition_type)\
		.set_ease(ease_type)

	# wait a bit
	tween.tween_interval(delay_between)

	# then return to the original
	tween.tween_property(target_node, property, original_value, duration)\
		.set_trans(transition_type)\
		.set_ease(ease_type)


#tween to a value, stay for some time and then tween to a value
func ping_pong_smooth_transition_and_then_to(
	property: String,
	target_node: Node2D,
	to_value,
	then_value,
	duration: float = 0.125,
	delay_between: float = 0.05,
	transition_type: Tween.TransitionType = Tween.TRANS_QUAD,
	ease_type: Tween.EaseType = Tween.EASE_OUT
) -> void:
	var tween = target_node.create_tween()
	
	# first go to the hover value
	tween.tween_property(target_node, property, to_value, duration)\
		.set_trans(transition_type)\
		.set_ease(ease_type)

	# wait a bit
	tween.tween_interval(delay_between)

	# then go to the other value
	tween.tween_property(target_node, property, then_value, duration)\
		.set_trans(transition_type)\
		.set_ease(ease_type)
		
		
#tween to a value with a certain tween type, then stay in the middle stay for x time, then tween to a final value with a certain tween type
func double_custom_smooth_transition(
	property: String,
	target_node: Node2D,
	to_first_value,
	to_first_duration,
	to_first_transition_type,
	delay_between,
	to_second_value,
	to_second_duration,
	to_second_transition_type,
	ease_type: Tween.EaseType = Tween.EASE_OUT
) -> void:
	stop_all_tweens(target_node)
	var tween = target_node.create_tween()
	
	# first go to the first value with a tween type
	tween.tween_property(target_node, property, to_first_value, to_first_duration)\
		.set_trans(to_first_transition_type)\
		.set_ease(ease_type)

	# wait a bit
	tween.tween_interval(delay_between)

	# then go to the second value with another tween type
	tween.tween_property(target_node, property, to_second_value, to_second_duration)\
		.set_trans(to_second_transition_type)\
		.set_ease(ease_type)
		

#transition smoothly from a first value, to a seocnd one, to a third one, all customizable
func triple_custom_smooth_transition(
	property: String,
	target_node: Node2D,
	to_first_value,
	to_first_duration,
	to_first_transition_type,
	delay_between_first_second,
	to_second_value,
	to_second_duration,
	to_second_transition_type,
	delay_between_second_third,
	to_third_value,
	to_third_duration,
	to_third_transition_type,
	ease_type: Tween.EaseType = Tween.EASE_OUT
) -> void:
	stop_all_tweens(target_node)
	var tween = target_node.create_tween()
	
	# first go to the first value with a tween type
	tween.tween_property(target_node, property, to_first_value, to_first_duration)\
		.set_trans(to_first_transition_type)\
		.set_ease(ease_type)

	# wait a bit between first and second
	tween.tween_interval(delay_between_first_second)

	# then go to the second value with another tween type
	tween.tween_property(target_node, property, to_second_value, to_second_duration)\
		.set_trans(to_second_transition_type)\
		.set_ease(ease_type)
	
	# wait a bit between second and third
	tween.tween_interval(delay_between_second_third)

	# finally go to the third value
	tween.tween_property(target_node, property, to_third_value, to_third_duration)\
		.set_trans(to_third_transition_type)\
		.set_ease(ease_type)


#func stop_all_tweens(target_node: Node) -> void:
	#var tweens: Array = target_node.get_tree().get_processed_tweens()
	#
	#for tween in tweens:
		#var methods = tween.get_method_list()
		#for method in methods:
			#if method["name"] == "tween_property" and method["args"][0] == target_node:
				#tween.kill()
				#break
				
func stop_all_tweens(target_node: Node) -> void:
	# Simple and effective - just kill all tweens
	var tweens: Array = target_node.get_tree().get_processed_tweens()
	for tween in tweens:
		tween.kill()
