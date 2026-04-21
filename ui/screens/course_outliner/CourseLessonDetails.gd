extends PanelContainer

const VALUE_CHECK_NONE := preload("res://ui/icons/checkmark_none.svg")
const VALUE_CHECK_PASSED := preload("res://ui/icons/checkmark_valid.svg")
const VALUE_COLOR_NONE := Color(0.290196, 0.294118, 0.388235)
const VALUE_COLOR_PASSED := Color(0.239216, 1, 0.431373)

@export var _title_label: Label
@export var _reading_stats_icon: TextureRect
@export var _quiz_stats_block: Control
@export var _quiz_stats_value: Label
@export var _practice_stats_value: Label
@export var _goto_lesson_button: Button

var course_index: CourseIndex:
	set = set_course_index
var lesson: BBCodeParser.ParseNode:
	set = set_lesson
var lesson_progress: LessonProgress:
	set = set_lesson_progress
var has_started: bool = false:
	set = set_has_started


func _ready() -> void:
	_update_visuals()

	_goto_lesson_button.pressed.connect(_on_goto_lesson_pressed)
	_goto_lesson_button.grab_focus()


func set_lesson(value: BBCodeParser.ParseNode) -> void:
	lesson = value
	_update_visuals()


func set_course_index(value: CourseIndex) -> void:
	course_index = value
	_update_visuals()


func set_lesson_progress(value: LessonProgress) -> void:
	lesson_progress = value
	_update_visuals()


func set_has_started(value: bool) -> void:
	has_started = value
	_update_visuals()


func _update_visuals() -> void:
	if not is_inside_tree():
		return
	if not lesson:
		return

	_title_label.text = BBCodeUtils.get_lesson_title(lesson)

	var has_done_reading := false
	_reading_stats_icon.texture = VALUE_CHECK_NONE
	_reading_stats_icon.modulate = VALUE_COLOR_NONE
	if lesson_progress and lesson_progress.completed_reading:
		_reading_stats_icon.texture = VALUE_CHECK_PASSED
		_reading_stats_icon.modulate = VALUE_COLOR_PASSED
		has_done_reading = true

	var total_practices := BBCodeUtils.get_lesson_practice_count(lesson)
	var completed_practices := 0
	if lesson_progress:
		completed_practices = lesson_progress.get_completed_practices_count(lesson)
	_practice_stats_value.text = "%d / %d" % [completed_practices, total_practices]

	var total_quizzes := BBCodeUtils.get_lesson_quiz_count(lesson)
	if total_quizzes > 0:
		var completed_quizzes := 0
		if lesson_progress:
			completed_quizzes = lesson_progress.get_completed_quizzes_count(lesson)
		_quiz_stats_value.text = "%d / %d" % [completed_quizzes, total_quizzes]
		_quiz_stats_block.show()
	else:
		_quiz_stats_block.hide()

	if has_done_reading:
		_goto_lesson_button.text = tr("Open Lesson")
	elif has_started:
		_goto_lesson_button.text = tr("Continue Lesson")
	else:
		_goto_lesson_button.text = tr("Start Lesson")


func _on_goto_lesson_pressed() -> void:
	if not lesson:
		return

	NavigationManager.navigate_to("%s" % [course_index.get_lesson_slug_from_path(lesson.bbcode_path)])
