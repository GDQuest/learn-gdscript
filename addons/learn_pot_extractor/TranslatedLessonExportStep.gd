@tool
extends EditorExportPlugin

const SHARED := preload("Shared.gd")
const LESSON_BUILDER := preload("TranslatedLessonBuilder.gd")


var _tr_blocks_set := {}


func _get_name() -> String:
	return "translated-lesson-builder"


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	var lesson_files := []
	var stack := ["res://course"]
	
	for lang in DirAccess.get_directories_at("res://i18n/"):
		var tr_blocks := SHARED.build_tr_blocks("res://i18n/%s/course.po" % [lang])
		_tr_blocks_set[lang] = tr_blocks


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if not path.begins_with("res://course") or not path.ends_with("/lesson.bbcode"):
		return
	
	var translation_reports := {}
	
	for lang in DirAccess.get_directories_at("res://i18n/"):
		var lesson_report := {"count": 0, "total": 0}
		translation_reports[lang] = lesson_report
		var lesson_text := LESSON_BUILDER.build_translated_lesson(path, lang, _tr_blocks_set[lang], lesson_report)
		lesson_report["percent"] = float(lesson_report.count) / float(lesson_report.total)
		
		var new_path := "%s.%s.bbcode" % [path.get_basename(), lang]
		add_file(new_path, lesson_text.to_utf8_buffer(), false)
	add_file(path.get_basename() + ".meta", JSON.stringify(translation_reports, "\t").to_utf8_buffer(), false)
