extends Node2D

@onready var _animation_tree: AnimationTree = find_child("AnimationTree", true, false)

func _ready() -> void:
	var playback := _animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	if playback:
		playback.travel("saying_hi")

func _run() -> void:
	run()
	await get_tree().create_timer(1.0).timeout
	Events.practice_run_completed.emit()

# EXPORT show
func run() -> void:
	show()
# /EXPORT show
