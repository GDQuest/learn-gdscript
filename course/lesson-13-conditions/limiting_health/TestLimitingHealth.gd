extends PracticeTester

var first_node: Control
var health := 0

var _expected_health_values = [60, 80]

func _prepare():
	first_node = _scene_root_viewport.get_child(0)
	health = first_node.health

func test_health_does_not_go_above_80() -> String:
	if health > 80:
		return tr("The health goes above 80 when we heal the character a lot. Did you set the health to 80 when that happens?")
	
	return ""

func test_health_limit_is_not_too_low() -> String:
	if health < 80:
		return tr("The health limit is too low when we heal the character. Did you set the correct limit?")
	
	return ""

func test_health_takes_different_values() -> String:
	if first_node.get_produced_health_values() != _expected_health_values:
		return tr("When healing the character twice by 40 points, the health should go up to 60, then 80. Instead, we got %s.\nAre you using the amount parameter?") % [first_node.get_produced_health_values()]
	return ""
