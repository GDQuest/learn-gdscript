@tool
extends EditorPlugin

const POT_FILES_PATH := "internationalization/locale/translations_pot_files"
const COURSE_POT_PATH := "res://i18n/course.pot"
const APPLICATION_POT_PATH := "res://i18n/application.pot"
const ERROR_POT_PATH := "res://i18n/error_database.pot"
const ERROR_DATABASE := "res://script_checking/error_database.csv"

const BBCODE_TRANSLATION_PARSER := preload("BBCodeTranslationParser.gd")
const CSV_TRANSLATION_PARSER := preload("ErrorCodeExtractor.gd")
const LESSON_BUILDER := preload("TranslatedLessonBuilder.gd")
const ENGINE_CALLER := preload("EngineCaller.gd")
const SHARED := preload("Shared.gd")

var _bbcode_parser := BBCODE_TRANSLATION_PARSER.new()
var _error_code_parser := CSV_TRANSLATION_PARSER.new()
var _current_pots: PackedStringArray
var _slipstream_running := false
var _building_translated_running := false


func _enter_tree() -> void:
	add_translation_parser_plugin(_bbcode_parser)
	add_translation_parser_plugin(_error_code_parser)
	
	var menu_entries := {}
	menu_entries["Generate Course POT"] = _generate_course_pot
	menu_entries["Generate Application POT"] = _generate_application_pot
	menu_entries["Generate Error Database POT"] = _generate_error_database_pot
	menu_entries["Slipstream Existing Translations"] = _slipstream_existing_translations
	menu_entries["Generate All POT files"] = _generate_all_pot_files
	menu_entries["Build Translated Lessons"] = _build_translated_lessons
	menu_entries["Handle Unique Strings"] = _handle_unique_strings
	
	var submenu := PopupMenu.new()
	for entry in menu_entries:
		submenu.add_item(entry)
	submenu.index_pressed.connect(func(idx: int) -> void:
		menu_entries.values()[idx].call())
	add_tool_submenu_item("i18n Tools", submenu)


func _exit_tree() -> void:
	remove_translation_parser_plugin(_bbcode_parser)
	remove_translation_parser_plugin(_error_code_parser)
	
	remove_tool_menu_item("i18n Tools")


func _handle_unique_strings() -> void:
	var course_blocks := SHARED.build_tr_blocks("res://i18n/course.pot")
	
	var course_association := {
		"course/lesson-1-what-code-is-like/lesson.bbcode":"lesson-1-what-code-is-like.po"
	}
	
	var id_swaps := {}
	for block in course_blocks:
		var glossary_re := RegEx.create_from_string(r'\[glossary term=\\"(?<term>[^"]+)\\"\]')
		var matches := glossary_re.search_all(block.id)
		if matches.is_empty():
			continue
		
		var associated_file: String = block.comments.sources[0].lesson
		associated_file = "%s.po" % [associated_file.get_base_dir().get_file()]
		
		var blockless := glossary_re.sub(block.id, "$term", true)
		var coded := glossary_re.sub(block.id, "[code]$term[/code]", true)
		var italicized := glossary_re.sub(block.id, "[i]$term[/i]", true)
		var file_swaps := id_swaps.get_or_add(associated_file, {})
		file_swaps[blockless] = block.id
		file_swaps[coded] = block.id
		file_swaps[italicized] = block.id
	
	for lang in DirAccess.get_directories_at("res://i18n"):
		for file in id_swaps:
			var blocks := SHARED.build_tr_blocks("res://i18n/%s/%s" % [lang, file])
			
			var header := SHARED.get_header("res://i18n/%s/%s" % [lang, file])
			for swap in id_swaps[file]:
				for block in blocks:
					block.id = block.id.replace("  \\n", "\\n")
					if block.id == swap:
						block.id = id_swaps[file][swap]
			var new_file_builder := [header, ""]
			for block in blocks:
				if block.comments:
					for comment in block.comments.comments:
						new_file_builder.append("#. %s" % comment)
					for source in block.comments.sources:
						new_file_builder.append("#: %s:%s" % [source.lesson, source.line_number])
					if block.ctxt:
						new_file_builder.append('msgctxt "%s"' % [block.ctxt])
					if "\\n" in block.id:
						new_file_builder.append('msgid ""')
						var lines := (block.id as String).split("\\n")
						for i in lines.size():
							var line := lines[i]
							new_file_builder.append('"%s%s"' % [line, "\\n" if i < lines.size()-1 else ""])
					else:
						new_file_builder.append('msgid "%s"' % [block.id])
					if "\\n" in block.str:
						new_file_builder.append('msgstr ""')
						var lines := (block.str as String).split("\\n")
						for line in lines:
							new_file_builder.append('"%s\\n"' % [line])
					else:
						new_file_builder.append('msgstr "%s"' % [block.str])
				new_file_builder.append("")
			FileAccess.open("res://i18n/%s/%s" % [lang, file], FileAccess.WRITE).store_string("\n".join(new_file_builder))
			var global_path := ProjectSettings.globalize_path("res://i18n/%s/%s" % [lang, file])
			OS.execute("msgcat", [global_path, "-o", global_path])


