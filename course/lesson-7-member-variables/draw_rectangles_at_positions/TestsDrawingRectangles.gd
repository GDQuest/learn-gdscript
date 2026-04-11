# Test that the user draws 3 squares of 100x100 at 200 pixel intervals on the X axis starting at position (100, 100)
extends PracticeTester

var expected_rect := [
	Vector2(0, 0),
	Vector2(100, 0),
	Vector2(100, 100),
	Vector2(0, 100),
	Vector2(0, 0),
]

var _polygons := []
var _points := []


# We sort vertices for accurate comparison
func _init() -> void:
	expected_rect.sort()


func _prepare() -> void:
	var turtle: DrawingTurtle = _scene_root_viewport.get_child(0)
	_polygons = turtle.get_polygons()
	for p in _polygons:
		var square_points := Array(p.points)
		square_points.sort()
		_points.append(square_points)


func _clean_up() -> void:
	_points.clear()
	_polygons.clear()


func test_draw_three_squares() -> String:
	var count := _polygons.size()
	if count < 3:
		return tr("You drew %s squares but you need to draw 3.") % count
	return ""


func test_squares_are_all_100_by_100() -> String:
	var index := 1
	for p in _points:
		if p != expected_rect:
			return tr("Shape3D number %s is not a square of size 100 by 100.") % index
		index += 1
	return ""


func test_first_shape_is_at_100_by_100() -> String:
	var first_square = _polygons.front()
	if not first_square:
		return tr("No shape drawn. Did you forget to call draw_rectangle()?")

	if not Vector2(100, 100).is_equal_approx(first_square.position):
		return tr("The first square should be drawn at (100, 100). Instead, you drew it at %s.") % [first_square.position]

	return ""


func test_shapes_are_100_pixels_apart() -> String:
	if _polygons.size() < 3:
		return tr("There are fewer than 3 shapes, we can't test if shapes are 100 pixels apart.")
	var first_square = _polygons[0]
	var second_square = _polygons[1]
	var third_square = _polygons[2]
	var first_to_second = abs(second_square.position.x - first_square.position.x)
	var second_to_third = abs(third_square.position.x - second_square.position.x)
	if not is_equal_approx(first_to_second, 200.0) or not is_equal_approx(second_to_third, 200.0):
		return tr("Shapes are not separated by 100 pixels on the X axis.")
	return ""
