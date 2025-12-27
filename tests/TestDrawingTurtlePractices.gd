# Unit tests for DrawingTurtle to verify multiple solution approaches
# for turtle-based practices work correctly.
#
# These tests ensure that both position-setting and jump() approaches
# produce equivalent results for Lesson 7 Practice 2 and similar exercises.
#
# Run this test by loading the scene or calling run_all_tests().
extends Node

# In Godot 4, preloading scripts works the same way
const DrawingTurtleScript := preload("res://course/common/turtle/DrawingTurtle.gd")

var _tests_run: int = 0
var _tests_passed: int = 0
var _tests_failed: int = 0
var _failure_messages: Array[String] = [] # Typed arrays are preferred in Godot 4


func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("DrawingTurtle Practice Tests")
	print("=".repeat(60) + "\n")

	run_all_tests()

	print("\n" + "=".repeat(60))
	print("Results: %d passed, %d failed out of %d tests" % [_tests_passed, _tests_failed, _tests_run])
	print("=".repeat(60))

	if _failure_messages.size() > 0:
		print("\nFailures:")
		for msg in _failure_messages:
			print("  - %s" % msg)
		print("")

	if _tests_failed == 0:
		print("\nOK - All DrawingTurtle tests passed!\n")
		get_tree().quit(0)
	else:
		print("\nFAIL - Some tests failed\n")
		get_tree().quit(1)


func run_all_tests() -> void:
	# Lesson 7 Practice 2 - Drawing multiple rectangles
	_test_lesson7_practice2_position_solution()
	_test_lesson7_practice2_jump_solution()
	_test_lesson7_practice2_mixed_solution()

	# Edge case tests
	_test_position_change_closes_polygon()
	_test_jump_after_position_change()
	_test_multiple_position_changes_before_drawing()
	_test_polygon_points_are_normalized()

	# Regression tests for previously reported bugs
	_test_position_and_jump_mix_does_not_leave_unclosed_shapes()

# =============================================================================
# Lesson 7 Practice 2: Draw three 100x100 squares at (100,100), (300,100), (500,100)
# =============================================================================


func _test_lesson7_practice2_position_solution() -> void:
	var turtle := _create_turtle()

	turtle.position.x = 100
	turtle.position.y = 100
	_draw_rectangle(turtle, 100, 100)

	turtle.position.x = 300
	_draw_rectangle(turtle, 100, 100)

	turtle.position.x = 500
	_draw_rectangle(turtle, 100, 100)

	var polygons = turtle.get_polygons()

	_assert_equals(3, polygons.size(), "Position solution: Should draw 3 polygons")
	_assert_polygon_at_position(polygons[0], Vector2(100, 100), "Position solution: First square at (100, 100)")
	_assert_polygon_at_position(polygons[1], Vector2(300, 100), "Position solution: Second square at (300, 100)")
	_assert_polygon_at_position(polygons[2], Vector2(500, 100), "Position solution: Third square at (500, 100)")
	_assert_polygon_is_100x100_square(polygons[0], "Position solution: First polygon is 100x100")
	_assert_polygon_is_100x100_square(polygons[1], "Position solution: Second polygon is 100x100")
	_assert_polygon_is_100x100_square(polygons[2], "Position solution: Third polygon is 100x100")

	turtle.queue_free()


func _test_lesson7_practice2_jump_solution() -> void:
	var turtle := _create_turtle()

	turtle.position.x = 100
	turtle.position.y = 100
	_draw_rectangle(turtle, 100, 100)

	turtle.jump(200, 0)
	_draw_rectangle(turtle, 100, 100)

	turtle.jump(200, 0)
	_draw_rectangle(turtle, 100, 100)

	var polygons = turtle.get_polygons()

	_assert_equals(3, polygons.size(), "Jump solution: Should draw 3 polygons")
	_assert_polygon_at_position(polygons[0], Vector2(100, 100), "Jump solution: First square at (100, 100)")
	_assert_polygon_at_position(polygons[1], Vector2(300, 100), "Jump solution: Second square at (300, 100)")
	_assert_polygon_at_position(polygons[2], Vector2(500, 100), "Jump solution: Third square at (500, 100)")
	_assert_polygon_is_100x100_square(polygons[0], "Jump solution: First polygon is 100x100")
	_assert_polygon_is_100x100_square(polygons[1], "Jump solution: Second polygon is 100x100")
	_assert_polygon_is_100x100_square(polygons[2], "Jump solution: Third polygon is 100x100")

	turtle.queue_free()


