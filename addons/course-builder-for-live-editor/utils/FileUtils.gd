extends Object


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
			if block_data.resource_path.begins_with("lesson-"):
				var resource_path = base_path.plus_file(block_data.resource_path)
				block_data.take_over_path(resource_path)
			if moved_path:
				var resource_path = block_data.resource_path.replace(old_base_path, base_path)
				block_data.take_over_path(resource_path)

		for practice_data in lesson_data.practices:
			if practice_data.resource_path.begins_with("lesson-"):
				var resource_path = base_path.plus_file(practice_data.resource_path)
				practice_data.take_over_path(resource_path)
			if moved_path:
				var resource_path = practice_data.resource_path.replace(old_base_path, base_path)
				practice_data.take_over_path(resource_path)

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

		for block_data in lesson_data.content_blocks:
			error = ResourceSaver.save(block_data.resource_path, block_data)
			if not error == OK:
				printerr(
					(
						"Failed to save the ContentBlock resource at '%s', error code: %d"
						% [block_data.resource_path, error]
					)
				)
				had_errors = true
				continue

		for practice_data in lesson_data.practices:
			error = ResourceSaver.save(practice_data.resource_path, practice_data)
			if not error == OK:
				printerr(
					(
						"Failed to save the Practice resource at '%s', error code: %d"
						% [practice_data.resource_path, error]
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
	var base_path = course.resource_path.get_base_dir()
	var lesson_slug = "lesson-%d" % [randi() % 100000 + 10000]
	return base_path.plus_file(lesson_slug).plus_file("lesson.tres")


static func slugged_lesson_path(course: Course, slug: String) -> String:
	var base_path = course.resource_path.get_base_dir()
	var lesson_slug = "lesson-%s" % [slug]
	return base_path.plus_file(lesson_slug).plus_file("lesson.tres")


static func random_content_block_path(lesson: Lesson) -> String:
	var base_path = lesson.resource_path.get_base_dir()
	var block_file = "content-%d.tres" % [randi() % 100000 + 10000]
	return base_path.plus_file(block_file)


static func random_practice_path(lesson: Lesson) -> String:
	var base_path = lesson.resource_path.get_base_dir()
	var practice_file = "practice-%d.tres" % [randi() % 100000 + 10000]
	return base_path.plus_file(practice_file)
