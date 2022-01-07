extends PracticeTester

var first_node: Control
var health := 0

func _prepare():
	first_node = _scene_root_viewport.get_child(0)
	health = first_node.health

func test_health_can_go_below_zero() -> String:
	if health > 0:
		return "The health stays above 0 when we damage the character a lot. Did you set the health to 0 when that happens?"
	
	return ""

func test_health_does_not_go_below_zero() -> String:
	if health < 0:
		return "The health becomes negative if we deal 400 damage to the character. Did you set it to 0?"
	
	return ""
