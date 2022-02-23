extends PracticeTester

var first_node: Node2D

func _prepare():
	first_node = _scene_root_viewport.get_child(0)


func test_multiplication_is_used_to_reduce_damage_amount() -> String:
	var regex = RegEx.new()
	regex.compile("amount\\s*\\*|\\*\\s*amount")
	var result = regex.search(_slice.current_text)
	if not result:
		return tr("It looks like amount isn't reduced by a percentage. Did you multiply it by a value less than 1?")
	return ""


func test_damage_amount_is_correct_value() -> String:
	var health = first_node.get("health")
	if is_equal_approx(health, 95):
		return ""
	return tr("The damage amount is %s; If an enemy attacks for 10 damage, it should reduce to 5.") % [100 - health]