func _test_lesson7_practice2_mixed_solution() -> void:
	var turtle := _create_turtle()

	turtle.position.x = 100
	turtle.position.y = 100
	_draw_rectangle(turtle, 100, 100)

	turtle.position.x = 300
	_draw_rectangle(turtle, 100, 100)

	turtle.jump(200, 0)
	_draw_rectangle(turtle, 100, 100)

	var polygons = turtle.get_polygons()

	_assert_equals(3, polygons.size(), "Mixed solution: Should draw 3 polygons")
	_assert_polygon_at_position(polygons[0], Vector2(100, 100), "Mixed solution: First square at (100, 100)")
	_assert_polygon_at_position(polygons[1], Vector2(300, 100), "Mixed solution: Second square at (300, 100)")
	_assert_polygon_at_position(polygons[2], Vector2(500, 100), "Mixed solution: Third square at (500, 100)")

	turtle.queue_free()

# =============================================================================
# Edge Case Tests
# =============================================================================


func _test_position_change_closes_polygon() -> void:
	var turtle := _create_turtle()

	turtle.position = Vector2(50, 50)
	turtle.move_forward(100)
	turtle.turn_right(90)
	turtle.move_forward(50)
	
	turtle.position = Vector2(200, 200)
	turtle.move_forward(30)

	var polygons = turtle.get_polygons()

	_assert_true(polygons.size() >= 1, "Position change closes polygon: At least 1 polygon created")
	_assert_polygon_at_position(polygons[0], Vector2(50, 50), "Position change closes polygon: First at (50, 50)")

	turtle.queue_free()


func _test_jump_after_position_change() -> void:
	var turtle := _create_turtle()

	turtle.position = Vector2(100, 100)
	_draw_rectangle(turtle, 50, 50)

	turtle.jump(100, 0)
	_draw_rectangle(turtle, 50, 50)

	var polygons = turtle.get_polygons()

	_assert_equals(2, polygons.size(), "Jump after position change: Should draw 2 polygons")
	_assert_polygon_at_position(polygons[0], Vector2(100, 100), "Jump after position: First at (100, 100)")
	_assert_polygon_at_position(polygons[1], Vector2(200, 100), "Jump after position: Second at (200, 100)")

	turtle.queue_free()


func _test_multiple_position_changes_before_drawing() -> void:
	var turtle := _create_turtle()

	turtle.position.x = 50
	turtle.position.y = 50
	turtle.position.x = 100
	turtle.position.y = 100
	_draw_rectangle(turtle, 50, 50)

	var polygons = turtle.get_polygons()

	_assert_equals(1, polygons.size(), "Multiple position changes: Should only draw 1 polygon")
	_assert_polygon_at_position(polygons[0], Vector2(100, 100), "Multiple position changes: Rectangle at final position")

	turtle.queue_free()


func _test_polygon_points_are_normalized() -> void:
	var turtle := _create_turtle()

	turtle.position = Vector2(150, 75)
	_draw_rectangle(turtle, 100, 100)

	var polygons = turtle.get_polygons()

	_assert_equals(1, polygons.size(), "Normalized points: Should have 1 polygon")

	# In Godot 4, PoolVector2Array is replaced by PackedVector2Array
	var points: PackedVector2Array = polygons[0].points
	var has_origin := false
	for p in points:
		if p.is_equal_approx(Vector2.ZERO):
			has_origin = true
			break

	_assert_true(has_origin, "Normalized points: Points should include (0, 0) origin")

	turtle.queue_free()


