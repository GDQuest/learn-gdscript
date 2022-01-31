extends Object

const LETTERS_AND_DIGITS := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
const CHARACTER_COUNT := 62
const SUPPORTED_LESSON_RESOURCES := ["content", "practice", "quiz"]

# Recursively saves the course content: lessons, their order, their content, and
# their practices.
static func save_course(course: Course, file_path: String) -> bool:
	var moved_path := not file_path == course.resource_path
	var base_path = file_path.get_base_dir()
	var old_base_path = course.resource_path.get_base_dir()

	# Update paths of the Course resource and all sub-resources.
	course.take_over_path(file_path)

	for lesson_data in course.lessons:
		if lesson_data.resource_path.begins_with("lesson-"):
			var resource_path = base_path.plus_file(lesson_data.resource_path)
			lesson_data.take_over_path(resource_path)
		if moved_path:
			var resource_path = lesson_data.resource_path.replace(old_base_path, base_path)
			lesson_data.take_over_path(resource_path)

		for block_data in lesson_data.content_blocks:
			if block_data is Quiz:
				if block_data.quiz_id.begins_with("lesson-"):
					block_data.quiz_id = base_path.plus_file(block_data.quiz_id)
				if moved_path:
					block_data.quiz_id = block_data.quiz_id.replace(old_base_path, base_path)
			else:
				if block_data.content_id.begins_with("lesson-"):
					block_data.content_id = base_path.plus_file(block_data.content_id)
				if moved_path:
					block_data.content_id = block_data.content_id.replace(old_base_path, base_path)

		for practice_data in lesson_data.practices:
			if practice_data.practice_id.begins_with("lesson-"):
				practice_data.practice_id = base_path.plus_file(practice_data.practice_id)
			if moved_path:
				practice_data.practice_id = practice_data.practice_id.replace(old_base_path, base_path)

	# Start saving resources, top to bottom.
	var error = ResourceSaver.save(file_path, course)
	if not error == OK:
		printerr("Failed to save the Course resource at '%s', error code: %d" % [file_path, error])
		return false

	# TODO: Update the paths when "Save As" was used and the root resource was moved

	var had_errors := false
	var fs := Directory.new()

	for lesson_data in course.lessons:
		var lesson_dir = lesson_data.resource_path.get_base_dir()
		if not fs.dir_exists(lesson_dir):
			fs.make_dir_recursive(lesson_dir)

		error = ResourceSaver.save(lesson_data.resource_path, lesson_data)
		if not error == OK:
			printerr(
				(
					"Failed to save the Lesson resource at '%s', error code: %d"
					% [lesson_data.resource_path, error]
				)
			)
			had_errors = true
			continue

	return not had_errors

static func remove_obsolete(file_paths: Array) -> void:
	if file_paths.empty():
		return

	var fs := Directory.new()
	var error

	for file_path in file_paths:
		if not file_path.empty() and fs.file_exists(file_path):
			error = fs.remove(file_path)
			if error != OK:
				printerr(
					"Failed to remove an obsolete file at '%s', error code: %d" % [file_path, error]
				)

static func random_lesson_path(course: Course) -> String:
	var _file_tester := Directory.new()
	var base_path := course.resource_path.get_base_dir()
	var lesson_directory := "lesson-" + generate_random_path_slug()
	var dirpath := base_path.plus_file(lesson_directory)
	while _file_tester.dir_exists(dirpath):
		lesson_directory = "lesson-" + generate_random_path_slug()
		dirpath = base_path.plus_file(lesson_directory)
	return dirpath.plus_file("lesson.tres")

static func slugged_lesson_path(course: Course, slug: String) -> String:
	var base_path = course.resource_path.get_base_dir()
	var lesson_slug = "lesson-%s" % [slug]
	return base_path.plus_file(lesson_slug).plus_file("lesson.tres")

static func generate_random_lesson_subresource_path(lesson: Lesson, kind: String) -> String:
	var _file_tester := Directory.new()
	var base_path = lesson.resource_path.get_base_dir()
	assert(
		kind in SUPPORTED_LESSON_RESOURCES,
		"Resource name must be one of %s" % [SUPPORTED_LESSON_RESOURCES]
	)
	var block_file = "%s-%s.tres" % [kind, generate_random_path_slug()]
	var path = base_path.plus_file(block_file)
	while _file_tester.file_exists(path):
		block_file = "%s-%s.tres" % [kind, generate_random_path_slug()]
		path = base_path.plus_file(block_file)
	return path

static func generate_random_path_slug(length := 8) -> String:
	var text = ""
	for i in length:
		text += LETTERS_AND_DIGITS[randi() % CHARACTER_COUNT]
	return text

static func pack_playable_scene(instance: Node, base_path: String, keyword: String) -> PackedScene:
	var packed_instance := PackedScene.new()
	var error = packed_instance.pack(instance)
	if error != OK:
		printerr("Failed to pack the %s scene from the instance '%s': Error code %d" % [keyword, instance, error])
		return null

	var practice_path = base_path.plus_file("test-%s.tscn" % [keyword])
	error = ResourceSaver.save(practice_path, packed_instance)
	if error != OK:
		printerr("Failed to save the %s scene at '%s': Error code %d" % [keyword, practice_path, error])
		return null

	packed_instance.take_over_path(practice_path)
	return packed_instance
