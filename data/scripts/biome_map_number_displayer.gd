extends Node2D

@onready var play_random_timer: Timer = $anim_sprite/play_random_timer
@onready var num_text: Label = $anim_sprite/num_text
@export var origin_line: Line2D
@onready var anim_sprite: AnimatedSprite2D = $anim_sprite
@onready var displayer_anims: AnimationPlayer = $displayer_anims
@onready var displayer_anims_timer: Timer = $displayer_anims/displayer_anims_timer
@onready var death_timer: Timer = $death_timer


var biome_id : int
var displayer_offset : Vector2 = Vector2(0, -28)
var is_waypoint : bool = false#if the displayer is on the waypoint state,aka when ur not hovering it and its just marking the full map itself

func _ready() -> void:
	origin_line.visible = false
	origin_line.clear_points()
	origin_line.add_point(Vector2.ZERO)
	origin_line.add_point(Vector2.ZERO)
	_on_play_random_timer_timeout()
	displayer_anims_timer.start(randi_range(3, 4))
	
func _process(delta: float) -> void:
	#if origin_line.visible == false: return
	origin_line.set_point_position(0, global_position)
	origin_line.set_point_position(1, anim_sprite.global_position)


func _on_play_random_timer_timeout() -> void:
	var rand_num = randi_range(2, 4)
	play_random_timer.start(rand_num)
	anim_sprite.play("shine")

func set_number(value : int) -> void:
	num_text.text = str(value)

func grow_and_change_visuals() -> void:
	TweenControl.stop_all_tweens(self)
	TweenControl.smooth_transition("scale", self, Vector2(4.0, 4.0), 0.5, Tween.TransitionType.TRANS_ELASTIC, Tween.EaseType.EASE_OUT)
	TweenControl.smooth_transition("position", anim_sprite, displayer_offset, 0.5)
	origin_line.visible = true

func shrink_and_change_visuals() -> void:
	var anim_time = 0.5
	TweenControl.stop_all_tweens(self)
	TweenControl.smooth_transition("scale", self, Vector2(0.0, 0.0), anim_time)
	origin_line.visible = false
	#it's giving issues when we use delayed death, so we are gonna do
	#delayed death but, we are also gonna get this thing off its group,
	#so other parts of the code dont detect it
	remove_from_group("travel_tag_displayer")
	death_timer.start(anim_time)


func _on_delete_displayer(biome_id_to_delete: int) -> void:
	if biome_id == biome_id_to_delete:
		shrink_and_change_visuals()

func update_all_travel_tag_numbers()-> void:
	#var tagged_biomes_arr = MapDataIntermediary.travel_tag_display_info
	var new_number = MapDataIntermediary.get_travel_tag_index(biome_id) + 1
	num_text.text = str(new_number)

func _on_displayer_anims_timer_timeout() -> void:
	displayer_anims.play("glow")
	displayer_anims_timer.start(randi_range(2, 3))


func _on_death_timer_timeout() -> void:
	queue_free()
