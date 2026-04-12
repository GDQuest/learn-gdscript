extends ColorRect

const PracticeButtonScene := preload("res://ui/screens/lesson/UIPracticeButton.tscn")

@onready var _practice_items := $PanelContainer/Column/Margin/Column/PracticeList/Items as Control
@onready var _cancel_button := $PanelContainer/Column/Margin/Column/Buttons/CancelButton as Button


func _ready() -> void:
	set_as_top_level(true)

	Events.practice_requested.connect(_on_practice_requested)
	_cancel_button.pressed.connect(hide)
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		_cancel_button.grab_focus()


func clear_items() -> void:
	for child_node in _practice_items.get_children():
		_practice_items.remove_child(child_node)
		child_node.queue_free()


func add_item(practice: BBCodeParser.ParseNode, lesson: BBCodeParser.ParseNode, course_index: CourseIndex, lesson_number: int, current: bool = false) -> void:
	var button: UIPracticeButton = PracticeButtonScene.instantiate()
	button.setup(practice, BBCodeUtils.get_practice_index(lesson, practice), lesson_number)

	if course_index:
		var user_profile := UserProfiles.get_profile()
		button.completed_before = user_profile.is_lesson_practice_completed(course_index.get_course_id(), lesson.bbcode_path, BBCodeUtils.get_practice_id(practice))

	if current:
		button.navigation_disabled = true

	_practice_items.add_child(button)


func _on_practice_requested(_practice: BBCodeParser.ParseNode) -> void:
	hide()
