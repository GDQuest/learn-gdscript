extends PanelContainer

signal transition_completed

export (Resource) var course = preload("res://course/course-learn-gdscript.tres")

# If `true`, play transition animations.
var use_transitions := true

var _screens_stack := []
# Maps url strings to resource paths.
var _matches := {}
var _breadcrumbs: PoolStringArray
# Used for transition animations.

var _lesson_index := 0 setget _set_lesson_index
var _lesson_count: int = course.lessons.size()

onready var _back_button := $VBoxContainer/Buttons/MarginContainer/HBoxContainer/BackButton as Button
onready var _label := $VBoxContainer/Buttons/MarginContainer/HBoxContainer/BreadCrumbs as Label
onready var _settings_button := (
	$VBoxContainer/Buttons/MarginContainer/HBoxContainer/SettingsButton as Button
)
onready var _report_button := (
	$VBoxContainer/Buttons/MarginContainer/HBoxContainer/ReportButton as Button
)

onready var _screen_container := $VBoxContainer/PanelContainer as Container
onready var _tween := $Tween as Tween


func _ready() -> void:
	NavigationManager.connect("back_navigation_requested", self, "_back")
	NavigationManager.connect("navigation_requested", self, "_navigate_to")
	
	#Events.connect("lesson_end_popup_closed", Navigation, "back")
	#Events.connect("lesson_start_requested", Navigation, "_navigate_to")
	#Events.connect("practice_start_requested", self, "_navigate_to")
	Events.connect("practice_completed", self, "_on_Events_practice_completed")

	_back_button.connect("pressed", NavigationManager, "back")
	_settings_button.connect("pressed", Events, "emit_signal", ["settings_requested"])
	_report_button.connect("pressed", Events, "emit_signal", ["report_form_requested"])

	if NavigationManager.current_url == "":
		NavigationManager.navigate_to(course.lessons[0].resource_path)
	else:
		_navigate_to()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("ui_back"):
		NavigationManager.back()


# Pops the last screen from the stack
func _back() -> void:
	if _screens_stack.size() < 2:
		print("TODO: return to main screen?")
		return

	_breadcrumbs.remove(_breadcrumbs.size() - 1)

	var current_screen: Control = _screens_stack.pop_back()
	var next_screen: Control = _screens_stack.back()
	_transition_to(next_screen, current_screen, false)
	yield(self, "transition_completed")
	current_screen.queue_free()

func _navigate_to() -> void:
	var current_resource_path = NavigationManager.current_url
	var target: Resource = load(current_resource_path)
	var screen: Control
	if target is Practice:
		screen = preload("UIPractice.tscn").instance()
	elif target is Lesson:
		screen = preload("UILesson.tscn").instance()
	else:
		printerr("Trying to navigate to unsupported resource type: %s" % target.get_class())
		return

	# warning-ignore:unsafe_method_access
	screen.setup(target)

	# warning-ignore:unsafe_property_access
	# warning-ignore:unsafe_property_access
	_breadcrumbs.push_back(target.title)
	_label.text = _breadcrumbs.join("/")

	var has_previous_screen = not _screens_stack.empty()
	_screens_stack.push_back(screen)
	_screen_container.add_child(screen)
	if has_previous_screen:
		var previous_screen: Control = _screens_stack[-2]
		_transition_to(screen, previous_screen)
		yield(self, "transition_completed")

	# Connect to RichTextLabel meta links to navigate to different scenes.
	for node in get_tree().get_nodes_in_group("rich_text_label"):
		assert(node is RichTextLabel)
		if (
			node.bbcode_enabled
			and not node.is_connected("meta_clicked", self, "_on_RichTextLabel_meta_clicked")
		):
			node.connect("meta_clicked", self, "_on_RichTextLabel_meta_clicked")


# Transitions a screen in. This is there as a placeholder, we probably want
# something prettier.
#
# Anything can go in there, as long as "transition_in_completed" or
# "transition_out_completed" are emitted at the end.
func _transition_to(screen: Control, previous_screen: Control = null, direction_in := true) -> void:
	if not use_transitions:
		previous_screen.hide()
		screen.show()
		yield(get_tree(), "idle_frame")
		emit_signal("transition_completed")
		return

	screen.show()
	previous_screen.show()
	var viewport_width := get_viewport().size.x
	var direction := 1.0 if direction_in else -1.0
	screen.rect_position.x = viewport_width * direction
	_tween.interpolate_property(
		screen,
		"rect_position:x",
		screen.rect_position.x,
		0.0,
		1.2,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	)
	if previous_screen:
		_tween.interpolate_property(
			previous_screen,
			"rect_position:x",
			previous_screen.rect_position.x,
			-viewport_width * direction,
			1.2,
			Tween.TRANS_CUBIC,
			Tween.EASE_OUT
		)
	_tween.start()
	yield(_tween, "tween_all_completed")
	previous_screen.hide()
	emit_signal("transition_completed")


func _on_Events_practice_completed(practice: Practice) -> void:
	var practices: Array = course.lessons[_lesson_index].practices
	var index := practices.find(practice)
	var is_last_practice := practices.size() - 1 <= index
	if is_last_practice:
		_set_lesson_index(_lesson_index + 1)
	else:
		NavigationManager.navigate_to(practices[index + 1].resource_path)


func _set_lesson_index(index: int) -> void:
	_lesson_index = index
	if _lesson_index == _lesson_count:
		# TODO: figure out some screen at the end of the course
		print("You reached the end of the course!")
	else:
		_clear_history_stack()
		NavigationManager.navigate_to(course.lessons[index].resource_path)

		
func _clear_history_stack() -> void:
	for child in _screen_container.get_children():
			child.queue_free()
	_screens_stack.clear()
	_breadcrumbs = PoolStringArray()
