extends PracticeTester

var game_board: Node2D

const EXPECTED_ORDERS := ["cheese sandwich", "burger", "toast", "tomato soup"]


func _prepare() -> void:
	game_board = _scene_root_viewport.get_child(0)


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Used Pop Front"), tr(""), test_used_pop_front))
	checks.append(Check.new(tr("Used Append"), tr(""), test_used_append))
	checks.append(Check.new(tr("Completed Orders Contain All Elements"), tr(""), test_completed_orders_contain_all_elements))
	checks.append(Check.new(tr("Starting Data Unchanged"), tr(""), test_starting_data_unchanged))


func test_used_pop_front() -> String:
	if not "waiting_orders.pop_front" in _slice.current_text:
		return tr("We found no call to the pop_front() function. Did you forget to call it?")
	return ""


func test_used_append() -> String:
	if not "completed_orders.append" in _slice.current_text:
		return tr("We found no call to the append() function. Did you forget to call it?")
	return ""


func test_completed_orders_contain_all_elements() -> String:
	var current_orders := PackedStringArray(game_board.completed_orders)

	if current_orders.size() == 0:
		return tr("The completed_orders array is empty. Are you sure you appended the elements?")

	var expected_orders := PackedStringArray(EXPECTED_ORDERS)
	if current_orders != expected_orders:
		return tr("We expected %s, but got %s instead")%[expected_orders, current_orders]
	return ""


func test_starting_data_unchanged() -> String:
	var text := _slice.current_text

	for item in EXPECTED_ORDERS:
		if not item in text:
			return tr("It looks like you removed %s from waiting_orders.")%[item]

	return ""
