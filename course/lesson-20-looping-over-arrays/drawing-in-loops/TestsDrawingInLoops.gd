extends PracticeTester

var expected_rects := [
	[Vector2(0, 0), Vector2(200, 0), Vector2(200, 120), Vector2(0, 120), Vector2(0, 0)],
	[Vector2(0, 0), Vector2(140, 0), Vector2(140, 80), Vector2(0, 80), Vector2(0, 0)],
	[Vector2(0, 0), Vector2(80, 0), Vector2(80, 140), Vector2(0, 140), Vector2(0, 0)],
	[Vector2(0, 0), Vector2(200, 0), Vector2(200, 140), Vector2(0, 140), Vector2(0, 0)],
]

var polygons := []
var points := []
var count := -1

# We sort vertices for accurate comparison
func _init() -> void:
	for rect in expected_rects:
		rect.sort()


func _prepare() -> void:
	var turtle: DrawingTurtle = _scene_root_viewport.get_child(0)
	polygons = turtle.get_polygons()
	if polygons.back().is_empty():
		polygons.pop_back()
	for p in polygons:
		var p_points = Array(p.points)
		p_points.sort()
		points.append(p_points)
	count = polygons.size()


func test_rectangles_have_the_correct_size() -> String:
	if count != expected_rects.size():
		return tr("We expected 4 polygons, but you drew %s instead.") % count

	for index in count:
		if expected_rects[index] != points[index]:
			return tr("At least one of the rectangles does not have the expected size.")
	return ""


func test_rectangles_do_not_overlap() -> String:
	var last_polygon = polygons.front()
	var index := 0

	while index < count - 1:
		index += 1
		if last_polygon.get_positioned_rect().intersects(polygons[index].get_positioned_rect()):
			return tr("At least two drawn shape intersect. Did you pass arguments big enough to ")
		last_polygon = polygons[index]
	return ""
