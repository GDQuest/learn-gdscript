extends HBoxContainer

const NODE_FONT := preload("res://ui/theme/fonts/font_text.tres")
const NODE_FONT_CURRENT := preload("res://ui/theme/fonts/font_text_bold.tres")
const NODE_FONT_SIZE := 20
const NODE_COLOR := Color(0.572549, 0.560784, 0.721569)

var _last_course_index: CourseIndex
var _last_target: BBCodeParser.ParseNode


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		await get_tree().process_frame
		_rebuild_breadcrumbs()


func update_breadcrumbs(course_index: CourseIndex, target: BBCodeParser.ParseNode) -> void:
	_last_course_index = course_index
	_last_target = target

	_rebuild_breadcrumbs()


func _rebuild_breadcrumbs() -> void:
	_clear_navigation_nodes()
	
	if not _last_course_index or not _last_target:
		return

	if _last_target is BBCodeParser.ParseNode and _last_target.tag == BBCodeParserData.Tag.LESSON:
		var lesson := _last_target as BBCodeParser.ParseNode
		var lesson_index := -1

		var i := 0
		for l in _last_course_index.get_lessons_count():
			var lesson_data := NavigationManager.get_navigation_resource(_last_course_index.get_lesson_path(l)) as BBCodeParser.ParseNode
			if lesson_data == lesson:
				lesson_index = i
				break

			i += 1

		var title := BBCodeUtils.get_lesson_title(lesson)
		var node_text: String = tr(title)
		if lesson_index >= 0:
			node_text = "%s. %s" % [lesson_index + 1, tr(title)]

		_create_navigation_node(node_text, null, "", true)
		return

	elif _last_target is BBCodeParser.ParseNode and _last_target.tag == BBCodeParserData.Tag.PRACTICE:
		var practice := _last_target as BBCodeParser.ParseNode
		# TODO: Should probably avoid relying on content ID for getting paths.
		
		var practice_id := BBCodeUtils.get_practice_id(practice)

		var lesson: BBCodeParser.ParseNode = practice.parent
		var lesson_index := -1

		var i := 0
		for l in _last_course_index.get_lessons_count():
			var lesson_data := NavigationManager.get_navigation_resource(_last_course_index.get_lesson_path(l)) as BBCodeParser.ParseNode
			if lesson_data.bbcode_path == lesson.bbcode_path:
				lesson_index = i
				break

			i += 1

		if lesson and lesson_index >= 0:
			var title := BBCodeUtils.get_lesson_title(lesson)
			var lesson_text := "%d. %s" % [lesson_index + 1, tr(title)]
			_create_navigation_node(lesson_text, _last_course_index, lesson.bbcode_path)

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
			_create_navigation_node(node_text, null, "", true)
		return


func _clear_navigation_nodes() -> void:
	for child_node in get_children():
		remove_child(child_node)
		child_node.queue_free()


func _create_navigation_node(text: String, course_index: CourseIndex, path: String = "", current: bool = false) -> void:
	if get_child_count() > 0:
		var separator := Label.new()
		separator.text = "•"
		separator.add_theme_font_override("font", NODE_FONT)
		separator.add_theme_font_size_override("font_size", NODE_FONT_SIZE)
		separator.add_theme_color_override("font_color", NODE_COLOR)
		add_child(separator)

	if path.is_empty():
		var navigation_node := Label.new()
		navigation_node.text = text
		navigation_node.add_theme_font_override("font", NODE_FONT_CURRENT if current else NODE_FONT)
		navigation_node.add_theme_font_size_override("font_size", NODE_FONT_SIZE)
		navigation_node.add_theme_color_override("font_color", NODE_COLOR)
		add_child(navigation_node)
	else:
		var navigation_node := Button.new()
		navigation_node.flat = true
		navigation_node.text = text
		navigation_node.add_theme_font_override("font", NODE_FONT_CURRENT if current else NODE_FONT)
		navigation_node.add_theme_font_size_override("font_size", NODE_FONT_SIZE)
		navigation_node.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		add_child(navigation_node)
		var slug := "%s" % [course_index.get_lesson_slug_from_path(path)]
		navigation_node.pressed.connect(_on_navigation_pressed.bind(slug))


func _on_navigation_pressed(path: String) -> void:
	if path.is_empty():
		return

	NavigationManager.navigate_to(path)
