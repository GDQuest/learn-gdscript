extends HBoxContainer

const NODE_FONT := preload("res://ui/theme/fonts/font_text.tres")
const NODE_FONT_CURRENT := preload("res://ui/theme/fonts/font_text_bold.tres")
const NODE_COLOR := Color(0.572549, 0.560784, 0.721569)


var _last_course_index: CourseIndex
var _last_target: BBCodeParser.ParseNode


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		yield(get_tree(), "idle_frame")
		_rebuild_breadcrumbs()


func update_breadcrumbs(course_index: CourseIndex, target: BBCodeParser.ParseNode) -> void:
	_last_course_index = course_index
	_last_target = target
	
	_rebuild_breadcrumbs()


func _rebuild_breadcrumbs() -> void:
	if not _last_course_index or not _last_target:
		return
	
	_clear_navigation_nodes()

	if _last_target is BBCodeParser.ParseNode and BBCodeUtils.get_node_type(_last_target) == BBCodeParserData.Tag.LESSON:
		var lesson = _last_target as BBCodeParser.ParseNode
		var lesson_index := -1

		var i := 0
		for l in _last_course_index._get_lessons_count():
			var lesson_data := NavigationManager.get_navigation_resource(_last_course_index.get_lesson_path(l)) as BBCodeParser.ParseNode
			if lesson_data == lesson:
				lesson_index = i
				break

			i += 1

		var title := BBCodeUtils.get_lesson_title(lesson)
		var node_text: String = tr(title)
		if lesson_index >= 0:
			node_text = "%s. %s" % [lesson_index + 1, tr(title)]

		_create_navigation_node(node_text, "", true)
		return

	if _last_target is BBCodeParser.ParseNode and BBCodeUtils.get_node_type(_last_target) == BBCodeParserData.Tag.PRACTICE:
		var practice = _last_target as BBCodeParser.ParseNode
		# TODO: Should probably avoid relying on content ID for getting paths.
		var practice_id := BBCodeUtils.get_practice_id(practice)
		var lesson_path = practice_id.get_base_dir().plus_file("lesson.bbcode")

		var lesson: BBCodeParser.ParseNode
		var lesson_index := -1

		var i := 0
		for l in _last_course_index.get_lessons_count():
			var lesson_data := NavigationManager.get_navigation_resource(_last_course_index.get_lesson_path(l)) as BBCodeParser.ParseNode
			if lesson_data.bbcode_path == lesson_path:
				lesson = lesson_data
				lesson_index = i
				break

			i += 1

		if lesson and lesson_index >= 0:
			var title := BBCodeUtils.get_lesson_title(lesson)
			var lesson_text := "%d. %s" % [lesson_index + 1, tr(title)]
			_create_navigation_node(lesson_text, lesson.bbcode_path)

			var practice_count := BBCodeUtils.get_lesson_practice_count(lesson)
			var practice_index := -1
			for l in practice_count:
				var other_practice := BBCodeUtils.get_lesson_practice(lesson, l)
				var other_practice_id := BBCodeUtils.get_practice_id(other_practice)
				if other_practice_id == practice_id:
					practice_index = l
					break
			var practice_title := BBCodeUtils.get_practice_title(practice)
			var node_text: String = "%d. %s" % [practice_index + 1, tr(practice_title)]
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
