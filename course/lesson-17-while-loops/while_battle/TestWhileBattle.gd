extends PracticeTester

var first_node: Node2D
var turtle_power


func _prepare() -> void:
	first_node = _scene_root_viewport.get_child(0)
	turtle_power = first_node.get("turtle_power")


func test_robot_health_reduced_to_zero() -> String:
	return "Test not implemented yet."


func test_use_while_loop() -> String:
	return "Test not implemented yet."
