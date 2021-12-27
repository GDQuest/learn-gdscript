extends PanelContainer

const VALUE_CHECK_NONE := preload("res://ui/icons/checkmark_none.svg")
const VALUE_CHECK_PASSED := preload("res://ui/icons/checkmark_valid.svg")
const VALUE_COLOR_NONE := Color(0.290196, 0.294118, 0.388235)
const VALUE_COLOR_PASSED := Color(0.239216, 1, 0.431373)

var lesson: Lesson setget set_lesson
var lesson_progress: LessonProgress setget set_lesson_progress

onready var _title_label := $MarginContainer/Layout/TitleLabel as Label
onready var _reading_stats_block := $MarginContainer/Layout/ReadingStats as Control
onready var _reading_stats_value := $MarginContainer/Layout/ReadingStats/ValueLabel as Label
onready var _reading_stats_icon := $MarginContainer/Layout/ReadingStats/ValueIcon as TextureRect
onready var _quiz_stats_block := $MarginContainer/Layout/QuizStats as Control
onready var _quiz_stats_value := $MarginContainer/Layout/QuizStats/ValueLabel as Label
onready var _practice_stats_block := $MarginContainer/Layout/PracticeStats as Control
onready var _practice_stats_value := $MarginContainer/Layout/PracticeStats/ValueLabel as Label

onready var _goto_lesson_button := $MarginContainer/Layout/Buttons/GoToButton as Button


func _ready() -> void:
	_update_visuals()
	
	_goto_lesson_button.connect("pressed", self, "_on_goto_lesson_pressed")


func set_lesson(value: Lesson) -> void:
	lesson = value
	_update_visuals()


func set_lesson_progress(value: LessonProgress) -> void:
	lesson_progress = value
	_update_visuals()


func _update_visuals() -> void:
	if not is_inside_tree():
		return
	
	if lesson:
		_title_label.text = lesson.title
		
		if lesson_progress and lesson_progress.completed_reading:
			_reading_stats_value.text = "%d / %d" % [1, 1]
			_reading_stats_icon.texture = VALUE_CHECK_PASSED
			_reading_stats_icon.modulate = VALUE_COLOR_PASSED
		else:
			_reading_stats_value.text = "%d / %d" % [0, 1]
			_reading_stats_icon.texture = VALUE_CHECK_NONE
			_reading_stats_icon.modulate = VALUE_COLOR_NONE
		
		var total_practices := lesson.practices.size()
		var completed_practices := 0
		if lesson_progress:
			completed_practices = lesson_progress.get_completed_practices_count(lesson.practices)
		_practice_stats_value.text = "%d / %d" % [completed_practices, total_practices]

		var total_quizzes := lesson.get_quzzes_count()
		if total_quizzes > 0:
			var completed_quizzes := 0
			if lesson_progress:
				completed_quizzes = lesson_progress.get_completed_quizzes_count(lesson.get_quizzes())
			_quiz_stats_value.text = "%d / %d" % [completed_quizzes, total_quizzes]
			_quiz_stats_block.show()
		else:
			_quiz_stats_block.hide()


func _on_goto_lesson_pressed() -> void:
	if not lesson:
		return
	
	NavigationManager.navigate_to(lesson.resource_path)
