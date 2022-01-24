class_name UINavigator
extends PanelContainer

signal transition_completed
signal return_to_welcome_screen_requested

const CourseOutliner := preload("./screens/course_outliner/CourseOutliner.gd")
const BreadCrumbs := preload("./components/BreadCrumbs.gd")

const SCREEN_TRANSITION_DURATION := 0.75
const OUTLINER_TRANSITION_DURATION := 0.5

var course: Course

# If `true`, play transition animations.
var use_transitions := true
# If `true`, the initial load is forced to go to the outliner (provided default URL).
var load_into_outliner := false

var _screens_stack := []
# Maps url strings to resource paths.
var _matches := {}

var _lesson_index := 0
var _lesson_count: int = 0

onready var _home_button := $Layout/Header/MarginContainer/HeaderContent/HomeButton as Button
onready var _outliner_button := $Layout/Header/MarginContainer/HeaderContent/OutlinerButton as Button
onready var _back_button := $Layout/Header/MarginContainer/HeaderContent/BackButton as Button
onready var _breadcrumbs := $Layout/Header/MarginContainer/HeaderContent/BreadCrumbs as BreadCrumbs
onready var _settings_button := $Layout/Header/MarginContainer/HeaderContent/SettingsButton as Button
onready var _report_button := $Layout/Header/MarginContainer/HeaderContent/ReportButton as Button

onready var _screen_container := $Layout/Content/ScreenContainer as Container
onready var _course_outliner := $Layout/Content/CourseOutliner as CourseOutliner
onready var _tween := $Tween as Tween


func _ready() -> void:
	_lesson_count = course.lessons.size()
	_course_outliner.course = course

	NavigationManager.connect("navigation_requested", self, "_navigate_to")
	NavigationManager.connect("back_navigation_requested", self, "_navigate_back")
	NavigationManager.connect("outliner_navigation_requested", self, "_navigate_to_outliner")

	Events.connect("practice_navigated_next", self, "_on_practice_navigated_next")

	_outliner_button.connect("pressed", NavigationManager, "navigate_to_outliner")
	_back_button.connect("pressed", NavigationManager, "navigate_back")
	_home_button.connect("pressed", NavigationManager, "navigate_to_welcome_screen")

	_settings_button.connect("pressed", Events, "emit_signal", ["settings_requested"])
	_report_button.connect("pressed", Events, "emit_signal", ["report_form_requested"])

	if NavigationManager.current_url == "":
		if load_into_outliner:
			NavigationManager.navigate_to_outliner()
		else:
			if _lesson_index < 0 or _lesson_index >= course.lessons.size():
				_lesson_index = 0
			NavigationManager.navigate_to(course.lessons[_lesson_index].resource_path)
	else:
		_navigate_to()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("ui_back"):
		NavigationManager.navigate_back()


func set_start_from_lesson(lesson_id: String) -> void:
	if not course:
		return

	var matched_index := 0
	for lesson in course.lessons:
		if lesson.resource_path == lesson_id:
			_lesson_index = matched_index
			break

		matched_index += 1


# Pops the last screen from the stack.
func _navigate_back() -> void:
	# Nothing to go back to, open the outliner.
	if _screens_stack.size() < 2:
		_navigate_to_outliner()
		return

	var current_screen: Control = _screens_stack.pop_back()
	var next_screen: Control = _screens_stack.back()
	_back_button.disabled = _screens_stack.size() < 2

	var target = next_screen.get_screen_resource()
	_breadcrumbs.update_breadcrumbs(course, target)

	_transition_to(next_screen, current_screen, false)
	yield(self, "transition_completed")
	current_screen.queue_free()


# Opens the course outliner and flushes the screen stack.
func _navigate_to_outliner() -> void:
	_course_outliner.modulate.a = 0.0
	_course_outliner.show()

	_outliner_button.hide()
	_back_button.hide()
	_back_button.disabled = true
	_home_button.show()
	_clear_history_stack()

	_tween.stop_all()
	_animate_outliner(true)
	_tween.start()
	yield(_tween, "tween_all_completed")

	_screen_container.hide()


