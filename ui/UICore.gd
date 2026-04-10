extends Control

const WelcomeScreen := preload("./screens/welcome_screen/WelcomeScreen.gd")
const LoadingScreen := preload("./LoadingScreen.gd")
const ReportFormPopup := preload("./components/popups/ReportFormPopup.gd")
const SettingsPopup := preload("./components/popups/SettingsPopup.gd")

@export var default_course_id := "learn-gdscript"
@export var _pages: Control
@export var _loading_screen: LoadingScreen
@export var _welcome_screen: WelcomeScreen
@export var _course_screen: Control
@export var _settings_popup: SettingsPopup
@export var _report_form_popup: ReportFormPopup

var _unloading_target: Control
var _loading_target: Control
var _course_navigator: UINavigator

var _user_profile := UserProfiles.get_profile()


func _init() -> void:
	# TODO: Remove feature guard whenever https://github.com/godotengine/godot/issues/117875 is fixed
	# also consider using Engine.max_fps instead when it's fixed
	if not OS.has_feature("web"):
		OS.low_processor_usage_mode = true
		OS.low_processor_usage_mode_sleep_usec = 20000
		_update_framerate(_user_profile.framerate_limit)
		_user_profile.framerate_limit_changed.connect(_update_framerate)


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
	# Needed to navigate back from the end screen to the outliner.
	NavigationManager.outliner_navigation_requested.connect(_course_screen.show)

	await get_tree().process_frame

	if NavigationManager.current_url != "":
		_on_course_requested()
		return
	_loading_screen.hide()
	_welcome_screen.appear()


func _unhandled_input(event: InputEvent) -> void:
	# We need to check the distraction free mode to avoid conflicts with the
	# button in UIPractice.
	if (
		event.is_action_pressed("toggle_full_screen")
		and not event.is_action_pressed("toggle_distraction_free_mode")
	):
		Events.emit_signal("fullscreen_toggled")
		accept_event()


# Use this function to manually display the loading screen and control its
# progress. To increase the loading progress, set
# _loading_screen.progress_value. When the value reaches 1.0, the loading screen
# disappears automatically.
func start_loading(target: Control) -> void:
	_loading_target = target
	_loading_screen.reset_progress_value()
	_loading_screen.fade_in()


# Immediately displays the loaded target after playing the loading screen
# animation. If the loading screen is transparent, this function doesn't fade it
# in.
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

	if default_course_id.is_empty():
		# We completely failed, chief!
		printerr("Missing the default course path, make sure to set it in the UICore scene.")
		return

	# We don't preload this scene, nor the course resource, so that the initial load into the app
	# is faster. Consider using ResourceLoader.load_interactive() for progress updates in the future.
	var course_navigator_scene := load("res://ui/UINavigator.tscn") as PackedScene
	_course_navigator = course_navigator_scene.instantiate()
	_course_navigator.course_index = CourseIndexPaths.get_course_index_instance(default_course_id)

	var user_profile = UserProfiles.get_profile()
	var lesson_id := user_profile.get_last_started_lesson(_course_navigator.course_index.get_course_id())
	if not lesson_id.is_empty():
		_course_navigator.set_start_from_lesson(lesson_id)

	_course_navigator.load_into_outliner = force_outliner
	_course_screen.add_child(_course_navigator)

	_loading_screen.progress_value = 1.0


func _on_loading_faded_in() -> void:
	if _unloading_target and is_instance_valid(_unloading_target):
		_unloading_target.hide()
		_unloading_target = null


func _on_loading_finished() -> void:
	if _loading_target and is_instance_valid(_loading_target):
		_loading_target.show()
		_loading_target = null


func _show_end_screen(_course_index: CourseIndex) -> void:
	var show_sponsored_screen := UserProfiles.get_profile().is_sponsored_profile

	for page: Control in _pages.get_children():
		page.hide()

	if show_sponsored_screen:
		get_tree().change_scene_to_file("res://ui/screens/end_screen/EndScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://ui/screens/end_screen/SponsorlessEndScreen.tscn")


func _go_to_welcome_screen() -> void:
	_course_screen.hide()
	_course_navigator.queue_free()

	_update_welcome_button()
	start_loading(_welcome_screen)
	_loading_screen.progress_value = 1.0


func _update_welcome_button() -> void:
	if default_course_id.is_empty():
		return

	var user_profile = UserProfiles.get_profile()
	var lesson_id = user_profile.get_last_started_lesson(default_course_id)
	_welcome_screen.set_button_continue(not lesson_id.is_empty())


func _update_framerate(new_framerate: int) -> void:
	if new_framerate == 0:
		new_framerate = 1000
	# TODO: Consider using Engine.max_fps instead
	OS.low_processor_usage_mode_sleep_usec = floori(1_000_000.0 / new_framerate)
