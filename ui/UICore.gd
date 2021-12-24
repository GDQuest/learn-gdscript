extends Control

const LoadingScreen = preload("./LoadingScreen.gd")
const ReportFormPopup = preload("./components/popups/ReportFormPopup.gd")
const SettingsPopup = preload("./components/popups/SettingsPopup.gd")

export var default_course := "res://course/course-learn-gdscript.tres"

var _unloading_target: Control
var _loading_target: Control

onready var _loading_screen := $Pages/LoadingScreen as LoadingScreen
onready var _welcome_screen := $Pages/WelcomeScreen as Control
onready var _settings_screen := $Pages/SettingsScreen as Control
onready var _course_screen := $Pages/CourseScreen as Control

onready var _settings_popup := $SettingsPopup as SettingsPopup
onready var _report_form_popup := $ReportFormPopup as ReportFormPopup


func _ready() -> void:
	_settings_popup.hide()
	_report_form_popup.hide()
	
	if not default_course.empty():
		var user_profile = UserProfiles.get_profile()
		var lesson_id = user_profile.get_last_started_lesson(default_course)
		if not lesson_id.empty():
			_welcome_screen.set_button_continue()
	
	_loading_screen.connect("faded_in", self, "_on_loading_faded_in")
	_loading_screen.connect("loading_finished", self, "_on_loading_finished")
	_welcome_screen.connect("course_requested", self, "_on_course_requested")
	
	Events.connect("report_form_requested", _report_form_popup, "show")
	Events.connect("settings_requested", _settings_popup, "show")
	
	if NavigationManager.current_url != "":
		_on_course_requested()
		return
	
	load_immediately(_welcome_screen)


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
	yield(get_tree(), "idle_frame")
	
	if default_course.empty():
		# We completely failed, chief!
		printerr("Missing the default course path, make sure to set it in the UICore scene.")
		return
	
	# We don't preload this scene, nor the course resource, so that the initial load into the app
	# is faster.
	# FIXME: Use interactive loader instead?
	var course_navigator_scene := load("res://ui/UINavigator.tscn") as PackedScene
	var course_navigator = course_navigator_scene.instance()
	course_navigator.course = load(default_course) as Course
	
	var user_profile = UserProfiles.get_profile()
	var lesson_id = user_profile.get_last_started_lesson(default_course)
	if not lesson_id.empty():
		course_navigator.set_start_from_lesson(lesson_id)
	
	course_navigator.load_into_outliner = force_outliner
	_course_screen.add_child(course_navigator)
	
	_loading_screen.progress_value = 1.0


func _on_loading_faded_in() -> void:
	if _unloading_target and is_instance_valid(_unloading_target):
		_unloading_target.hide()
		_unloading_target = null


func _on_loading_finished() -> void:
	if _loading_target and is_instance_valid(_loading_target):
		_loading_target.show()
		_loading_target = null
