extends Node2D

@onready var play_random_timer: Timer = $anim_sprite/play_random_timer
@onready var num_text: Label = $anim_sprite/num_text
@onready var origin_line: Line2D = $anim_sprite/origin_line

var biome_id : int

func _ready() -> void:
	origin_line.visible = false
	_on_play_random_timer_timeout()


func _on_play_random_timer_timeout() -> void:
	var rand_num = randi_range(2, 4)
	play_random_timer.start()

func set_number(value : int) -> void:
	num_text.text = str(value)

func grow_and_change_visuals() -> void:
	TweenControl.stop_all_tweens(self)
	TweenControl.smooth_transition("scale", self, Vector2(4.0, 4.0), 0.5, Tween.TransitionType.TRANS_ELASTIC, Tween.EaseType.EASE_OUT)
	origin_line.visible = true
