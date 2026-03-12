extends PanelContainer

const CourseLessonList := preload("res://ui/screens/course_outliner/CourseLessonList.gd")
const LessonDetails := preload("./CourseLessonDetails.gd")


var course_index: CourseIndex setget set_course
var _current_lesson: BBCodeParser.ParseNode
var _current_practice: BBCodeParser.ParseNode

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


func set_course(value: CourseIndex) -> void:
	course_index = value
	# Ensure that the user profile and the course progression data exists.
	var user_profile = UserProfiles.get_profile()
	user_profile.get_or_create_course(course_index.get_course_id())

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

		if not _last_selected_lesson.empty() and lesson_data.bbcode_path == _last_selected_lesson:
			_reselect_index = lesson_index

		lesson_index += 1

	if _reselect_index >= 0:
		_lesson_list.select(_reselect_index)
		_on_lesson_selected(_reselect_index)


func _calculate_lesson_completion(lesson_data: BBCodeParser.ParseNode, lesson_progress: LessonProgress) -> int:
	var completion := 0
	var practice_count := BBCodeUtils.get_lesson_practice_count(lesson_data)
	var quiz_count := BBCodeUtils.get_lesson_quiz_count(lesson_data)
	var block_count := BBCodeUtils.get_lesson_block_count(lesson_data) - practice_count - quiz_count
	var max_completion := block_count + practice_count + quiz_count

	if lesson_progress.completed_reading:
		completion += block_count
	else:
		completion += lesson_progress.get_completed_blocks_count(lesson_data, block_count)

	completion += lesson_progress.get_completed_quizzes_count(lesson_data)
	completion += lesson_progress.get_completed_practices_count(lesson_data)

	return int(clamp(float(completion) / float(max_completion) * 100, 0, 100))


func _on_lesson_selected(lesson_index: int) -> void:
	if not course_index or lesson_index < 0 or lesson_index >= course_index.get_lessons_count():
		return

	var lesson_data := NavigationManager.get_navigation_resource(course_index.get_lesson_path(lesson_index)) as BBCodeParser.ParseNode
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


func _on_lesson_reading_block(block_data, block_idx: int, previous_blocks: Array = []) -> void:
	if not _current_lesson:
		return

	var user_profile = UserProfiles.get_profile()
	# Ensure that all previous blocks are also considered as read.
	for i in previous_blocks.size():
		var prev_block_data = previous_blocks[i]
		var block_id := ""
		if prev_block_data is BBCodeParser.ParseNode and prev_block_data.tag in [BBCodeParserData.Tag.QUIZ_CHOICE, BBCodeParserData.Tag.QUIZ_INPUT]:
			block_id = BBCodeUtils.get_quiz_id(prev_block_data)
		elif prev_block_data is BBCodeParser.ParseNode:
			block_id = BBCodeUtils.get_lesson_block_id(prev_block_data)
		else:
			block_id = "_generated_content_block_plain_%s" % i
		user_profile.set_lesson_reading_block(course_index.get_course_id(), _current_lesson.bbcode_path, block_id)
	# Then set the last block.
	var block_id := ""
	if block_data is BBCodeParser.ParseNode and block_data.tag in [BBCodeParserData.Tag.QUIZ_CHOICE, BBCodeParserData.Tag.QUIZ_INPUT]:
		block_id = BBCodeUtils.get_quiz_id(block_data)
	elif block_data is BBCodeParser.ParseNode:
		block_id = BBCodeUtils.get_lesson_block_id(block_data)
	else:
		block_id = "_generated_content_block_plain_%s" % block_idx
	user_profile.set_lesson_reading_block(course_index.get_course_id(), _current_lesson.bbcode_path, block_id)
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


func _on_course_completed(_course_data: Reference) -> void:
	_update_outliner_index()


func _on_reset_requested() -> void:
	_reset_confirm_popup.popup()


func _on_reset_confirmed() -> void:
	_reset_confirm_popup.hide()

	var user_profile = UserProfiles.get_profile()
	user_profile.reset_course_progress(course_index.get_course_id())

	_update_outliner_index()
