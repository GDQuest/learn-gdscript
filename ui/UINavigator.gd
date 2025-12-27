class_name UINavigator
extends PanelContainer

signal transition_completed
signal return_to_welcome_screen_requested

# 1. Properly type the preloaded scripts so Godot knows what they are
const CourseOutlinerScript := preload("res://ui/screens/course_outliner/CourseOutliner.gd")
const BreadCrumbsScript := preload("res://ui/components/BreadCrumbs.gd")
const LessonDonePopupScript := preload("res://ui/components/popups/LessonDonePopup.gd")

const SCREEN_TRANSITION_DURATION := 0.75
const OUTLINER_TRANSITION_DURATION := 0.5

var course: Course

var use_transitions := true
var load_into_outliner := false

# 2. Typed Array: Tells Godot this array ONLY contains Controls
var _screens_stack: Array[Control] = []

# FIX: Line 22 - Removed _matches as it was unused.

var _lesson_index := 0
var _lesson_count: int = 0

@onready var _home_button := $Layout/Header/MarginContainer/HeaderContent/HomeButton as Button
@onready var _outliner_button := $Layout/Header/MarginContainer/HeaderContent/OutlinerButton as Button
@onready var _back_button := $Layout/Header/MarginContainer/HeaderContent/BackButton as Button
@onready var _breadcrumbs := $Layout/Header/MarginContainer/HeaderContent/BreadCrumbs as BreadCrumbs
@onready var _settings_button := $Layout/Header/MarginContainer/HeaderContent/SettingsButton as Button
@onready var _report_button := $Layout/Header/MarginContainer/HeaderContent/ReportButton as Button

@onready var _screen_container := $Layout/Content/ScreenContainer as Container

@onready var _course_outliner := $Layout/Content/CourseOutliner as CourseOutlinerScript

@onready var _lesson_done_popup := $LessonDonePopup as LessonDonePopupScript

@onready var _sale_button := $Layout/Header/MarginContainer/HeaderContent/SaleButton as Button
@onready var _sale_popup := $SalePopup # If SalePopup has a class_name, use 'as SalePopup' here

var _tween: Tween

func _ready() -> void:
	_lesson_count = course.lessons.size()
	_course_outliner.course = course

	NavigationManager.navigation_requested.connect(_navigate_to)
	NavigationManager.back_navigation_requested.connect(_navigate_back)
	NavigationManager.outliner_navigation_requested.connect(_navigate_to_outliner)

	Events.practice_next_requested.connect(_on_practice_next_requested)
	Events.practice_previous_requested.connect(_on_practice_previous_requested)
	Events.practice_requested.connect(_on_practice_requested)

	_lesson_done_popup.accepted.connect(_on_lesson_completed)

	_outliner_button.pressed.connect(NavigationManager.navigate_to_outliner)
	_back_button.pressed.connect(NavigationManager.navigate_back)
	_home_button.pressed.connect(NavigationManager.navigate_to_welcome_screen)

	_settings_button.pressed.connect(Events.settings_requested.emit)
	_report_button.pressed.connect(Events.report_form_requested.emit)

	# FIX: Line 67/70 - Added safety checks for the sale popup
	if not UserProfiles.get_profile().is_sponsored_profile or (_sale_popup.has_method("is_sale_over") and _sale_popup.is_sale_over()):
		_sale_button.hide()
	else:
		_sale_button.pressed.connect(_sale_popup.show)

	if NavigationManager.current_url == "":
		if load_into_outliner:
			NavigationManager.navigate_to_outliner()
		else:
			if _lesson_index < 0 or _lesson_index >= course.lessons.size():
				_lesson_index = 0
			# FIX: Line 78 - Ensure path is a String
			NavigationManager.navigate_to(str(course.lessons[_lesson_index].resource_path))
	else:
		_navigate_to()



func _unhandled_input(event: InputEvent) -> void:
	# FIX: Line 84 - event.alt only exists on InputEventWithModifiers (like keys or mouse clicks)
	if event.is_action_released("ui_back") and event is InputEventWithModifiers and event.alt:
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


func _navigate_back() -> void:
	if _tween and _tween.is_valid():
		return

	if _screens_stack.size() < 2:
		_navigate_to_outliner()
		return

	var current_screen := _screens_stack.pop_back() as Control
	var next_screen := _screens_stack.back() as Control
	_update_back_button(_screens_stack.size() < 2)

	if next_screen.has_method("get_screen_resource"):
		var target = next_screen.call("get_screen_resource")
		_breadcrumbs.update_breadcrumbs(course, target)

	if next_screen.has_method("set_is_current_screen"):
		next_screen.call("set_is_current_screen", true)

	_transition_to(next_screen, current_screen, false)
	await transition_completed
	current_screen.queue_free()


func _navigate_to_outliner() -> void:
	show()
	_course_outliner.modulate.a = 0.0
	_course_outliner.show()

	_outliner_button.hide()
	_back_button.hide()
	_update_back_button(true)
	_home_button.show()
	_clear_history_stack()

	if _tween: _tween.kill()
	_animate_outliner(true)
	
	await _tween.finished 
	_screen_container.hide()


