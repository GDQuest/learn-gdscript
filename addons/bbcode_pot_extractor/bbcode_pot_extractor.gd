@tool
extends EditorPlugin

const POT_FILES_PATH := "internationalization/locale/translations_pot_files"
const COURSE_POT_PATH := "res://i18n/course.pot"
const APPLICATION_POT_PATH := "res://i18n/application.pot"
const ERROR_POT_PATH := "res://i18n/error_database.pot"
const ERROR_DATABASE := "res://script_checking/error_database.csv"

const BBCODE_TRANSLATION_PARSER := preload("bbcode_translation_parser.gd")
const CSV_TRANSLATION_PARSER := preload("error_code_pot_extractor.gd")
const ENGINE_CALLER := preload("engine_caller.gd")

var _bbcode_parser := BBCODE_TRANSLATION_PARSER.new()
var _error_code_parser := CSV_TRANSLATION_PARSER.new()
var _current_pots: PackedStringArray


func _enter_tree() -> void:
	add_translation_parser_plugin(_bbcode_parser)
	add_translation_parser_plugin(_error_code_parser)
	
	add_tool_menu_item("Generate Course POT", _generate_course_pot)
	add_tool_menu_item("Generate Application POT", _generate_application_pot)
	add_tool_menu_item("Generate Error Database POT", _generate_error_database_pot)


func _exit_tree() -> void:
	remove_translation_parser_plugin(_bbcode_parser)
	remove_translation_parser_plugin(_error_code_parser)
	
	remove_tool_menu_item("Generate Course POT")
	remove_tool_menu_item("Generate Application POT")
	remove_tool_menu_item("Generate Error Database POT")


func _generate_error_database_pot() -> void:
	await _set_pot_files([ERROR_DATABASE])
	
	var last_modified_time := 0
	if FileAccess.file_exists(ERROR_POT_PATH):
		last_modified_time = FileAccess.get_modified_time(ERROR_POT_PATH)
	
	ENGINE_CALLER.template_generate(ERROR_POT_PATH)
	
	if FileAccess.file_exists(ERROR_POT_PATH):
		if last_modified_time == 0 or (last_modified_time > 0 and FileAccess.get_modified_time(ERROR_POT_PATH) > last_modified_time):
			print("Generated file at %s" % [ERROR_POT_PATH])
		else:
			print("Failed to generate file at %s" % [ERROR_POT_PATH])
	else:
		print("Failed to generate file at %s" % [ERROR_POT_PATH])
	
	_recover_pot_files()


func _generate_application_pot() -> void:
	var translatable_files := []
	_get_all_tscns_with_labels("res://", translatable_files)
	_get_all_gdscript_with_tr("res://", translatable_files)
	
	await _set_pot_files(translatable_files)
	
	var last_modified_time := 0
	if FileAccess.file_exists(APPLICATION_POT_PATH):
		last_modified_time = FileAccess.get_modified_time(APPLICATION_POT_PATH)
	
	ENGINE_CALLER.template_generate(APPLICATION_POT_PATH)
	
	if FileAccess.file_exists(APPLICATION_POT_PATH):
		if last_modified_time == 0 or (last_modified_time > 0 and FileAccess.get_modified_time(APPLICATION_POT_PATH) > last_modified_time):
			print("Generated file at %s" % [APPLICATION_POT_PATH])
		else:
			print("Failed to generate file at %s" % [APPLICATION_POT_PATH])
	else:
		print("Failed to generate file at %s" % [APPLICATION_POT_PATH])
	
	_recover_pot_files()


func _get_all_tscns_with_labels(root: String, out_files: Array) -> void:
	var dir := DirAccess.open(root)
	out_files.append_array(Array(dir.get_files()).filter(func(filename: String) -> bool:
		if filename.get_extension() != "tscn":
			return false
		var packed_scene := load(root.path_join(filename)) as PackedScene
		var state := packed_scene.get_state()
		for i in state.get_node_count():
			match state.get_node_type(i):
				&"Label", &"RichTextLabel", &"Button":
					return true
		return false
	).map(func(filename: String) -> String:
		return root.path_join(filename)
	))
	for other_dir in dir.get_directories():
		_get_all_tscns_with_labels(root.path_join(other_dir), out_files)


func _get_all_gdscript_with_tr(root: String, out_files: Array) -> void:
	var dir := DirAccess.open(root)
	out_files.append_array(Array(dir.get_files()).filter(func(filename: String) -> bool:
		if filename.get_extension() != "gd":
			return false
		var text := FileAccess.open(root.path_join(filename), FileAccess.READ).get_as_text()
		if not text.contains(" tr("):
			return false
		return true
	).map(func(filename: String) -> String:
		return root.path_join(filename)
	))
	for other_dir in dir.get_directories():
		_get_all_gdscript_with_tr(root.path_join(other_dir), out_files)


func _set_pot_files(paths: PackedStringArray) -> void:
	if ProjectSettings.has_setting(POT_FILES_PATH):
		_current_pots = ProjectSettings.get_setting(POT_FILES_PATH)
		ProjectSettings.clear(POT_FILES_PATH)
	ProjectSettings.set_setting(POT_FILES_PATH, paths)
	var localization_editor := ENGINE_CALLER.get_localization_editor()
	localization_editor.call("update_translations")
	localization_editor.call("emit_signal", "localization_changed")
	
	await get_tree().process_frame


func _recover_pot_files() -> void:
	if _current_pots.is_empty() and ProjectSettings.has_setting(POT_FILES_PATH):
		ProjectSettings.clear(POT_FILES_PATH)
	else:
		ProjectSettings.set_setting(POT_FILES_PATH, _current_pots)
		var localization_editor := ENGINE_CALLER.get_localization_editor()
		localization_editor.call("update_translations")
		localization_editor.call("emit_signal", "localization_changed")
		_current_pots.clear()


func _generate_course_pot() -> void:
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
	
	await _set_pot_files(lesson_files)
	
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
	
	_recover_pot_files()
