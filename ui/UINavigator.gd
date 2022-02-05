class_name UINavigator
extends PanelContainer

signal transition_completed
signal return_to_welcome_screen_requested

enum NAVIGATION_REQUEST_TYPE {BACK, OUTLINER, HOME, BREADCRUMBS, NEXT_PRACTICE, PREVIOUS_PRACTICE, TO_PRACTICE}

const CourseOutliner := preload("./screens/course_outliner/CourseOutliner.gd")
const BreadCrumbs := preload("./components/BreadCrumbs.gd")
const LessonDonePopup := preload("./components/popups/LessonDonePopup.gd")
const LeaveUnsavedPracticePopup := preload("./components/popups/LeaveUnsavedPracticePopup.gd")

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

onready var _leave_unsaved_practice_popup := $LeaveUnsavedPracticePopup as LeaveUnsavedPracticePopup
onready var _lesson_done_popup := $LessonDonePopup as LessonDonePopup

onready var _tween := $Tween as Tween


func _ready() -> void:
	_lesson_count = course.lessons.size()
	_course_outliner.course = course

	NavigationManager.connect("navigation_requested", self, "_navigate_to")
	NavigationManager.connect("back_navigation_requested", self, "_navigate_back")
	NavigationManager.connect("outliner_navigation_requested", self, "_navigate_to_outliner")

	Events.connect("practice_next_requested", self, "_on_practice_next_requested")
	Events.connect("practice_previous_requested", self, "_on_user_navigation_request")
	Events.connect("practice_requested", self, "_on_practice_requested")
	Events.connect("breadcrumbs_navigation_requested", self, "_on_breadcrumbs_navigation_requested")

	_leave_unsaved_practice_popup.connect("confirmed", self, "_on_leave_practice_unsaved_confirmed")
	_lesson_done_popup.connect("accepted", self, "_on_lesson_completed")

	_outliner_button.connect("pressed", self, "_on_user_navigation_request", [NAVIGATION_REQUEST_TYPE.OUTLINER])
	_back_button.connect("pressed", self, "_on_user_navigation_request", [NAVIGATION_REQUEST_TYPE.BACK])
	_home_button.connect("pressed", self, "_on_user_navigation_request", [NAVIGATION_REQUEST_TYPE.HOME])

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
		_on_user_navigation_request(NAVIGATION_REQUEST_TYPE.BACK)


func set_start_from_lesson(lesson_id: String) -> void:
	if not course:
		return

	var matched_index := 0
	for lesson in course.lessons:
		if lesson.resource_path == lesson_id:
			_lesson_index = matched_index
			break

		matched_index += 1

func _perform_user_navigation_request(type: int, payload: Array):
	match type:
		NAVIGATION_REQUEST_TYPE.BACK:
			NavigationManager.navigate_back()
		NAVIGATION_REQUEST_TYPE.OUTLINER:
			NavigationManager.navigate_to_outliner()
		NAVIGATION_REQUEST_TYPE.HOME:
			NavigationManager.navigate_to_welcome_screen()
		NAVIGATION_REQUEST_TYPE.NEXT_PRACTICE:
			_navigate_to_practice_next(payload.pop_back())
		NAVIGATION_REQUEST_TYPE.PREVIOUS_PRACTICE:
			_navigate_to_practice_previous(payload.pop_back())
		NAVIGATION_REQUEST_TYPE.TO_PRACTICE:
			_navigate_to_practice(payload.pop_back())
		NAVIGATION_REQUEST_TYPE.BREADCRUMBS:
			NavigationManager.navigate_to(payload.pop_back())
		_:
			printerr("Unsupported navigation request with request id %s!" % type)

# Pops the last screen from the stack.
func _navigate_back() -> void:
	# Nothing to go back to, open the outliner.
	if _screens_stack.size() < 2:
		_navigate_to_outliner()
		return

	var current_screen: Control = _screens_stack.pop_back()
	var next_screen: Control = _screens_stack.back()
	_back_button.disabled = _screens_stack.size() < 2

	# warning-ignore:unsafe_method_access
	var target = next_screen.get_screen_resource()
	_breadcrumbs.update_breadcrumbs(course, target)

	_transition_to(next_screen, current_screen, false)
	yield(self, "transition_completed")
	current_screen.queue_free()


