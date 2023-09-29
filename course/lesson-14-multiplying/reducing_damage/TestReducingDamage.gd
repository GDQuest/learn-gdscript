extends PracticeTester

const TEST_DAMAGE = 10

var first_node: Node2D

var damage_taken_at_level_2 = -1
var damage_taken_at_level_3 = -1

func _prepare():
	first_node = _scene_root_viewport.get_child(0)
	
	first_node.level = 2
	var health_before_1 = first_node.health
	first_node.take_damage(TEST_DAMAGE)
	var health_after_1 = first_node.health
	damage_taken_at_level_2 = health_before_1 - health_after_1

	first_node.level = 3
	var health_before_2 = first_node.health
	first_node.take_damage(TEST_DAMAGE)
	var health_after_2 = first_node.health
	damage_taken_at_level_3 = health_before_2 - health_after_2


func test_multiplication_is_used_to_reduce_damage_amount() -> String:
	var regex = RegEx.new()
	regex.compile("amount\\s*\\*|\\*\\s*amount")
	var result = regex.search(_slice.current_text)
	if not result:
		return tr("It looks like amount isn't reduced by a percentage. Did you multiply it by a value less than 1?")
	return ""


func test_damage_amount_is_correct_value() -> String:
	if damage_taken_at_level_3 != TEST_DAMAGE / 2:
		return tr("The character did not take half damage despite being level 3. Did you multiply the amount by 0.5 to reduce it?")
	
	if damage_taken_at_level_2 != TEST_DAMAGE:
		if damage_taken_at_level_2 > 0:
			return tr("The character appears not to be taking full damage when their level is below 3. Did you use a condition to limit damage reduction to when the level is greater or equal to 3?")
		else:
			return tr("The character appears to be taking 0 damage when its level is less than 3. Did you subtract the amount to health when the level is less than 3?")
	return ""
