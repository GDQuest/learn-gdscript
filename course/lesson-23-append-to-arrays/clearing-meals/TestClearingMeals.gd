extends PracticeTester

var game_board: Node2D
# Preloading constants from other scripts remains the same
const WAIT_QUEUE := preload("ClearingMeals.gd").WAIT_QUEUE

func _prepare() -> void:
	# Assuming _scene_root_viewport is a property of the base PracticeTester class
	game_board = _scene_root_viewport.get_child(0)


func test_used_pop_front() -> String:
	# Code-slicing logic typically remains the same as it checks raw text
	if not "waiting_orders.pop_front" in _slice.current_text:
		return tr("We found no call to the pop_front() function. Did you forget to call it?")
	return ""


func test_used_append() -> String:
	if not "completed_orders.append" in _slice.current_text:
		return tr("We found no call to the append() function. Did you forget to call it?")
	return ""


func test_completed_orders_contain_all_elements() -> String:
	# Godot 4: Warning ignore uses the @ annotation syntax
	@warning_ignore("unsafe_property_access")
	var completed_orders_raw = game_board.completed_orders
	
	# Godot 4: PoolStringArray is now PackedStringArray
	var current_orders := PackedStringArray(completed_orders_raw)

	# Godot 4: is_empty() is preferred over size() == 0
	if current_orders.is_empty():
		return tr("the completed_orders array is empty. Are you sure you appended the elements?")
	
	var expected_orders := PackedStringArray()
	
	# Godot 4: for loops over integers must use range()
	for i in range(WAIT_QUEUE.size()):
		var order = WAIT_QUEUE[-i - 1]
		expected_orders.append(order.name)
		
	if current_orders != expected_orders:
		# String formatting with % still works in Godot 4
		return tr("we were expecting %s, but got %s instead") % [expected_orders, current_orders]
	return ""
