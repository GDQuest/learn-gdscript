@tool
extends EditorScript

const COURSE_RESOURCE_PATH := "res://course/CourseLearnGDScriptIndex.gd"
const VISUAL_ELEMENT_EXTENSIONS := ["tscn", "png", "jpg", "jpeg", "svg", "gif"]


func _run() -> void:
	print("[TEST] Testing all resource paths...")

	if not ResourceLoader.exists(COURSE_RESOURCE_PATH):
		printerr(
			"Course resource at path '%s' does not exist. Aborting test." % [COURSE_RESOURCE_PATH],
		)
		return

	var course_script = ResourceLoader.load(COURSE_RESOURCE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not course_script:
		printerr(
			"Failed to load the course resource at '%s'. Aborting test." % [COURSE_RESOURCE_PATH],
		)

	var course: CourseIndex = course_script.new()

	var error_messages := PackedStringArray()
	var index := 1
	for i in course.get_lessons_count():
		var lesson_path := course.get_lesson_path(i)
		var lesson := NavigationManager.get_navigation_resource(lesson_path)
		var lesson_title := BBCodeUtils.get_lesson_title(lesson)
		var block_count := BBCodeUtils.get_lesson_block_count(lesson)
		for l in block_count:
			var block_type := BBCodeUtils.get_lesson_block_type(lesson, l)
			var block: BBCodeParser.ParseNode = lesson.children[l]
			if block_type == BBCodeParserData.Tag.VISUAL:
				var visual_path := BBCodeUtils.get_visual_path(block)
				if not _is_valid(lesson, visual_path, VISUAL_ELEMENT_EXTENSIONS):
					error_messages.append(
						(
							"Lesson %s (%s): visual element at path '%s' is not valid."
							% [index, lesson_title, visual_path]
						),
					)

		var practice_index := 1
		var practice_count := BBCodeUtils.get_lesson_practice_count(lesson)
		for l in practice_count:
			var practice := BBCodeUtils.get_lesson_practice(lesson, l)
			var practice_title := BBCodeUtils.get_practice_title(practice)
			var validator_path := BBCodeUtils.get_practice_validator_path(practice)
			if not _is_valid(lesson, validator_path, ["gd"]):
				error_messages.append(
					(
						"Lesson %s (%s) / Practice %s (%s): validator script at path '%s' is not valid."
						% [
							index,
							lesson_title,
							practice_index,
							practice_title,
							validator_path,
						]
					),
				)
			var slice_path := BBCodeUtils.get_practice_script_slice_path(practice)
			if not _is_valid(lesson, slice_path):
				error_messages.append(
					(
						"Lesson %s (%s) / Practice %s (%s): script slice at path '%s' is not valid."
						% [
							index,
							lesson_title,
							practice_index,
							practice_title,
							slice_path,
						]
					),
				)
		index += 1

	var count := error_messages.size()
	if count > 0:
		print("%s invalid resources found." % count)
		print("\n".join(error_messages))
	else:
		print("No invalid resources found!")
	print("Done.")


# Returns true if the path is valid, whether it's relative or absolute.
func _is_valid(resource: BBCodeParser.ParseNode, path: String, valid_extensions := ["tres"]) -> bool:
	if path.is_empty():
		return true
	if not path.get_extension().to_lower() in valid_extensions:
		return false

	var test_path := path
	if test_path.is_relative_path():
		test_path = resource.resource_path.get_base_dir().path_join(test_path)
	return FileAccess.file_exists(test_path)
