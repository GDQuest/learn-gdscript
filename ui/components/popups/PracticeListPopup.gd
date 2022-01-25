extends ColorRect

const PracticeButtonScene := preload("res://ui/screens/lesson/UIPracticeButton.tscn")

onready var _practice_items := $PanelContainer/Column/Margin/Column/PracticeList/Items as Control
onready var _cancel_button := $PanelContainer/Column/Margin/Column/Buttons/CancelButton as Button


func _ready() -> void:
	set_as_toplevel(true)
	
	Events.connect("practice_requested", self, "_on_practice_requested")
	_cancel_button.connect("pressed", self, "hide")


func clear_items() -> void:
	for child_node in _practice_items.get_children():
		_practice_items.remove_child(child_node)
		child_node.queue_free()


func add_item(practice: Practice, lesson: Lesson, course: Course, current: bool = false) -> void:
	var button: UIPracticeButton = PracticeButtonScene.instance()
	button.setup(practice)
	
	if course:
		var user_profile := UserProfiles.get_profile()
		button.completed_before = user_profile.is_lesson_practice_completed(course.resource_path, lesson.resource_path, practice.resource_path)
	
	if current:
		button.navigation_disabled = true
	
	_practice_items.add_child(button)


func _on_practice_requested(_practice: Practice) -> void:
	hide()
