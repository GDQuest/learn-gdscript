extends ColorRect

const PracticeButtonScene := preload("res://ui/screens/lesson/UIPracticeButton.tscn")

onready var _practice_items := $PanelContainer/Column/Margin/Column/PracticeList/Items as Control
onready var _cancel_button := $PanelContainer/Column/Margin/Column/Buttons/CancelButton as Button


func _ready() -> void:
	set_as_toplevel(true)

	Events.connect("practice_requested", self, "_on_practice_requested")
	_cancel_button.connect("pressed", self, "hide")
	connect("visibility_changed", self, "_on_visibility_changed")



func _on_visibility_changed() -> void:
	if visible:
		_cancel_button.grab_focus()


func clear_items() -> void:
	for child_node in _practice_items.get_children():
		_practice_items.remove_child(child_node)
		child_node.queue_free()


func add_item(practice: BBCodeParser.ParseNode, lesson: BBCodeParser.ParseNode, course_index: CourseIndex, current: bool = false) -> void:
	var button: UIPracticeButton = PracticeButtonScene.instance()
	var practice_id := BBCodeUtils.get_practice_id(practice)
	var practice_index := -1
	var practice_count := BBCodeUtils.get_lesson_practice_count(lesson)
	for i in practice_count:
		var other_practice := BBCodeUtils.get_lesson_practice(lesson, i)
		var other_practice_id := BBCodeUtils.get_practice_id(other_practice)
		if other_practice_id == practice_id:
			practice_index = i
			break
	button.setup(practice, practice_index)

	if course_index:
		var user_profile := UserProfiles.get_profile()
		button.completed_before = user_profile.is_lesson_practice_completed(course_index.get_course_id(), lesson.bbcode_path, practice_id)

	if current:
		button.navigation_disabled = true

	_practice_items.add_child(button)


func _on_practice_requested(_practice: BBCodeParser.ParseNode) -> void:
	hide()
