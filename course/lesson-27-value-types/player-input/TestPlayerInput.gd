extends PracticeTester

var node: Node
var count


func _prepare():
	node = _scene_root_viewport.get_child(0)
	count = node.get("item_count")


func test_item_count_is_int() -> String:
	if not count is int:
		return tr(
			"Item count is not of type int. Did you use the int() function to convert the player_input value?"
		)
	return ""


func test_item_count_matches_player_input() -> String:
	if not count is int:
		return tr("Item count is not of type int. We can't compare it to the player_input value.")

	var input = node.get("player_input")
	if not input is float:
		return tr("Player input is not of its original type anymore. Did you change its value?")

	var input_number = int(input)
	if count != input_number:
		return tr(
			(
				"The item_count value doesn't match the number stored in the player_input variable. We expected %s but got %s."
				% [input_number, count]
			)
		)
	return ""
