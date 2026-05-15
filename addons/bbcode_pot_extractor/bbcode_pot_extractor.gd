@tool
extends EditorPlugin

const POT_FILES_PATH := "internationalization/locale/translations_pot_files"
const COURSE_POT_PATH := "res://i18n/course.pot"
const BBCODE_TRANSLATION_PARSER := preload("bbcode_translation_parser.gd")
const ENGINE_CALLER := preload("engine_caller.gd")
var _bbcode_parser := BBCODE_TRANSLATION_PARSER.new()


func _enter_tree() -> void:
	add_translation_parser_plugin(_bbcode_parser)
	
	add_tool_menu_item("Generate Course POT", _generate_course_pot)


func _exit_tree() -> void:
	remove_translation_parser_plugin(_bbcode_parser)
	
	remove_tool_menu_item("Generate Course POT")


func _generate_course_pot() -> void:
	var default_pots: PackedStringArray
	if ProjectSettings.has_setting(POT_FILES_PATH):
		default_pots = ProjectSettings.get_setting(POT_FILES_PATH)
		ProjectSettings.clear(POT_FILES_PATH)
	
	var lesson_files_arr := Array()
	for dir_path in DirAccess.get_directories_at("res://course"):
		if FileAccess.file_exists("res://course/%s/lesson.bbcode" % [dir_path]):
			lesson_files_arr.push_back("res://course/%s/lesson.bbcode" % [dir_path])
	
	lesson_files_arr.sort_custom(func(a: String, b: String) -> bool:
		a = a.get_base_dir().get_file()
		b = b.get_base_dir().get_file()
		
		var lesson_a_index := a.substr(7, a.find("-", 7) - 7)
		var lesson_b_index := b.substr(7, b.find("-", 7) - 7)
		
		return lesson_a_index.to_int() < lesson_b_index.to_int()
	)
	
	var lesson_files := PackedStringArray(lesson_files_arr)
	
	ProjectSettings.set_setting(POT_FILES_PATH, lesson_files)
	
	var localization_editor := ENGINE_CALLER.get_localization_editor()
	localization_editor.call("update_translations")
	localization_editor.call("emit_signal", "localization_changed")
	
	await get_tree().process_frame
	
	var last_modified_time := 0
	if FileAccess.file_exists(COURSE_POT_PATH):
		last_modified_time = FileAccess.get_modified_time(COURSE_POT_PATH)
	
	ENGINE_CALLER.template_generate(COURSE_POT_PATH)
	if FileAccess.file_exists(COURSE_POT_PATH):
		if last_modified_time == 0 or (last_modified_time > 0 and FileAccess.get_modified_time(COURSE_POT_PATH) > last_modified_time):
			print("Generated file at %s" % [COURSE_POT_PATH])
		else:
			print("Failed to generate file at %s" % [COURSE_POT_PATH])
	else:
		print("Failed to generate file at %s" % [COURSE_POT_PATH])
	
	if not default_pots.is_empty():
		ProjectSettings.set_setting(POT_FILES_PATH, default_pots)
	else:
		ProjectSettings.clear(POT_FILES_PATH)
	if ProjectSettings.has_setting(POT_FILES_PATH):
		localization_editor.call("update_translations")
		localization_editor.call("emit_signal", "localization_changed")