func _generate_all_pot_files() -> void:
	await _generate_course_pot()
	await _generate_application_pot()
	await _generate_error_database_pot()
	await _slipstream_existing_translations()


func _build_translated_lessons() -> void:
	if _building_translated_running:
		return
	_building_translated_running = true
	
	var lesson_files := []
	var stack := ["res://course"]
	while not stack.is_empty():
		var current := stack.pop_front()
		stack.append_array(Array(DirAccess.get_directories_at(current)).map(func(dir: String) -> String: return current.path_join(dir)))
		var files := Array(DirAccess.get_files_at(current)).filter(func(file: String) -> bool: return file.get_file() == "lesson.bbcode").map(func(file: String) -> String: return current.path_join(file))
		for file: String in files:
			print("Processing %s..." % [file.get_base_dir().get_basename()])
			await get_tree().process_frame
			for lang in DirAccess.get_directories_at("res://i18n/"):
				LESSON_BUILDER.build_translated_lesson(file, lang)
	
	_building_translated_running = false
	print("Done")


func _slipstream_existing_translations() -> void:
	if not FileAccess.file_exists("res://i18n/course.pot"):
		print("Course pot not created yet")
		return
	
	if _slipstream_running:
		return
	_slipstream_running = true
	
	var course_pot := FileAccess.open("res://i18n/course.pot", FileAccess.READ).get_as_text()
	var first_entry_idx := course_pot.find("#: ")
	var course_header := course_pot.substr(0, first_entry_idx-1)
	
	var missing_strings_report := []
	
	var course_blocks := SHARED.build_tr_blocks("res://i18n/course.pot")
	
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
			var lesson_blocks := SHARED.build_tr_blocks(file)
			for lesson_block in lesson_blocks:
				var course_idx := course_blocks.find_custom(func(block: Dictionary) -> bool:
					return block.id == lesson_block.id
				)
				if course_idx > -1:
					course_blocks[course_idx][lang] = lesson_block.str
			
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
				
				if block.ctxt:
					lang_course.append('msgctxt "%s"' % [block.ctxt])
				lang_course.append('msgid %s' % [_wrap_and_quoted_string(block.id)])
				lang_course.append('msgstr %s' % [_wrap_and_quoted_string(block.get(lang, ""))])
				lang_course.append("")
		FileAccess.open("res://i18n/course.%s.po" % [lang], FileAccess.WRITE).store_string("\n".join(lang_course))
		_update_missing_strings("res://i18n/course.%s.po" % [lang], missing_strings_report)
		
	FileAccess.open("res://i18n/missing_string_ids.txt", FileAccess.WRITE).store_string("\n".join(missing_strings_report))
	print("Done")
	_slipstream_running = false


func _update_missing_strings(po_file: String, missing_strings_report: Array) -> void:
	var course_blocks := SHARED.build_tr_blocks(po_file)
	var missing_strings := []
	
	for block in course_blocks:
		if block.str == "":
			if block.comments and block.comments.sources:
				missing_strings.append_array(block.comments.sources.map(func(source: Dictionary) -> String: return source.lesson))
			missing_strings.append_array([block.id, ""])
	
	var total_string_count := course_blocks.size()
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
