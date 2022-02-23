extends PracticeTester

const ROBOT_CELL := Vector2(5, 3)

var game_board: Node2D


func _prepare() -> void:
	game_board = _scene_root_viewport.get_child(0)


func test_all_units_are_selected() -> String:
	for cell in game_board.units:
		if not cell in game_board.selected_units:
			return tr("Unit in cell %s not selected.") % cell
	return ""


func test_only_units_are_selected() -> String:
	for cell in game_board.selected_units:
		if not cell in game_board.units:
			return tr("Trying to select a cell that doesn't contain a unit: %s.") % cell
	return ""
