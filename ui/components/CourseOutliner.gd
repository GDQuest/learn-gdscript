extends PanelContainer

const CourseLessonList := preload("res://ui/components/CourseLessonList.gd")

var course: Course setget set_course

onready var _title_label := $MarginContainer/Layout/TitleBox/TitleLabel as Label
onready var _lesson_list := $MarginContainer/Layout/HBoxContainer/LessonList as CourseLessonList
onready var _lesson_details := $MarginContainer/Layout/HBoxContainer/LessonDetails as Control
onready var _lesson


func _ready() -> void:
	_update_outliner_index()
	
	_lesson_list.connect("lesson_selected", self, "_on_lesson_selected")


func set_course(value: Course) -> void:
	course = value
	_update_outliner_index()


func _update_outliner_index() -> void:
	_lesson_list.clear()
	_lesson_details.hide()
	_title_label.text = ""
	if not course:
		return
	
	_title_label.text = course.title
	
	var lesson_index := 0
	for lesson_data in course.lessons:
		lesson_data = lesson_data as Lesson
		
		var completion := randi() % 101
		_lesson_list.add_item(lesson_index, lesson_data.title, completion)
		lesson_index += 1


func _on_lesson_selected(lesson_index: int) -> void:
	if not course or lesson_index < 0 or lesson_index >= course.lessons.size():
		return
	
	var lesson_data := course.lessons[lesson_index] as Lesson
	_lesson_details.lesson = lesson_data
	_lesson_details.show()
