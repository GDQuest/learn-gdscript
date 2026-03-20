@tool
extends EditorScript

const COURSE_RESOURCE_PATH := "res://course/course-learn-gdscript.tres"
const VISUAL_ELEMENT_EXTENSIONS := ["tscn", "png", "jpg", "jpeg", "svg", "gif"]

var _file_tester := File.new()


func _run() -> void:
	print("[TEST] Testing all resource paths...")

	if not ResourceLoader.exists(COURSE_RESOURCE_PATH):
		printerr(
			"Course resource at path '%s' does not exist. Aborting test." % [COURSE_RESOURCE_PATH]
		)
		return

	var course = ResourceLoader.load(COURSE_RESOURCE_PATH, "", true)
	if not course:
		printerr(
			"Failed to load the course resource at '%s'. Aborting test." % [COURSE_RESOURCE_PATH]
		)

	var error_messages := PackedStringArray()
	var index := 1
	for lesson in course.lessons:
		for content_block in lesson.content_blocks:
			if not _is_valid(lesson, content_block.visual_element_path, VISUAL_ELEMENT_EXTENSIONS):
				error_messages.append(
					(
						"Lesson %s (%s): visual element at path '%s' is not valid."
						% [index, lesson.title, content_block.visual_element_path]
					)
				)

		var practice_index := 1
		for practice in lesson.practices:
			if not _is_valid(lesson, practice.validator_script_path, ["gd"]):
				error_messages.append(
					(
						"Lesson %s (%s) / Practice %s (%s): validator script at path '%s' is not valid."
						% [
							index,
							lesson.title,
							practice_index,
							practice.title,
							practice.validator_script_path
						]
					)
				)
			if not _is_valid(lesson, practice.script_slice_path):
				error_messages.append(
					(
						"Lesson %s (%s) / Practice %s (%s): script slice at path '%s' is not valid."
						% [
							index,
							lesson.title,
							practice_index,
							practice.title,
							practice.script_slice_path
						]
					)
				)
		index += 1

	var count := error_messages.size()
	if count > 0:
		print("%s invalid resources found." % count)
		"\n".join(print(error_messages))
	else:
		print("No invalid resources found!")
	print("Done.")


# Returns true if the path is valid, whether it's relative or absolute.
func _is_valid(resource: Resource, path: String, valid_extensions := ["tres"]) -> bool:
	if path.is_empty():
		return true
	if not path.get_extension().to_lower() in valid_extensions:
		return false

	var test_path := path
	if test_path.is_rel_path():
		test_path = resource.resource_path.get_base_dir().path_join(test_path)
	return _file_tester.file_exists(test_path)
