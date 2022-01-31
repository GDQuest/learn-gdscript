extends HBoxContainer



onready var _back_button := $BackButton
onready var _breadcrumbs_label := $BreadCrumbs as Label


func update_breadcrumbs(target: Resource) -> void:
	if target is Lesson:
		var lesson = target as Lesson
		var lesson_index := -1

		var i := 0
		for lesson_data in course.lessons:
			if lesson_data == lesson:
				lesson_index = i
				break

			i += 1

		if lesson_index >= 0:
			_breadcrumbs_label.text = "%s. %s" % [lesson_index + 1, lesson.title]
		else:
			_breadcrumbs_label.text = "%s" % [lesson.title]
		return

	if target is Practice:
		var practice = target as Practice
		# TODO: Should probably avoid relying on content ID for getting paths.
		var lesson_path = practice.practice_id.get_base_dir().plus_file("lesson.tres")

		var lesson: Lesson
		var lesson_index := -1

		var i := 0
		for lesson_data in course.lessons:
			if lesson_data.resource_path == lesson_path:
				lesson = lesson_data
				lesson_index = i
				break

			i += 1

		if lesson and lesson_index >= 0:
			_breadcrumbs_label.text = "%s. %s > %s" % [lesson_index + 1, lesson.title, practice.title]
		else:
			_breadcrumbs_label.text = "%s" % [practice.title]
		return

	_breadcrumbs_label.text = ""
