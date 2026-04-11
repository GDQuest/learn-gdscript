extends PanelContainer

const CourseLessonList := preload("res://ui/screens/course_outliner/CourseLessonList.gd")
const LessonDetails := preload("./CourseLessonDetails.gd")

@export var _title_label: Label
@export var _lesson_list: CourseLessonList
@export var _lesson_details: LessonDetails
@export var _reset_button: Button
@export var _reset_confirm_popup: ConfirmPopup

var course_index: CourseIndex:
	set = set_course
var _current_lesson: BBCodeParser.ParseNode
var _current_practice: BBCodeParser.ParseNode

var _last_selected_lesson := ""


func _ready() -> void:
	_update_outliner_index()

	Events.lesson_started.connect(_on_lesson_started)
	Events.lesson_read.connect(_on_lesson_read)
	Events.quiz_completed.connect(_on_quiz_completed)
	Events.practice_started.connect(_on_practice_started)
	Events.practice_completed.connect(_on_practice_completed)
	Events.lesson_completed.connect(_on_lesson_completed)
	Events.course_completed.connect(_on_course_completed)

	_lesson_list.lesson_selected.connect(_on_lesson_selected)
	_reset_button.pressed.connect(_on_reset_requested)
	_reset_confirm_popup.confirmed.connect(_on_reset_confirmed)


func set_course(value: CourseIndex) -> void:
	course_index = value
	# Ensure that the user profile and the course progression data exists.
	var user_profile = UserProfiles.get_profile()
	user_profile.get_or_create_course(course_index.get_course_id())

	_update_outliner_index()


func _on_lesson_read(lesson: BBCodeParser.ParseNode) -> void:
	var user_profile = UserProfiles.get_profile()
	user_profile.set_lesson_reading_completed(course_index.get_course_id(), lesson.bbcode_path, true)
	_update_outliner_index()


func _update_outliner_index() -> void:
	_lesson_list.clear()
	_lesson_details.hide()
	_title_label.text = ""
	if not course_index:
		return

	_title_label.text = course_index.get_title()

	var user_profile = UserProfiles.get_profile()
	var lesson_index := 0
	var _reselect_index := -1
	for i in course_index.get_lessons_count():
		var lesson_data := NavigationManager.get_navigation_resource(course_index.get_lesson_path(i)) as BBCodeParser.ParseNode
		var lesson_progress := (
			user_profile.get_or_create_lesson(course_index.get_course_id(), lesson_data.bbcode_path) as LessonProgress
		)

		var completion := _calculate_lesson_completion(lesson_data, lesson_progress)
		_lesson_list.add_item(lesson_index, BBCodeUtils.get_lesson_title(lesson_data), completion)

		if not _last_selected_lesson.is_empty() and lesson_data.bbcode_path == _last_selected_lesson:
			_reselect_index = lesson_index

		lesson_index += 1

	if _reselect_index >= 0:
		_lesson_list.select(_reselect_index)
		_on_lesson_selected(_reselect_index)


func _calculate_lesson_completion(lesson_data: BBCodeParser.ParseNode, lesson_progress: LessonProgress) -> int:
	var completion := 0
	var practice_count := BBCodeUtils.get_lesson_practice_count(lesson_data)
	var quiz_count := BBCodeUtils.get_lesson_quiz_count(lesson_data)
	var max_completion := practice_count + quiz_count + 1

	if lesson_progress.completed_reading:
		completion += 1

	completion += lesson_progress.get_completed_quizzes_count(lesson_data)
	completion += lesson_progress.get_completed_practices_count(lesson_data)

	return clampi(int(float(completion) / float(max_completion) * 100), 0, 100)


func _on_lesson_selected(lesson_index: int) -> void:
	if not course_index or lesson_index < 0 or lesson_index >= course_index.get_lessons_count():
		return

	var lesson_data := NavigationManager.get_navigation_resource(course_index.get_lesson_path(lesson_index)) as BBCodeParser.ParseNode
	_lesson_details.course_index = course_index
	_lesson_details.lesson = lesson_data

	var user_profile = UserProfiles.get_profile()
	var lesson_progress := (
		user_profile.get_or_create_lesson(course_index.get_course_id(), lesson_data.bbcode_path) as LessonProgress
	)
	_lesson_details.lesson_progress = lesson_progress

	_lesson_details.has_started = _calculate_lesson_completion(lesson_data, lesson_progress) > 0
	_lesson_details.show()

	_last_selected_lesson = lesson_data.bbcode_path


func _on_lesson_started(lesson_data: BBCodeParser.ParseNode) -> void:
	_current_lesson = lesson_data
	_current_practice = null

	_last_selected_lesson = _current_lesson.bbcode_path

	var user_profile = UserProfiles.get_profile()
	user_profile.set_last_started_lesson(course_index.get_course_id(), _current_lesson.bbcode_path)
	_update_outliner_index()


func _on_quiz_completed(quiz_data: BBCodeParser.ParseNode) -> void:
	if not _current_lesson:
		return

	var user_profile = UserProfiles.get_profile()
	user_profile.set_lesson_quiz_completed(course_index.get_course_id(), _current_lesson.bbcode_path, BBCodeUtils.get_quiz_id(quiz_data), true)
	_update_outliner_index()


func _on_practice_started(practice_data: BBCodeParser.ParseNode) -> void:
	if not _current_lesson:
		return
	_current_practice = practice_data

	var user_profile = UserProfiles.get_profile()
	user_profile.set_lesson_reading_completed(course_index.get_course_id(), _current_lesson.bbcode_path, true)
	_update_outliner_index()


func _on_practice_completed(practice_data: BBCodeParser.ParseNode) -> void:
	if not _current_lesson or not _current_practice:
		return

	var user_profile = UserProfiles.get_profile()
	user_profile.set_lesson_practice_completed(course_index.get_course_id(), _current_lesson.bbcode_path, BBCodeUtils.get_practice_id(practice_data), true)
	_update_outliner_index()
	_current_practice = null


func _on_lesson_completed(_lesson_data: BBCodeParser.ParseNode) -> void:
	_current_lesson = null
	_update_outliner_index()


func _on_course_completed(_course_data: RefCounted) -> void:
	_update_outliner_index()


func _on_reset_requested() -> void:
	_reset_confirm_popup.popup()


func _on_reset_confirmed() -> void:
	_reset_confirm_popup.hide()

	var user_profile = UserProfiles.get_profile()
	user_profile.reset_course_progress(course_index.get_course_id())

	_update_outliner_index()