# Opens the course outliner and flushes the screen stack.
func _navigate_to_outliner() -> void:
	show()
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
	var target := NavigationManager.get_navigation_resource(NavigationManager.current_url)
	var screen: Control
	if target is Practice:
		var lesson = course.lessons[_lesson_index]

		screen = preload("UIPractice.tscn").instance()
		# warning-ignore:unsafe_method_access
		screen.setup(target, lesson, course)
	elif target is Lesson:
		var lesson := target as Lesson
		screen = preload("UILesson.tscn").instance()
		# warning-ignore:unsafe_method_access
		screen.setup(target, course)

		_lesson_index = course.lessons.find(lesson) # Make sure the index is synced after navigation.
	else:
		printerr("Trying to navigate to unsupported resource type: %s" % target.get_class())
		return

	_outliner_button.show()
	_home_button.hide()
	_screen_container.show()
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


func _navigate_to_practice_next(practice: Practice) -> void:
	var lesson_data := course.lessons[_lesson_index] as Lesson
	var practices: Array = lesson_data.practices

	var index := practices.find(practice)
	# This practice is not in the current lesson, return early.
	if index < 0:
		return

	# This is the last practice in the set, try to move to the next lesson.
	if index >= practices.size() - 1:
		# Checking that it's the last practice is not enough.
		# Check if all practices are completed before moving to the next lesson.
		var user_profile = UserProfiles.get_profile()
		var lesson_progress = user_profile.get_or_create_lesson(course.resource_path, lesson_data.resource_path)
		var total_practices := practices.size()
		var completed_practices = lesson_progress.get_completed_practices_count(practices)

		# Show a confirmation popup and optionally tell the user that the lesson is incomplete.
		_lesson_done_popup.set_incomplete(completed_practices < total_practices)
		_lesson_done_popup.popup_centered()
	else:
		# Otherwise, go to the next practice in the set.
		NavigationManager.navigate_to(practices[index + 1].practice_id)


func _navigate_to_practice_previous(practice: Practice) -> void:
	var lesson_data := course.lessons[_lesson_index] as Lesson
	var practices: Array = lesson_data.practices

	var index := practices.find(practice)
	# This practice is not in the current lesson, return early.
	if index < 0:
		return

	# This is the first practice in the set, there is no valid path, should be blocked by UI.
	if index == 0:
		return
	else:
		# Otherwise, go to the previous practice in the set.
		NavigationManager.navigate_to(practices[index - 1].practice_id)


func _navigate_to_practice(practice: Practice) -> void:
	var lesson_data := course.lessons[_lesson_index] as Lesson
	var practices: Array = lesson_data.practices

	var index := practices.find(practice)
	# This practice is not in the current lesson, return early.
	if index < 0:
		return

	NavigationManager.navigate_to(practice.practice_id)

func _on_practice_next_requested(practice: Practice) -> void:
	_on_user_navigation_request(NAVIGATION_REQUEST_TYPE.NEXT_PRACTICE, [practice])

func _on_practice_previous_requested(practice: Practice) -> void:
	_on_user_navigation_request(NAVIGATION_REQUEST_TYPE.PREVIOUS_PRACTICE, [practice])

func _on_practice_requested(practice: Practice) -> void:
	_on_user_navigation_request(NAVIGATION_REQUEST_TYPE.TO_PRACTICE, [practice])

func _on_breadcrumbs_navigation_requested(path: String) -> void:
	_on_user_navigation_request(NAVIGATION_REQUEST_TYPE.BREADCRUMBS, [path])

func _on_leave_practice_unsaved_confirmed() -> void:
	_leave_unsaved_practice_popup.hide()
	var type = _leave_unsaved_practice_popup.get_navigation_type()
	var payload = _leave_unsaved_practice_popup.get_payload()
	_perform_user_navigation_request(type, payload)

func _on_user_navigation_request(type: int, payload := []) -> void:
	var screen = _screens_stack.back()
	
	# If user is in unfinished practice that has begun, prompt user to confirm navigation
	if screen is UIPractice and screen._code_editor_is_dirty:
		_leave_unsaved_practice_popup.set_navigation_data(type, payload)
		_leave_unsaved_practice_popup.popup()
	else:
		#if not, just perform the navigation
		_perform_user_navigation_request(type, payload)

func _on_lesson_completed() -> void:
	var lesson := course.lessons[_lesson_index] as Lesson
	Events.emit_signal("lesson_completed", lesson)

	_lesson_index += 1
	if _lesson_index >= _lesson_count:
		_on_course_completed()
		return

	_clear_history_stack()
	NavigationManager.navigate_to(course.lessons[_lesson_index].resource_path)


func _on_course_completed() -> void:
	Events.emit_signal("course_completed", course)
	hide()


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
