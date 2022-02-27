extends PracticeTester

var node: Node
var cell_size := Vector2.ZERO

func _prepare() -> void:
	node = _scene_root_viewport.get_child(0)
	cell_size = node.get("cell_size")


func cell_to_world(cell: Vector2) -> Vector2:
	return cell * cell_size + cell_size / 2


func test_function_maps_cell_to_world_coordinates() -> String:
	if not node.has_method("convert_to_world_coordinates"):
		return tr("Function convert_to_world_coordinates() does not exist. Did you make a typo or not define it?")

	if not "return" in _slice.current_text:
		return tr("We didn't find any \"return\" keyword in your code. Did you forget to return the value from the convert_to_world_coordinates() function?")

	for cell in node.get("TEST_CELL_COORDINATES"):
		var student_result =node.convert_to_world_coordinates(cell)
		var expected := cell_to_world(cell)
		if not student_result is Vector2 or not expected.is_equal_approx(student_result):
			return tr("When converting cell %s to world coordinates, we got %s, but we expected %s.") % [cell, student_result, expected]

	return ""
