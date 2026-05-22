

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

static var POT_PATTERN := RegEx.create_from_string(
	r'(?<comment>(?:#[^\n]+\n)+)?' +
	r'(?<ctxt>msgctxt "(?:\\.|[^"\\])*"\n)?' +
	r'(?<id>msgid (?:""\n(?:"(?:\\.|[^"\\])*"\n)+|"(?:\\.|[^"\\])*"\n))' +
	r'(?<str>msgstr (?:""\n(?:"(?:\\.|[^"\\])*"\n)+|"(?:\\.|[^"\\])*"\n))'
)

var _bbcode_parser := BBCODE_TRANSLATION_PARSER.new()
var _error_code_parser := CSV_TRANSLATION_PARSER.new()
var _current_pots: PackedStringArray
var _running := false


func _enter_tree() -> void:
	add_translation_parser_plugin(_bbcode_parser)
	add_translation_parser_plugin(_error_code_parser)
	
	add_tool_menu_item("Generate Course POT", _generate_course_pot)
	add_tool_menu_item("Generate Application POT", _generate_application_pot)
	add_tool_menu_item("Generate Error Database POT", _generate_error_database_pot)
	add_tool_menu_item("Slipstream Existing Translations", _slipstream_existing_translations)
	add_tool_menu_item("Generate All POT files", _generate_all_pot_files)


func _exit_tree() -> void:
	remove_translation_parser_plugin(_bbcode_parser)
	remove_translation_parser_plugin(_error_code_parser)
	
	remove_tool_menu_item("Generate Course POT")
	remove_tool_menu_item("Generate Application POT")
	remove_tool_menu_item("Generate Error Database POT")
	remove_tool_menu_item("Slipstream Existing Translations")
	remove_tool_menu_item("Generate All POT files")


func _generate_all_pot_files() -> void:
	await _generate_course_pot()
	await _generate_application_pot()
	await _generate_error_database_pot()
	await _slipstream_existing_translations()


func _slipstream_existing_translations() -> void:
	if not FileAccess.file_exists("res://i18n/course.pot"):
		print("Course pot not created yet")
		return
	
	if _running:
		return
	_running = true
	
	var course_pot := FileAccess.open("res://i18n/course.pot", FileAccess.READ).get_as_text()
	var first_entry_idx := course_pot.find("#: ")
	var course_header := course_pot.substr(0, first_entry_idx-1)
	
	var course_blocks := []
	
	var missing_strings_report := []
	
	var results := POT_PATTERN.search_all(course_pot, first_entry_idx)
	for result in results:
		var comments := _parse_course_comment(result)
		var context := result.get_string("ctxt").substr(9, result.get_string("ctxt").length()-11)
		var id := _parse_course_string(result, true)
		
		course_blocks.push_back({"comments": comments, "context": context, "id": id})
	
	for lang in DirAccess.get_directories_at("res://i18n/"):
		print("Processing %s..." % [lang])
		await get_tree().process_frame
		
		missing_strings_report.append("## %s ##" % [lang])
		
		var lesson_files := []
		for file in DirAccess.get_files_at("res://i18n/%s" % [lang]):
			if not file.begins_with("lesson-") or file.get_extension() != "po":
				continue
			lesson_files.push_back("res://i18n/%s/%s" % [lang, file])
		
		for file in lesson_files:
			var lesson_text := FileAccess.open(file, FileAccess.READ).get_as_text()
			first_entry_idx = lesson_text.find("#: ")
			var lesson_matches := POT_PATTERN.search_all(lesson_text, first_entry_idx)
			
			for lesson_match in lesson_matches:
				var lesson_id := _parse_course_string(lesson_match, true)
				
				var course_idx := course_blocks.find_custom(func(block: Dictionary) -> bool:
					return block.id == lesson_id
				)
				if course_idx > -1:
					course_blocks[course_idx][lang] = _parse_course_string(lesson_match, false)
	
		var lang_course := [course_header.replace("LANGUAGE", TranslationServer.get_language_name(lang)) + '"Language: %s\\n"' % [lang], ""]
		for block: Dictionary in course_blocks:
				if block.comments.comments:
					for comment: String in block.comments.comments:
						lang_course.append("#. %s" % [comment])
				
				if not block.comments.sources.is_empty():
					var source_line := "#: %s" % [" ".join(block.comments.sources.map(func(source: Dictionary) -> String:
						return "%s:%s" % [source.lesson, source.line_number]
					))]
					lang_course.append(source_line)
				
				if block.context:
					lang_course.append('msgctxt "%s"' % [block.context])
				lang_course.append('msgid %s' % [_wrap_and_quoted_string(block.id)])
				lang_course.append('msgstr %s' % [_wrap_and_quoted_string(block.get(lang, ""))])
				lang_course.append("")
		FileAccess.open("res://i18n/course.%s.po" % [lang], FileAccess.WRITE).store_string("\n".join(lang_course))
		_update_missing_strings("res://i18n/course.%s.po" % [lang], missing_strings_report)
		
	FileAccess.open("res://i18n/missing_string_ids.txt", FileAccess.WRITE).store_string("\n".join(missing_strings_report))
	print("Done")
	_running = false


func _update_missing_strings(po_file: String, missing_strings_report: Array) -> void:
	var po_text := FileAccess.open(po_file, FileAccess.READ).get_as_text()
	
	var course_blocks := []
	var results := POT_PATTERN.search_all(po_text)
	
	var missing_strings := []
	
	for result in results:
		var msgstr := _parse_course_string(result, false)
		if msgstr == "":
			missing_strings.append_array([_parse_course_string(result, true), ""])
	
	var total_string_count := results.size()
	var missing_string_count := floori(missing_strings.size()/2.0)
	var available_strings := total_string_count - missing_string_count
	var t := (float(available_strings) / float(total_string_count))*100.0
	missing_strings_report.append_array(["%s / %s (%.0f%%)" % [available_strings, total_string_count, t], ""])
	missing_strings_report.append_array(missing_strings)


func _wrap_and_quoted_string(s: String) -> String:
	if not "\\n" in s:
		return '"%s"' % [s]
	
	var lines := s.split("\\n")
	var string_builder := ['""']
	for i in lines.size():
		var line := lines[i]
		string_builder.append('"%s%s"' % [line, "\\n" if i < lines.size()-1 else ""])
	
	return "\n".join(string_builder)


func _parse_course_comment(target: RegExMatch) -> Dictionary:
	var result := {"sources": [], "comments": []}
	
	var comments := target.get_string("comment").split("\n", false)
	for comment in comments:
		if comment.begins_with("#: course/"):
			var line_number_idx := comment.rfind(":")
			var path := comment.substr(3, line_number_idx - 3)
			var line_number := comment.substr(line_number_idx+1).to_int()
			result.sources.push_back({"lesson": path, "line_number": line_number})
		else:
			result.comments.push_back(comment.substr(2 if comment.begins_with("# ") else 3))
	
	return result


func _parse_course_string(target: RegExMatch, is_id: bool) -> String:
	var id := target.get_string("id" if is_id else "str")

	var result := ""
	
	if id.begins_with('msg%s ""\n' % ["id" if is_id else "str"]):
		var lines := id.split("\n").slice(1)
		for line in lines:
			if not line.ends_with('\n"'):
				result += line.substr(1, line.length()-2)
			else:
				result += line.substr(1, line.length()-2) + "\n"
	else:
		result = id.substr(7 + (0 if is_id else 1), id.length()-(9 + (0 if is_id else 1)))
	
	return result


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
