extends PracticeTester

var game_board: Container

func _prepare() -> void:
	game_board = _scene_root_viewport.get_child(0)


func test_used_pop_back() -> String:
	if not "pop_back()" in _slice.current_text:
		return tr("We found no call to the pop_back() function. Did you forget to call it?")
	return ""

func test_used_while_loop() -> String:
	if not "while " in _slice.current_text:
		return tr("You didn't use the while keyword")
	return ""

func test_crates_array_is_empty() -> String:
	# warning-ignore:unsafe_property_access
	var crates_size = game_board.crates.size()
	if crates_size != 0:
		return tr("The crate array is not empty")
	return ""
