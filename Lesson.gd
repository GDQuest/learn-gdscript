extends MarginContainer

const Goal := preload("res://CodeEditor/Goal.gd")

const STATUS := Goal.STATUS

var goals := []

onready var _scene_player: ScenePlayer = $HSplitContainer/ScenePlayer


func _ready():
	_scene_player.connect("is_invalid", self, "_on_scene_player_invalid")
	_scene_player.connect("is_valid", self, "_on_scene_player_valid")
	goals = get_tree().get_nodes_in_group("goals")
	set_all_goals(STATUS.NONE)


func set_all_goals(status: int) -> void:
	for goal in goals:
		goal.status = status


func _on_scene_player_invalid() -> void:
	set_all_goals(STATUS.INVALID)


func _on_scene_player_valid(scene: Node, script_text: String) -> void:
	for index in goals.size():
		var goal: Goal = goals[index]
		goal.validate_and_set(scene, script_text)
