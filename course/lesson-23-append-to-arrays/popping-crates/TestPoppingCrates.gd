extends PracticeTester

var game_board: Container


func _prepare() -> void:
	game_board = _scene_root_viewport.get_child(0)


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Used Pop Back"), tr(""), test_used_pop_back))
	checks.append(Check.new(tr("Used While Loop"), tr(""), test_used_while_loop))
	checks.append(Check.new(tr("Crates Array Is Empty"), tr(""), test_crates_array_is_empty))


func test_used_pop_back() -> String:
	var run_function := _analyzer.get_function_named("run")
	var uses_pop_back := false
	if run_function:
		for statement in run_function.get_body().get_statements():
			if statement.get_type() != GDNode.WHILE:
				continue
			for loop_statement in (statement as GDWhileNode).get_loop().get_statements():
				if (
					loop_statement.get_type() == GDNode.CALL
					and (loop_statement as GDCallNode).get_function_name() == "pop_back"
				):
					uses_pop_back = true
	if not uses_pop_back:
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
