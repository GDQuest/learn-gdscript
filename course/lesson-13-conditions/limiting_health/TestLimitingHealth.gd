extends PracticeTester

var first_node: Control
var health := 0

func _prepare():
	first_node = _scene_root_viewport.get_child(0)
	health = first_node.health

func test_health_does_not_go_above_80() -> String:
	if health > 80:
		return "The health goes above 80 when we heal the character a lot. Did you set the health to 80 when that happens?"
	
	return ""

func test_health_limit_is_not_too_low() -> String:
	if health < 80:
		return "The health limit is too low when we heal the character. Did you set the correct limit?"
	
	return ""
