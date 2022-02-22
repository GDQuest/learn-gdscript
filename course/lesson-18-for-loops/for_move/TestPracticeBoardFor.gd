extends PracticeTester

var game_board: Node2D
var robot: Node2D

func _prepare() -> void:
	game_board = _scene_root_viewport.get_child(0)


func test_robot_gets_to_bottom_of_board() -> String:
	if not is_equal_approx(game_board.cell.y, game_board.board_size.y - 1):
		return tr("The robot isn't at the bottom of the game board. Did you increase its cell.y coordinate?")
	return ""


func test_use_for_loop() -> String:
	if not  "for" in _slice.current_text:
		return tr("Your code has no for loop. You need to use a for loop to complete this practice, even if there are other solutions!")
	return ""
