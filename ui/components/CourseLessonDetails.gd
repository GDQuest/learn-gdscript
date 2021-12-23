extends PanelContainer

var lesson: Lesson setget set_lesson

onready var _title_label := $MarginContainer/Layout/TitleLabel as Label
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


func _update_visuals() -> void:
	if not is_inside_tree():
		return
	
	if lesson:
		_title_label.text = lesson.title
		
		var total_practices := lesson.practices.size()
		var completed_practices := 0
		_practice_stats_value.text = "%d / %d" % [completed_practices, total_practices]

		var total_quizzes := 0
		for content_item in lesson.content_blocks:
			if content_item is Quizz:
				total_quizzes += 1
		
		var completed_quizzes := 0
		if total_quizzes > 0:
			_quiz_stats_block.show()
			_quiz_stats_value.text = "%d / %d" % [completed_quizzes, total_quizzes]
		else:
			_quiz_stats_block.hide()


func _on_goto_lesson_pressed() -> void:
	if not lesson:
		return
	
	NavigationManager.navigate_to(lesson.resource_path)
