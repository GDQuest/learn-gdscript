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
		if not NavigationManager.current_url.is_empty():
			var target := NavigationManager.get_navigation_resource(NavigationManager.current_url)
			if target:
				_last_target = target
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
		var lesson_info := _last_course_index.get_lesson_info(lesson.bbcode_path)
		var node_text := "L%d. %s" % [lesson_info.number, tr(lesson_info.title)]

		_create_navigation_node(node_text, null, "", true)
		return

	elif _last_target is BBCodeParser.ParseNode and _last_target.tag == BBCodeParserData.Tag.PRACTICE:
		var practice := _last_target as BBCodeParser.ParseNode
		var practice_id := BBCodeUtils.get_practice_id(practice)
		var lesson_info := _last_course_index.get_lesson_info(practice.bbcode_path)
		var practice_info := _last_course_index.get_practice_info(practice.bbcode_path, practice_id)

		var lesson_text := "L%d. %s" % [lesson_info.number, tr(lesson_info.title)]
		_create_navigation_node(lesson_text, _last_course_index, lesson_info.path)

		var node_text := "P%d. %s" % [practice_info.index + 1, tr(practice_info.title)]
		_create_navigation_node(node_text, null, "", true)
		return


func _clear_navigation_nodes() -> void:
	for child_node in get_children():
		remove_child(child_node)
		child_node.queue_free()


func _create_navigation_node(text: String, course_index: CourseIndex, path := "", current: bool = false) -> void:
	if get_child_count() > 0:
		var separator := Label.new()
		separator.text = " > "
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
