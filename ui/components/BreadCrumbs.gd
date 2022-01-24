extends HBoxContainer

const NODE_FONT := preload("res://ui/theme/fonts/font_text.tres")
const NODE_FONT_CURRENT := preload("res://ui/theme/fonts/font_text_bold.tres")
const NODE_COLOR := Color(0.572549, 0.560784, 0.721569)

const BUTTON_NORMAL := preload("res://ui/theme/button_navigation_normal.tres")
const BUTTON_PRESSED := preload("res://ui/theme/button_navigation_pressed.tres")
const BUTTON_HOVER := preload("res://ui/theme/button_navigation_hover.tres")
const BUTTON_DISABLED := preload("res://ui/theme/button_navigation_disabled.tres")


func update_breadcrumbs(course: Course, target: Resource) -> void:
	_clear_navigation_nodes()
	
	if target is Lesson:
		var lesson = target as Lesson
		var lesson_index := -1
		
		var i := 0
		for lesson_data in course.lessons:
			if lesson_data == lesson:
				lesson_index = i
				break
			
			i += 1
		
		var node_text: String = lesson.title
		if lesson_index >= 0:
			node_text = "%s. %s" % [lesson_index + 1, lesson.title]
		
		_create_navigation_node(node_text, "", true)
		return
	
	if target is Practice:
		var practice = target as Practice
		var lesson_path = practice.resource_path.get_base_dir().plus_file("lesson.tres")
		
		var lesson: Lesson
		var lesson_index := -1
		
		var i := 0
		for lesson_data in course.lessons:
			if lesson_data.resource_path == lesson_path:
				lesson = lesson_data
				lesson_index = i
				break
			
			i += 1
		
		if lesson and lesson_index >= 0:
			var lesson_text := "%s. %s" % [lesson_index + 1, lesson.title]
			_create_navigation_node(lesson_text, lesson.resource_path)

		var node_text: String = practice.title
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
		navigation_node.add_stylebox_override("normal", BUTTON_NORMAL)
		add_child(navigation_node)
	else:
		var navigation_node := Button.new()
		navigation_node.flat = true
		navigation_node.text = text
		navigation_node.add_font_override("font", NODE_FONT_CURRENT if current else NODE_FONT)
		navigation_node.add_stylebox_override("normal", BUTTON_NORMAL)
		navigation_node.add_stylebox_override("pressed", BUTTON_PRESSED)
		navigation_node.add_stylebox_override("hover", BUTTON_HOVER)
		navigation_node.add_stylebox_override("disabled", BUTTON_DISABLED)
		add_child(navigation_node)
		navigation_node.connect("pressed", self, "_on_navigation_pressed", [ path ])


func _on_navigation_pressed(path: String) -> void:
	if path.empty():
		return
	
	NavigationManager.navigate_to(path)
