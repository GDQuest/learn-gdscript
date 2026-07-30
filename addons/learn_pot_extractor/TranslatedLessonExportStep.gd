@tool
## Export plugin that adds rebuilt localized lessons and completeness metadata to exports.
extends EditorExportPlugin

const SHARED := preload("Shared.gd")
const LESSON_BUILDER := preload("TranslatedLessonBuilder.gd")


var _tr_blocks_set := {}
var _locales := PackedStringArray()
var _locale_reports := {}


func _get_name() -> String:
	return "translated-lesson-builder"


## Loads each translation/PO catalog once before building translated lesson
## files.
func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	_tr_blocks_set.clear()
	_locales.clear()
	_locale_reports.clear()
	var ignored_patterns := ["images", "README.md"]
	for lang in DirAccess.get_directories_at("res://i18n/"):
		if lang in ignored_patterns:
			continue
		var course_catalog_path := "res://i18n/%s/course.po" % [lang]
		if not FileAccess.file_exists(course_catalog_path):
			printerr("Translation export: skipping locale '%s'; missing '%s'." % [lang, course_catalog_path])
			continue
		_locales.append(lang)
		_tr_blocks_set[lang] = SHARED.build_tr_lookup(SHARED.build_tr_blocks(course_catalog_path))
		_locale_reports[lang] = {"count": 0, "total": 0, "completed_lessons": 0, "total_lessons": 0}
	print("Translation export: loaded %d locale catalogs." % [_locales.size()])


## Rebuilds one exported source lesson for every loaded locale and adds its metadata.
func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if not path.begins_with("res://course") or not path.ends_with("/lesson.bbcode"):
		return

	var lesson := LESSON_BUILDER.parse_lesson(path)
	if not lesson:
		printerr("Translation export: skipping '%s'; parsing failed." % [path])
		return

	var translation_reports := {}

	for lang in _locales:
		var lesson_report := {"count": 0, "total": 0}
		translation_reports[lang] = lesson_report
		var lesson_text := LESSON_BUILDER.build_translated_lesson(lesson, _tr_blocks_set[lang], lesson_report)
		lesson_report["percent"] = float(lesson_report.count) / float(lesson_report.total) if lesson_report.total > 0 else 1.0
		_locale_reports[lang].count += lesson_report.count
		_locale_reports[lang].total += lesson_report.total
		_locale_reports[lang].total_lessons += 1
		if lesson_report.count >= lesson_report.total:
			_locale_reports[lang].completed_lessons += 1

		var new_path := "%s.%s.bbcode" % [path.get_basename(), lang]
		add_file(new_path, lesson_text.to_utf8_buffer(), false)
	add_file(path.get_basename() + ".meta", JSON.stringify(translation_reports, "\t").to_utf8_buffer(), false)


func _export_end() -> void:
	print("Completed translated lesson build")
	for lang in _locales:
		var locale_report: Dictionary = _locale_reports[lang]
		var strings_percent := float(locale_report.count) / float(locale_report.total) if locale_report.total > 0 else 1.0
		var lessons_percent := float(locale_report.completed_lessons) / float(locale_report.total_lessons) if locale_report.total_lessons > 0 else 1.0
		print("%s:" % [lang])
		print("- %d out of %d strings translated (%.1f%%)" % [locale_report.count, locale_report.total, strings_percent * 100.0])
		print("- %d out of %d lessons are fully translated (%.1f%%)" % [locale_report.completed_lessons, locale_report.total_lessons, lessons_percent * 100.0])