func _navigate_to() -> void:
	if _tween and _tween.is_valid():
		return

	var target := NavigationManager.get_navigation_resource(NavigationManager.current_url)
	var screen: Control
	
	if target is Practice:
		var lesson = course.lessons[_lesson_index]
		screen = preload("UIPractice.tscn").instantiate()
		if screen.has_method("setup"):
			screen.call("setup", target, lesson, course)
	elif target is Lesson:
		var lesson := target as Lesson
		screen = preload("UILesson.tscn").instantiate()
		if screen.has_method("setup"):
			screen.call("setup", target, course)
		_lesson_index = course.lessons.find(lesson)
	else:
		return

	_outliner_button.show()
	_home_button.hide()
	_screen_container.show()
	_breadcrumbs.update_breadcrumbs(course, target)

	var has_previous_screen = not _screens_stack.is_empty()
	_screens_stack.push_back(screen)
	
	if screen.has_method("set_is_current_screen"):
		screen.call("set_is_current_screen", true)
		
	_back_button.show()
	_update_back_button(_screens_stack.size() < 2)

	_screen_container.add_child(screen)
	if has_previous_screen:
		var previous_screen := _screens_stack[-2] as Control
		if previous_screen.has_method("set_is_current_screen"):
			previous_screen.call("set_is_current_screen", false)
		_transition_to(screen, previous_screen)
		await transition_completed

	# FIX: Line 181 - Cast node to RichTextLabel
	for node in get_tree().get_nodes_in_group("rich_text_label"):
		if node is RichTextLabel:
			NavigationManager.connect_rich_text_node(node)

	if _course_outliner.visible:
		if _tween: _tween.kill()
		_animate_outliner(false)
		await _tween.finished

	_course_outliner.hide()

	if target is Practice:
		Events.practice_started.emit(target)
	elif target is Lesson:
		Events.lesson_started.emit(target)


func _on_practice_next_requested(practice: Practice) -> void:
	var lesson_data := course.lessons[_lesson_index] as Lesson
	var practices: Array = lesson_data.practices
	var index := practices.find(practice)

	if index < 0: return

	if index >= practices.size() - 1:
		var user_profile = UserProfiles.get_profile()
		var lesson_progress = user_profile.get_or_create_lesson(course.resource_path, lesson_data.resource_path)
		var total_practices := practices.size()
		var completed_practices = lesson_progress.get_completed_practices_count(practices)

		_lesson_done_popup.set_incomplete(bool(completed_practices < total_practices))
		_lesson_done_popup.popup_centered()
	else:
		NavigationManager.navigate_to(str(practices[index + 1].practice_id))

func _on_practice_previous_requested(practice: Practice) -> void:
	var lesson_data := course.lessons[_lesson_index] as Lesson
	var practices: Array = lesson_data.practices
	var index := practices.find(practice)

	if index <= 0: return
	NavigationManager.navigate_to(practices[index - 1].practice_id)


func _on_practice_requested(practice: Practice) -> void:
	var lesson_data := course.lessons[_lesson_index] as Lesson
	var practices: Array = lesson_data.practices
	if practices.find(practice) < 0: return
	NavigationManager.navigate_to(practice.practice_id)


func _on_lesson_completed() -> void:
	var lesson := course.lessons[_lesson_index] as Lesson
	Events.lesson_completed.emit(lesson)

	_lesson_index += 1
	if _lesson_index >= _lesson_count:
		_on_course_completed()
		return

	_clear_history_stack()
	NavigationManager.navigate_to(course.lessons[_lesson_index].resource_path)


func _on_course_completed() -> void:
	Events.course_completed.emit(course)
	hide()


func _transition_to(screen: Control, from_screen: Control = null, direction_in := true) -> void:
	if not use_transitions:
		if from_screen:
			from_screen.hide()
			_screen_container.remove_child(from_screen)

		if screen.get_parent() == null:
			_screen_container.add_child(screen)
		screen.show()

		await get_tree().process_frame
		transition_completed.emit()
		return

	if screen.get_parent() == null:
		_screen_container.add_child(screen)
	screen.show()

	if from_screen:
		from_screen.show()

	var viewport_width: float = _screen_container.size.x
	var direction := 1.0 if direction_in else -1.0
	screen.position.x = viewport_width * direction

	if _tween: _tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	_tween.tween_property(screen, "position:x", 0.0, SCREEN_TRANSITION_DURATION)
	
	if from_screen:
		_tween.tween_property(from_screen, "position:x", -viewport_width * direction, SCREEN_TRANSITION_DURATION)

	await _tween.finished

	if from_screen:
		from_screen.hide()
		_screen_container.remove_child(from_screen)

	transition_completed.emit()


func _animate_outliner(fade_in: bool) -> void:
	if _tween: _tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	var start_a = 0.0 if fade_in else 1.0
	var end_a = 1.0 if fade_in else 0.0
	
	_course_outliner.modulate.a = start_a
	_tween.tween_property(_course_outliner, "modulate:a", end_a, OUTLINER_TRANSITION_DURATION)
	

func _clear_history_stack() -> void:
	for child_node in _screen_container.get_children():
		_screen_container.remove_child(child_node)
		child_node.queue_free()
	for screen in _screens_stack:
		if is_instance_valid(screen):
			screen.queue_free()
	_screens_stack.clear()

	_breadcrumbs.update_breadcrumbs(course, null)

func _update_back_button(is_disabled: bool) -> void:
	_back_button.disabled = is_disabled
	var tooltip := tr("Go back in your navigation history")
	if is_disabled:
		_back_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		tooltip += " " + tr("(no previous history)")
	else:
		_back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# hint_tooltip -> tooltip_text
	_back_button.tooltip_text = tooltip
