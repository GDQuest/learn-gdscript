@abstract
class_name CourseIndex
extends RefCounted


class PracticeInfo:
	var index := -1
	var id := ""
	var title := ""


class LessonInfo:
	var number := 0
	var path := ""
	var slug := ""
	var title := ""
	var practices: Array[PracticeInfo] = []


var lessons: Array[LessonInfo] = []
var _lesson_info_by_path: Dictionary[String, LessonInfo] = {}
var _lesson_cache: Dictionary[String, BBCodeParser.ParseNode] = {}
var _lesson_parser := LessonBBCodeParser.new()
var _is_initialized := false


@abstract
func get_title() -> String
@abstract
func get_lessons_count() -> int
@abstract
func get_lesson_path(i: int) -> String
@abstract
## Returns the lesson path for its one-based position in the course.
func get_lesson_path_from_number(lesson_number: int) -> String
@abstract
func get_lesson_path_from_slug(slug: String) -> String
@abstract
func get_lesson_slug(i: int) -> String
@abstract
func get_lesson_slug_from_path(path: String) -> String
@abstract
func get_course_id() -> String
@abstract
func get_real_slug_from_slug(slug: String) -> String
@abstract
func get_lesson_number(lesson_path: String) -> int


## Loads, parses, and indexes every lesson in the course.
func initialize() -> void:
	if _is_initialized:
		return

	if not TranslationManager.translation_changed.is_connected(_on_translation_changed):
		TranslationManager.translation_changed.connect(_on_translation_changed)

	lessons.clear()
	_lesson_info_by_path.clear()
	_lesson_cache.clear()
	for lesson_index in get_lessons_count():
		var lesson_path := get_lesson_path(lesson_index)
		var lesson_info := LessonInfo.new()
		lesson_info.number = get_lesson_number(lesson_path)
		lesson_info.path = lesson_path
		lesson_info.slug = get_lesson_slug_from_path(lesson_path)
		lessons.append(lesson_info)
		_lesson_info_by_path[lesson_path] = lesson_info
		var lesson := get_lesson(lesson_path)
		assert(lesson != null, "Failed to initialize lesson index for '%s'." % lesson_path)
	_is_initialized = true


func get_lesson(lesson_path: String) -> BBCodeParser.ParseNode:
	var effective_lesson_path := lesson_path
	if TranslationManager.current_language != TranslationManager.DEFAULT_LOCALE:
		effective_lesson_path = "%s.%s.%s" % [
			lesson_path.get_basename(),
			TranslationManager.current_language,
			lesson_path.get_extension(),
		]
		if not FileAccess.file_exists(effective_lesson_path):
			effective_lesson_path = lesson_path

	if _lesson_cache.has(effective_lesson_path):
		return _lesson_cache[effective_lesson_path]

	var result := _lesson_parser.parse_file(effective_lesson_path)
	if not result.is_success():
		push_error(
			"CourseIndex: Failed to parse lesson file %s. Fix the reported BBCode errors before loading this lesson:"
			% effective_lesson_path
		)
		for error: BBCodeParser.ParseError in result.errors:
			push_error("  " + error.format())
		return null

	if result.warnings:
		print(
			"CourseIndex: Parse warnings when loading lesson from bbcode file %s:" % effective_lesson_path
		)
		for warning: BBCodeParser.ParseError in result.warnings:
			print("  ", warning.format())

	if (
		result.root == null or result.root.children.is_empty()
		or not result.root.children[0] is BBCodeParser.ParseNode
	):
		push_error(
			"CourseIndex: Parsed lesson file %s has no [lesson] root." % effective_lesson_path
		)
		return null

	var lesson: BBCodeParser.ParseNode = result.root.children[0]
	_lesson_cache[effective_lesson_path] = lesson
	var lesson_info := _index_lesson(lesson, lesson_path)
	_lesson_info_by_path[effective_lesson_path] = lesson_info
	return lesson


func _index_lesson(lesson: BBCodeParser.ParseNode, lesson_path: String) -> LessonInfo:
	var lesson_info := get_lesson_info(lesson_path)
	lesson_info.title = BBCodeUtils.get_lesson_title(lesson)
	lesson_info.practices.clear()
	for practice_index in BBCodeUtils.get_lesson_practice_count(lesson):
		var practice := BBCodeUtils.get_lesson_practice(lesson, practice_index)
		var practice_info := PracticeInfo.new()
		practice_info.index = practice_index
		practice_info.id = BBCodeUtils.get_practice_id(practice)
		practice_info.title = BBCodeUtils.get_practice_title(practice)
		lesson_info.practices.append(practice_info)
	return lesson_info


func _on_translation_changed() -> void:
	_is_initialized = false
	initialize()


func get_lesson_info(lesson_path: String) -> LessonInfo:
	return _lesson_info_by_path[lesson_path]


func get_practice_info(lesson_path: String, practice_id: String) -> PracticeInfo:
	var lesson_info := get_lesson_info(lesson_path)
	for practice_info: PracticeInfo in lesson_info.practices:
		if practice_info.id == practice_id:
			return practice_info
	return null


func get_practice(lesson_path: String, practice_id: String) -> BBCodeParser.ParseNode:
	var practice_info := get_practice_info(lesson_path, practice_id)
	if not practice_info:
		return null
	return BBCodeUtils.get_lesson_practice(get_lesson(lesson_path), practice_info.index)
