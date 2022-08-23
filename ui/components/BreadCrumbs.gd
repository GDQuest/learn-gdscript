extends HBoxContainer

const NODE_FONT := preload("res://ui/theme/fonts/font_text.tres")
const NODE_FONT_CURRENT := preload("res://ui/theme/fonts/font_text_bold.tres")
const NODE_COLOR := Color(0.572549, 0.560784, 0.721569)


var _last_course: Course
var _last_target: Resource


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		yield(get_tree(), "idle_frame")
		_rebuild_breadcrumbs()


func update_breadcrumbs(course: Course, target: Resource) -> void:
	_last_course = course
	_last_target = target
	
	_rebuild_breadcrumbs()


func _rebuild_breadcrumbs() -> void:
	if not _last_course or not _last_target:
		return
	
	_clear_navigation_nodes()

	if _last_target is Lesson:
		var lesson = _last_target as Lesson
		var lesson_index := -1

		var i := 0
		for lesson_data in _last_course.lessons:
			if lesson_data == lesson:
				lesson_index = i
				break

			i += 1

		var node_text: String = tr(lesson.title)
		if lesson_index >= 0:
			node_text = "%s. %s" % [lesson_index + 1, tr(lesson.title)]

		_create_navigation_node(node_text, "", true)
		return

	if _last_target is Practice:
		var practice = _last_target as Practice
		# TODO: Should probably avoid relying on content ID for getting paths.
		var lesson_path = practice.practice_id.get_base_dir().plus_file("lesson.tres")

		var lesson: Lesson
		var lesson_index := -1

		var i := 0
		for lesson_data in _last_course.lessons:
			if lesson_data.resource_path == lesson_path:
				lesson = lesson_data
				lesson_index = i
				break

			i += 1

		if lesson and lesson_index >= 0:
			var lesson_text := "%d. %s" % [lesson_index + 1, tr(lesson.title)]
			_create_navigation_node(lesson_text, lesson.resource_path)

		var practice_index: int = (
			lesson.get_practice_index(practice.practice_id)
		)
		var node_text: String = "%d. %s" % [practice_index + 1, tr(practice.title)]
		_create_navigation_node(node_text, "", true)
		return


func _clear_navigation_nodes() -> void:
	for child_node in get_children():
		remove_child(child_node)
		child_node.queue_free()


func _create_navigation_node(text: String, path: String = "", current: bool = false) -> void:
	if get_child_count() > 0:
		var separator := Label.new()
		separator.text = "•"
		separator.add_font_override("font", NODE_FONT)
		separator.add_color_override("font_color", NODE_COLOR)
		add_child(separator)

	if path.empty():
		var navigation_node := Label.new()
		navigation_node.text = text
		navigation_node.add_font_override("font", NODE_FONT_CURRENT if current else NODE_FONT)
		navigation_node.add_color_override("font_color", NODE_COLOR)
		add_child(navigation_node)
	else:
		var navigation_node := Button.new()
		navigation_node.flat = true
		navigation_node.text = text
		navigation_node.add_font_override("font", NODE_FONT_CURRENT if current else NODE_FONT)
		navigation_node.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		add_child(navigation_node)
		navigation_node.connect("pressed", self, "_on_navigation_pressed", [ path ])


func _on_navigation_pressed(path: String) -> void:
	if path.empty():
		return

	NavigationManager.navigate_to(path)
