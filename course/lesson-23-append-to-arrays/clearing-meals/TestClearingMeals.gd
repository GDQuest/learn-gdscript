extends PracticeTester

var game_board: Node2D
const WAIT_QUEUE := preload("ClearingMeals.gd").WAIT_QUEUE

func _prepare() -> void:
	game_board = _scene_root_viewport.get_child(0)


func test_used_pop_front() -> String:
	if not "waiting_orders.pop_front" in _slice.current_text:
		return tr("We found no call to the pop_front() function. Did you forget to call it?")
	return ""


func test_used_append() -> String:
	if not "completed_orders.append" in _slice.current_text:
		return tr("We found no call to the append() function. Did you forget to call it?")
	return ""

func test_completed_orders_contain_all_elements() -> String:
	# warning-ignore:unsafe_property_access
	var current_orders := PackedStringArray(game_board.completed_orders)

	if current_orders.size() == 0:
		return tr("the completed_orders array is empty. Are you sure you appended the elements?")
	
	var expected_orders := PackedStringArray()
	
	for i in WAIT_QUEUE.size():
		var order = WAIT_QUEUE[-i-1]
		expected_orders.append(order.name)
	if current_orders != expected_orders:
		return tr("we were expecting %s, but got %s instead")%[expected_orders, current_orders]
	return ""
	
