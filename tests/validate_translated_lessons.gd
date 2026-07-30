extends Node

const SHARED := preload("res://addons/learn_pot_extractor/Shared.gd")
const LESSON_BUILDER := preload("res://addons/learn_pot_extractor/TranslatedLessonBuilder.gd")


func _ready() -> void:
	var parser := LessonBBCodeParser.new()
	var course_index := CourseIndexPaths.get_course_index_instance()
	print("Testing translations. Validating %d lesson(s)" % course_index.get_lessons_count())

	var locales := PackedStringArray()
	for directory in DirAccess.get_directories_at("res://i18n"):
		if FileAccess.file_exists("res://i18n/%s/course.po" % directory):
			locales.append(directory)
	locales.sort()
	print("Found %d locale(s): %s" % [locales.size(), ", ".join(locales)])
	print("Validating translations...")

	var tr_blocks_set := { }
	var failures := { }
	var lessons_count := course_index.get_lessons_count()

	for locale: String in locales:
		var catalog_path := "res://i18n/%s/course.po" % locale
		tr_blocks_set[locale] = SHARED.build_tr_lookup(SHARED.build_tr_blocks(catalog_path))
		failures[locale] = { }

	for lesson_index in lessons_count:
		var lesson_path := course_index.get_lesson_path(lesson_index)
		var source_result := parser.parse_file(lesson_path)
		if not source_result.is_success():
			failures["en"] = failures.get("en", { })
			failures["en"][lesson_path] = _format_errors(source_result)
			continue

		var lesson: BBCodeParser.ParseNode = source_result.root.children[0]
		for locale: String in locales:
			var translated_text := LESSON_BUILDER.build_translated_lesson(
				lesson,
				tr_blocks_set[locale],
				{ "count": 0, "total": 0 },
			)
			var translated_path := "%s.%s.bbcode" % [lesson_path.get_basename(), locale]
			var translated_result := parser.parse_text(translated_text, translated_path)
			if not translated_result.is_success():
				failures[locale][lesson_path] = _format_errors(translated_result)

	_print_report(failures, locales, lessons_count)

	var has_failures := false
	for locale: String in failures:
		if not failures[locale].is_empty():
			has_failures = true
			break

	get_tree().quit(1 if has_failures else 0)


func _format_errors(result: BBCodeParser.ParseResult) -> PackedStringArray:
	var errors := PackedStringArray()
	for error: BBCodeParser.ParseError in result.errors:
		errors.append(error.format())
	return errors


func _print_report(failures: Dictionary, locales: PackedStringArray, lessons_count: int) -> void:
	var failure_count := 0
	for locale: String in failures:
		failure_count += failures[locale].size()

	if failure_count == 0:
		print(
			"No errors found! Validated %d translated lessons across %d locales."
			% [lessons_count, locales.size()]
		)
		return

	print("Translated lesson parse failures: %d" % failure_count)
	for locale: String in failures:
		var locale_failures: Dictionary = failures[locale]
		if locale_failures.is_empty():
			continue
		print("\n%s (%d)" % [locale, locale_failures.size()])
		for lesson_path in locale_failures:
			print("  %s" % lesson_path)
			for error: String in locale_failures[lesson_path]:
				print("    %s" % error)
