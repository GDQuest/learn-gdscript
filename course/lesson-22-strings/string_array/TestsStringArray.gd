extends PracticeTester

var desired_combo = ["jump", "jump", "damage", "damage", "level"]
var robot: Node2D

func _prepare() -> void:
	robot = _scene_root_viewport.get_child(0)


func test_use_for_loop() -> String:
	if not  "for" in _slice.current_text:
		return "Your code has no for loop. You need to use a for loop to complete this practice, even if there are other solutions!"
	return ""


func test_robot_combo_is_correct() -> String:
	var robot_combo = robot.get("combo")
	if not robot_combo == desired_combo:
		return "The combo isn't correct. Did you use the right actions in the right order?"
	return ""
