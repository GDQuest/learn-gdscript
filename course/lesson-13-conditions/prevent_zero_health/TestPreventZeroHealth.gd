extends PracticeTester

var first_node: Control
var health := 0

var _expected_health_values = [10, 0, 0]

func _prepare():
	first_node = _scene_root_viewport.get_child(0)
	health = first_node.health

func test_health_reaches_zero() -> String:
	if health > 0:
		return tr("The health stays above 0 when we damage the character a lot. Did you set the health to 0 when that happens?")
	
	return ""

func test_health_does_not_go_below_zero() -> String:
	if health < 0:
		return tr("The health becomes negative if we deal 400 damage to the character. Did you set it to 0?")
	
	return ""

func test_health_takes_different_values() -> String:
	if first_node.get_produced_health_values() != _expected_health_values:
		return tr("When damaging the character three times by 10 points, the health should go down to 10, then 0. Instead, we got %s.\nAre you using the amount parameter?") % [first_node.get_produced_health_values()]
	return ""
