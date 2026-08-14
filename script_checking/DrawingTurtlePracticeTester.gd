@abstract
class_name DrawingTurtlePracticeTester
extends PracticeTester


@abstract func _get_turtle() -> DrawingTurtle


func get_shape_count() -> int:
	return _get_turtle().get_polygons().size()


func shape_has_fewer_than(shape: int, expected_vertex_count: int) -> bool:
	var polygon: DrawingTurtle.Polygon = _get_turtle().get_polygons().get(shape)
	if not polygon:
		return false
	return polygon.get_points().size() < expected_vertex_count


func shape_has_greater_than(shape: int, expected_vertex_count: int) -> bool:
	var polygon: DrawingTurtle.Polygon = _get_turtle().get_polygons().get(shape)
	if not polygon:
		return false
	return polygon.get_points().size() > expected_vertex_count


func shape_has(shape: int, expected_vertex_count: int) -> bool:
	var polygon: DrawingTurtle.Polygon = _get_turtle().get_polygons().get(shape)
	if not polygon:
		return false
	return polygon.get_points().size() == expected_vertex_count


## Compares the points of the provided shape against a set of vertices.
## Both are sorted before comparing
func shape_is(shape: int, expected_vertices: Array) -> bool:
	var polygon: DrawingTurtle.Polygon = _get_turtle().get_polygons().get(shape)
	if not polygon:
		return false
	var points := Array(polygon.get_points()).map(func(point: Vector2) -> Vector2: return point.abs())
	points.sort()
	var sorted_expected_vertices := Array(expected_vertices)
	sorted_expected_vertices.sort()
	return points == sorted_expected_vertices


func shape_count_fewer_than(expected: int) -> bool:
	var shape_count := _get_turtle().get_polygons().size()
	return shape_count < expected


func shape_count_greater_than(expected: int) -> bool:
	var shape_count := _get_turtle().get_polygons().size()
	return shape_count > expected


func shape_count_is(expected: int) -> bool:
	var shape_count := _get_turtle().get_polygons().size()
	return shape_count == expected


func turtle_faces_right() -> bool:
	return is_equal_approx(wrapf(_get_turtle().turn_degrees, 0.0, 360.0), 0.0)
