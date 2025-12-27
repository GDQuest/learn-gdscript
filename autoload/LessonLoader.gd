# Temporary adapter for loading lessons from BBCode files instead of the
# original Godot resource files. This is to migrate gradually from .tres to
# .bbcode format.
#
# TODO: Remove this when the migration to BBCode is complete.
#
# When removing this, also:
#
# - Remove the LessonLoader.gd autoload from the project
# - Update NavigationManager to load lessons directly from BBCode files
# - Delete all the lesson.tres files + course.tres from the course/ directory
# - Replace with a new GDScript index file that lists all lessons and their paths
# - Delete related resource files: ContentBlock.gd, CodeBlock.gd, Quiz*.gd,
# Practice.gd, Lesson.gd (only if they are no longer needed by the runtime)
extends Node


# Loads a lesson from either a BBCode file or falls back to the original Godot
# resources (.tres files). The tres_path should be the path to the lesson.tres
# file. Returns the Lesson resource that the UI needs to display.
#
# Set force_tres_fallback to true to force loading from .tres files even if .bbcode files exists
static func load_lesson(tres_path: String, force_tres_fallback := false) -> Lesson:
	var _parser := LessonBBCodeParser.new()

	if force_tres_fallback:
		print("LessonLoader.gd: Loading lesson from original .tres file: ", tres_path)
		return load(tres_path) as Lesson

	var base_dir := tres_path.get_base_dir()
	var bbcode_path := base_dir.plus_file("lesson.bbcode")
	var file := File.new()
	if file.file_exists(bbcode_path):
		var result := _parser.parse_file(bbcode_path)

		if result.errors:
			push_error("LessonLoader.gd: Parse errors when loading lesson from bbcode file %s:" % bbcode_path)
			for error in result.errors:
				push_error("  " + error.format())
			return null

		if result.warnings:
			print("LessonLoader.gd: Parse warnings when loading lesson from bbcode file %s:" % bbcode_path)
			for warning in result.warnings:
				print("  ", warning.format())
		# Copy resource_path from tres to maintain compatibility with existing code
		# that relies on lesson.resource_path for progress tracking, navigation, etc.

		# TODO: This also needs to be adapted: navigation, progress tracking, etc. as
		# well as page slugs should probably be encoded in the new TOC file,
		# probably a GDScript file. For progress tracking and remembering
		# scrolling position we used blocks with unique ids BUT, now I'd model
		# it more like the browser: possibly have a TOC on the left generated from headings
		# and use those as anchors for navigation and progress tracking. Or use
		# scroll % + number of completed quizzes for tracking progress through a lesson.
		#
		# Practices can still have an ID separate from the lesson resource path for
		# tracking practice completion.
		result.lesson.resource_path = tres_path
		return result.lesson
	else:
		print("LessonLoader.gd: No bbcode file found, loading tres: ", tres_path)
		return load(tres_path) as Lesson
