extends PracticeTester

var game_board: Node2D
var robot: Node2D


func _prepare() -> void:
	game_board = _scene_root_viewport.get_child(0)


func _define(checks: Array[Check]) -> void:
	checks.append(
		Check.new(tr("Robot Moves To Bottom Row"), tr(""), test_robot_gets_to_bottom_of_board)
	)
	checks.append(Check.new(tr("Use a While Loop to Move"), tr(""), test_use_while_loop))


func test_robot_gets_to_bottom_of_board() -> String:
	var bottom_row: float = game_board.board_size.y - 1
	if is_equal_approx(game_board.cell.y, bottom_row):
		return ""
	if game_board.cell.y < bottom_row:
		return tr(
			"The robot stopped above the bottom row. The cell.y member variable should be equal to board_size.y - 1 (the last row in the board)."
		)
	return tr(
		"The robot moved below the bottom row. The cell.y member variable should be equal to board_size.y - 1 (the last row in the board)."
	)


func test_use_while_loop() -> String:
	var move_to_bottom := _analyzer.get_function_named("move_to_bottom")
	if move_to_bottom:
		for statement in move_to_bottom.get_body().get_statements():
			if statement.get_type() != GDNode.WHILE:
				continue
			for loop_statement in (statement as GDWhileNode).get_loop().get_statements():
				if loop_statement.get_type() != GDNode.PASS:
					return ""
	return tr("Your while loop needs to contain the code that moves the robot.")
