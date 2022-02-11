extends PracticeTester

var first_node: Node2D
var turtle_power

func _prepare() -> void:
	first_node = _scene_root_viewport.get_child(0)
	turtle_power = first_node.get("turtle_power")

func _robot_health_reduced_to_zero() -> String:
	return ""

func robot_health_reduced_to_zero() -> String:
	var regex = RegEx.new()
	regex.compile("scale\\s*\\+.*Vector2|scale\\s*\\-.*Vector2|Vector2.*\\+.*scale")
	var result = regex.search(_slice.current_text)
	if not result:
		return "It looks like the scale isn't increasing by some vector. Did you add a vector to scale?"
	return ""


func test_robot_health_reduced_to_zero() -> String:
	
	if turtle_power * 100 >= 100:
		return ""

	return "Health is too high."