func _test_position_and_jump_mix_does_not_leave_unclosed_shapes() -> void:
	var turtle := _create_turtle()

	turtle.position.x = 100
	turtle.position.y = 100
	_draw_rectangle(turtle, 100, 100)

	turtle.jump(200, 0)
	_draw_rectangle(turtle, 100, 100)

	turtle.position.x = 600
	_draw_rectangle(turtle, 100, 100)

	var polygons = turtle.get_polygons()

	_assert_equals(3, polygons.size(), "Mix regression: Should draw exactly 3 complete polygons")

	for i in range(polygons.size()):
		var points: PackedVector2Array = polygons[i].points
		_assert_true(
			points.size() == 5,
			"Mix regression: Polygon %d should have 5 points (closed)" % (i + 1)
		)
		_assert_true(
			points[0].is_equal_approx(points[4]),
			"Mix regression: Polygon %d should be closed" % (i + 1)
		)

	turtle.queue_free()

# =============================================================================
# Helper Functions
# =============================================================================


func _create_turtle() -> Node2D:
	var turtle = DrawingTurtleScript.new()
	add_child(turtle)
	return turtle


func _draw_rectangle(turtle: Node2D, length: float, height: float) -> void:
	# Note: If DrawingTurtle uses methods like move_forward, ensure they are 
	# defined in DrawingTurtle.gd.
	turtle.call("move_forward", length)
	turtle.call("turn_right", 90)
	turtle.call("move_forward", height)
	turtle.call("turn_right", 90)
	turtle.call("move_forward", length)
	turtle.call("turn_right", 90)
	turtle.call("move_forward", height)
	turtle.call("turn_right", 90)
	# Using call if the method is intended to be internal or dynamically accessed
	if turtle.has_method("_close_polygon"):
		turtle.call("_close_polygon")


func _assert_equals(expected, actual, message: String) -> void:
	_tests_run += 1
	if expected == actual:
		_tests_passed += 1
		print("  PASS: %s" % message)
	else:
		_tests_failed += 1
		_failure_messages.append("%s (expected %s, got %s)" % [message, expected, actual])
		print("  FAIL: %s (expected %s, got %s)" % [message, expected, actual])


func _assert_true(condition: bool, message: String) -> void:
	_tests_run += 1
	if condition:
		_tests_passed += 1
		print("  PASS: %s" % message)
	else:
		_tests_failed += 1
		_failure_messages.append(message)
		print("  FAIL: %s" % message)


func _assert_polygon_at_position(polygon, expected_position: Vector2, message: String) -> void:
	_tests_run += 1
	if polygon.position.is_equal_approx(expected_position):
		_tests_passed += 1
		print("  PASS: %s" % message)
	else:
		_tests_failed += 1
		_failure_messages.append("%s (got position %s)" % [message, polygon.position])
		print("  FAIL: %s (got position %s)" % [message, polygon.position])


func _assert_polygon_is_100x100_square(polygon, message: String) -> void:
	var expected_rect: Array[Vector2] = [
		Vector2(0, 0),
		Vector2(100, 0),
		Vector2(100, 100),
		Vector2(0, 100),
		Vector2(0, 0),
	]
	expected_rect.sort()

	# Convert PackedVector2Array to Array[Vector2] for easier sorting/comparison
	var actual_points: Array[Vector2] = []
	for p in polygon.points:
		actual_points.append(p)
	actual_points.sort()

	_tests_run += 1
	if actual_points == expected_rect:
		_tests_passed += 1
		print("  PASS: %s" % message)
	else:
		_tests_failed += 1
		_failure_messages.append("%s (points don't match 100x100 square)" % message)
		print("  FAIL: %s (points don't match 100x100 square)" % message)
