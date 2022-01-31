extends PanelContainer

const CourseLessonList := preload("res://ui/screens/course_outliner/CourseLessonList.gd")
const LessonDetails := preload("./CourseLessonDetails.gd")


var course: Course setget set_course
var _current_lesson: Lesson
var _current_practice: Practice

var _last_selected_lesson := ""

onready var _title_label := $MarginContainer/Layout/TitleBox/TitleLabel as Label
onready var _lesson_list := $MarginContainer/Layout/HBoxContainer/LeftColumn/LessonList as CourseLessonList
onready var _lesson_details := $MarginContainer/Layout/HBoxContainer/LessonDetails as LessonDetails

onready var _reset_button := (
	$MarginContainer/Layout/HBoxContainer/LeftColumn/PanelContainer/Buttons/ResetButton as Button
)
onready var _reset_confirm_popup := $ConfirmResetPopup as ConfirmPopup


func _ready() -> void:
	_update_outliner_index()

	Events.connect("lesson_started", self, "_on_lesson_started")
	Events.connect("lesson_reading_block", self, "_on_lesson_reading_block")
	Events.connect("quiz_completed", self, "_on_quiz_completed")
	Events.connect("practice_started", self, "_on_practice_started")
	Events.connect("practice_completed", self, "_on_practice_completed")
	Events.connect("lesson_completed", self, "_on_lesson_completed")
	Events.connect("course_completed", self, "_on_course_completed")

	_lesson_list.connect("lesson_selected", self, "_on_lesson_selected")
	_reset_button.connect("pressed", self, "_on_reset_requested")
	_reset_confirm_popup.connect("confirmed", self, "_on_reset_confirmed")


func set_course(value: Course) -> void:
	course = value
	# Ensure that the user profile and the course progression data exists.
	var user_profile = UserProfiles.get_profile()
	user_profile.get_or_create_course(course.resource_path)

	_update_outliner_index()


func _update_outliner_index() -> void:
	_lesson_list.clear()
	_lesson_details.hide()
	_title_label.text = ""
	if not course:
		return

	_title_label.text = course.title

	var user_profile = UserProfiles.get_profile()
	var lesson_index := 0
	var _reselect_index := -1
	for lesson_data in course.lessons:
		lesson_data = lesson_data as Lesson
		var lesson_progress := (
			user_profile.get_or_create_lesson(course.resource_path, lesson_data.resource_path) as LessonProgress
		)

		var completion := _calculate_lesson_completion(lesson_data, lesson_progress)
		_lesson_list.add_item(lesson_index, lesson_data.title, completion)

		if not _last_selected_lesson.empty() and lesson_data.resource_path == _last_selected_lesson:
			_reselect_index = lesson_index

		lesson_index += 1

	if _reselect_index >= 0:
		_lesson_list.select(_reselect_index)
		_on_lesson_selected(_reselect_index)


func _calculate_lesson_completion(lesson_data: Lesson, lesson_progress: LessonProgress) -> int:
	var completion := 0
	var max_completion := lesson_data.content_blocks.size() + lesson_data.practices.size() + lesson_data.get_quizzes_count()

	if lesson_progress.completed_reading:
		completion += lesson_data.content_blocks.size()
	else:
		completion += lesson_progress.get_completed_blocks_count(lesson_data.content_blocks)

	completion += lesson_progress.get_completed_quizzes_count(lesson_data.get_quizzes())
	completion += lesson_progress.get_completed_practices_count(lesson_data.practices)

	return int(clamp(float(completion) / float(max_completion) * 100, 0, 100))


func _on_lesson_selected(lesson_index: int) -> void:
	if not course or lesson_index < 0 or lesson_index >= course.lessons.size():
		return

	var lesson_data := course.lessons[lesson_index] as Lesson
	_lesson_details.lesson = lesson_data

	var user_profile = UserProfiles.get_profile()
	var lesson_progress := (
		user_profile.get_or_create_lesson(course.resource_path, lesson_data.resource_path) as LessonProgress
	)
	_lesson_details.lesson_progress = lesson_progress

	_lesson_details.has_started = _calculate_lesson_completion(lesson_data, lesson_progress) > 0
	_lesson_details.show()

	_last_selected_lesson = lesson_data.resource_path


func _on_lesson_started(lesson_data: Lesson) -> void:
	_current_lesson = lesson_data
	_current_practice = null

	_last_selected_lesson = _current_lesson.resource_path

	var user_profile = UserProfiles.get_profile()
	user_profile.set_last_started_lesson(course.resource_path, _current_lesson.resource_path)
	_update_outliner_index()


func _on_lesson_reading_block(block_data: Resource, previous_blocks: Array = []) -> void:
	if not _current_lesson:
		return

	var user_profile = UserProfiles.get_profile()
	# Ensure that all previous blocks are also considered as read.
	for prev_block_data in previous_blocks:
		var block_id := ""
		if prev_block_data is Quiz:
			block_id = prev_block_data.quiz_id
		else:
			block_id = prev_block_data.content_id
		user_profile.set_lesson_reading_block(course.resource_path, _current_lesson.resource_path, block_id)
	# Then set the last block.
	var block_id := ""
	if block_data is Quiz:
		block_id = (block_data as Quiz).quiz_id
	else:
		block_id = (block_data as ContentBlock).content_id
	user_profile.set_lesson_reading_block(course.resource_path, _current_lesson.resource_path, block_id)
	_update_outliner_index()


func _on_quiz_completed(quiz_data: Quiz) -> void:
	if not _current_lesson:
		return

	var user_profile = UserProfiles.get_profile()
	user_profile.set_lesson_quiz_completed(course.resource_path, _current_lesson.resource_path, quiz_data.quiz_id, true)
	_update_outliner_index()


func _on_practice_started(practice_data: Practice) -> void:
	if not _current_lesson:
		return
	_current_practice = practice_data

	var user_profile = UserProfiles.get_profile()
	user_profile.set_lesson_reading_completed(course.resource_path, _current_lesson.resource_path, true)
	_update_outliner_index()


func _on_practice_completed(practice_data: Practice) -> void:
	if not _current_lesson or not _current_practice:
		return

	var user_profile = UserProfiles.get_profile()
	user_profile.set_lesson_practice_completed(course.resource_path, _current_lesson.resource_path, practice_data.practice_id, true)
	_update_outliner_index()
	_current_practice = null


func _on_lesson_completed(_lesson_data: Lesson) -> void:
	_current_lesson = null
	_update_outliner_index()


func _on_course_completed(_course_data: Course) -> void:
	_update_outliner_index()


func _on_reset_requested() -> void:
	_reset_confirm_popup.popup()


func _on_reset_confirmed() -> void:
	_reset_confirm_popup.hide()

	var user_profile = UserProfiles.get_profile()
	user_profile.reset_course_progress(course.resource_path)

	_update_outliner_index()