# Navigates forward to the next screen and adds it to the stack.
func _navigate_to() -> void:
	var current_resource_path = NavigationManager.current_url
	var target: Resource = load(current_resource_path)

	var screen: Control
	if target is Practice:
		var practice := target as Practice
		screen = preload("UIPractice.tscn").instance()
	elif target is Lesson:
		var lesson := target as Lesson
		screen = preload("UILesson.tscn").instance()
		
		_lesson_index = course.lessons.find(lesson) # Make sure the index is synced after navigation.
	else:
		printerr("Trying to navigate to unsupported resource type: %s" % target.get_class())
		return

	_outliner_button.show()
	_home_button.hide()
	_screen_container.show()
	# warning-ignore:unsafe_method_access
	screen.setup(target, course)
	_breadcrumbs.update_breadcrumbs(course, target)
	
	var has_previous_screen = not _screens_stack.empty()
	_screens_stack.push_back(screen)
	_back_button.show()
	_back_button.disabled = _screens_stack.size() < 2

	_screen_container.add_child(screen)
	if has_previous_screen:
		var previous_screen: Control = _screens_stack[-2]
		_transition_to(screen, previous_screen)
		yield(self, "transition_completed")

	# Connect to RichTextLabel meta links to navigate to different scenes.
	for node in get_tree().get_nodes_in_group("rich_text_label"):
		assert(node is RichTextLabel)
		NavigationManager.connect_rich_text_node(node)

	if _course_outliner.visible:
		_tween.stop_all()
		_animate_outliner(false)
		_tween.start()
		yield(_tween, "tween_all_completed")

	_course_outliner.hide()

	if target is Practice:
		Events.emit_signal("practice_started", target)
	elif target is Lesson:
		Events.emit_signal("lesson_started", target)


func _on_practice_navigated_next(practice: Practice) -> void:
	var lesson_data := course.lessons[_lesson_index] as Lesson
	var practices: Array = lesson_data.practices

	var index := practices.find(practice)
	# This is the last practice in the set, move to the next lesson.
	if index >= practices.size() - 1:
		yield(get_tree(), "idle_frame") # Allow the rest of practice handlers to sync up.
		_on_lesson_completed(lesson_data)
	else:
		# Otherwise, go to the next practice in the set.
		NavigationManager.navigate_to(practices[index + 1].resource_path)


func _on_lesson_completed(lesson: Lesson) -> void:
	Events.emit_signal("lesson_completed", lesson)

	_lesson_index += 1
	if _lesson_index >= _lesson_count:
		_on_course_completed()
		return

	_clear_history_stack()
	NavigationManager.navigate_to(course.lessons[_lesson_index].resource_path)


func _on_course_completed() -> void:
	Events.emit_signal("course_completed", course)
	queue_free()


# Transitions a screen in.
func _transition_to(screen: Control, from_screen: Control = null, direction_in := true) -> void:
	if not use_transitions:
		if from_screen:
			from_screen.hide()
			_screen_container.remove_child(from_screen)

		if screen.get_parent() == null:
			_screen_container.add_child(screen)
		screen.show()



		yield(get_tree(), "idle_frame")
		emit_signal("transition_completed")
		return

	if screen.get_parent() == null:
		_screen_container.add_child(screen)
	screen.show()

	if from_screen:
		from_screen.show()

	var viewport_width := _screen_container.rect_size.x
	var direction := 1.0 if direction_in else -1.0
	screen.rect_position.x = viewport_width * direction

	_animate_screen(screen, 0.0)
	if from_screen:
		_animate_screen(from_screen, -viewport_width * direction)

	_tween.start()
	yield(_tween, "tween_all_completed")

	if from_screen:
		from_screen.hide()
		_screen_container.remove_child(from_screen)

	emit_signal("transition_completed")


func _animate_screen(screen: Control, to_position: float) -> void:
	_tween.interpolate_property(
		screen,
		"rect_position:x",
		screen.rect_position.x,
		to_position,
		SCREEN_TRANSITION_DURATION,
		Tween.TRANS_CUBIC,
		Tween.EASE_IN_OUT
	)


func _animate_outliner(fade_in: bool) -> void:
	_tween.interpolate_property(
		_course_outliner,
		"modulate:a",
		0.0 if fade_in else 1.0,
		1.0 if fade_in else 0.0,
		OUTLINER_TRANSITION_DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)


func _clear_history_stack() -> void:
	# Remove all screen nodes from the screen container.
	for child_node in _screen_container.get_children():
		_screen_container.remove_child(child_node)
		child_node.queue_free()
	# Screens may be unloaded, so queue them for deletion from the stack as well.
	for screen in _screens_stack:
		screen.queue_free()
	_screens_stack.clear()

	_breadcrumbs.update_breadcrumbs(course, null)
