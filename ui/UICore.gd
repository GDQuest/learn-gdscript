extends Control

# It's often better to use class_name in the scripts themselves, 
# but preloading scripts as types works too.
const WelcomeScreen := preload("res://ui/screens/welcome_screen/WelcomeScreen.gd")
const LoadingScreen := preload("res://ui/LoadingScreen.gd")
const ReportFormPopup := preload("res://ui/components/popups/ReportFormPopup.gd")
const SettingsPopup := preload("res://ui/components/popups/SettingsPopup.gd")

@export var default_course := "res://course/course-learn-gdscript.tres"

var _unloading_target: Control
var _loading_target: Control
var _course_navigator: Node 

@onready var _pages := $Pages as Control
@onready var _loading_screen := $Pages/LoadingScreen as LoadingScreen
@onready var _welcome_screen := $Pages/WelcomeScreen as WelcomeScreen
@onready var _course_screen := $Pages/CourseScreen as Control

@onready var _settings_popup := $SettingsPopup as Control 
@onready var _report_form_popup := $ReportFormPopup as Control 

var _user_profile := UserProfiles.get_profile()


func _init() -> void:
	_update_framerate(_user_profile.framerate_limit)
	_user_profile.framerate_limit_changed.connect(_update_framerate)
	OS.low_processor_usage_mode = true
	OS.low_processor_usage_mode_sleep_usec = 20000


func _ready() -> void:
	_settings_popup.hide()
	_report_form_popup.hide()
	_update_welcome_button()

	_loading_screen.faded_in.connect(_on_loading_faded_in)
	_loading_screen.loading_finished.connect(_on_loading_finished)
	_welcome_screen.course_requested.connect(_on_course_requested)

	Events.report_form_requested.connect(_report_form_popup.show)
	Events.settings_requested.connect(_settings_popup.show)
	Events.course_completed.connect(_show_end_screen)

	NavigationManager.welcome_screen_navigation_requested.connect(_go_to_welcome_screen)
	NavigationManager.outliner_navigation_requested.connect(_course_screen.show)

	if not NavigationManager.current_url.is_empty():
		_on_course_requested()
		return
		
	_loading_screen.hide()
	_welcome_screen.appear()


func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed("toggle_full_screen")
		and not event.is_action_pressed("toggle_distraction_free_mode")
	):
		Events.fullscreen_toggled.emit()
		accept_event()


func start_loading(target: Control) -> void:
	_loading_target = target
	_loading_screen.reset_progress_value()
	_loading_screen.fade_in()


func load_immediately(target: Control) -> void:
	_loading_target = target
	_loading_screen.reset_progress_value()
	_loading_screen.show()
	_loading_screen.progress_value = 1.0


func _on_course_requested(force_outliner: bool = false) -> void:
	_unloading_target = _welcome_screen
	start_loading(_course_screen)

	_loading_screen.progress_value = 0.5
	await get_tree().process_frame

	if default_course.is_empty():
		printerr("Missing the default course path, make sure to set it in the UICore scene.")
		return

	var course_navigator_scene := load("res://ui/UINavigator.tscn") as PackedScene
	_course_navigator = course_navigator_scene.instantiate()
	
	# Explicitly casting for the navigator properties
	_course_navigator.set("course", load(default_course))

	var user_profile = UserProfiles.get_profile()
	var lesson_id: String = user_profile.get_last_started_lesson(default_course)
	if not lesson_id.is_empty():
		_course_navigator.call("set_start_from_lesson", lesson_id)

	_course_navigator.set("load_into_outliner", force_outliner)
	_course_screen.add_child(_course_navigator)

	_loading_screen.progress_value = 1.0


func _on_loading_faded_in() -> void:
	if is_instance_valid(_unloading_target):
		_unloading_target.hide()
		_unloading_target = null


func _on_loading_finished() -> void:
	if is_instance_valid(_loading_target):
		_loading_target.show()
		_loading_target = null


func _show_end_screen(_course: Course) -> void:
	var show_sponsored_screen: bool = UserProfiles.get_profile().is_sponsored_profile

	for page in _pages.get_children():
		var control_page := page as Control
		if control_page:
			control_page.hide()

	if show_sponsored_screen:
		get_tree().change_scene_to_file("res://ui/screens/end_screen/EndScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://ui/screens/end_screen/SponsorlessEndScreen.tscn")

func _go_to_welcome_screen() -> void:
	_course_screen.hide()
	if is_instance_valid(_course_navigator):
		_course_navigator.queue_free()

	_update_welcome_button()
	start_loading(_welcome_screen)
	_loading_screen.progress_value = 1.0


func _update_welcome_button() -> void:
	if default_course.is_empty():
		return

	var user_profile = UserProfiles.get_profile()
	var lesson_id: String = user_profile.get_last_started_lesson(default_course)
	_welcome_screen.set_button_continue(not lesson_id.is_empty())


func _update_framerate(new_framerate: int) -> void:
	if new_framerate <= 0:
		new_framerate = 1000
	OS.low_processor_usage_mode_sleep_usec = int(1000000.0 / new_framerate)
