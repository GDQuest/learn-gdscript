extends Node2D

var max_number := 20
var result := 0
var results := []

onready var _result_label := $Sprite/Label as Label
onready var _rolling_results := $RollingResultsLabel as Label
onready var _animation_player := $AnimationPlayer as AnimationPlayer


func _run() -> void:
	seed(123456789)
	for i in range(5):
		roll_die(max_number)
		results.append(result)
		_rolling_results.text = str(results)
		_result_label.text = str(result)
		_animation_player.play("roll")
		yield(_animation_player, "animation_finished")
	yield(get_tree().create_timer(1.5), "timeout")
	Events.emit_signal("practice_run_completed")

# EXPORT rolling
func roll_die(sides):
	result = randi() % sides + 1
# /EXPORT rolling
