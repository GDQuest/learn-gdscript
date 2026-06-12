@tool
extends EditorPlugin

const POT_FILES_PATH := "internationalization/locale/translations_pot_files"
const COURSE_POT_PATH := "res://i18n/course.pot"

const APPLICATION_POT_PATH := "res://i18n/application.pot"

const ERROR_DATABASE := "res://script_checking/error_database.csv"
const GLOSSARY_PATH := "res://course/glossary.csv"
const DOCUMENTATION_PATH := "res://course/documentation.csv"
const SUPPLEMENTARY_POT_PATH := "res://i18n/supplementary.pot"

const BBCODE_TRANSLATION_PARSER := preload("BBCodeTranslationParser.gd")
const CSV_TRANSLATION_PARSER := preload("LearnCSVExtractor.gd")
const LESSON_BUILDER := preload("TranslatedLessonBuilder.gd")
const ENGINE_CALLER := preload("EngineCaller.gd")
const SHARED := preload("Shared.gd")
const EXPORT_STEP := preload("TranslatedLessonExportStep.gd")

var _bbcode_parser := BBCODE_TRANSLATION_PARSER.new()
var _csv_parser := CSV_TRANSLATION_PARSER.new()
var _export_plugin := EXPORT_STEP.new()
var _current_pots: PackedStringArray
var _slipstream_running := false
var _building_translated_running := false


func _enter_tree() -> void:
	add_translation_parser_plugin(_bbcode_parser)
	add_translation_parser_plugin(_csv_parser)
	add_export_plugin(_export_plugin)
	
	var menu_entries := {}
	menu_entries["Generate All POT files"] = _generate_all_pot_files
	menu_entries["Build Translated Lessons"] = _build_translated_lessons
	
	var submenu := PopupMenu.new()
	for entry in menu_entries:
		submenu.add_item(entry)
	submenu.index_pressed.connect(func(idx: int) -> void:
		menu_entries.values()[idx].call())
	add_tool_submenu_item("i18n Tools", submenu)


func _exit_tree() -> void:
	remove_translation_parser_plugin(_bbcode_parser)
	remove_translation_parser_plugin(_csv_parser)
	remove_export_plugin(_export_plugin)
	
	remove_tool_menu_item("i18n Tools")


func _generate_all_pot_files() -> void:
	await _generate_course_pot()
	await _generate_application_pot()
	await _generate_supplemantary_pots()


# ⚠ Only use if you know what you're doing ⚠
func _slipstream_and_clean() -> void:
	await _slipstream_existing_translations()
	await _wipe_old_translations()


func _wipe_old_translations() -> void:
	var global_base_dir := ProjectSettings.globalize_path("res://i18n")
	
	for lang in DirAccess.get_directories_at(global_base_dir):
		if lang == "images":
			continue
		for file in DirAccess.get_files_at("%s/%s" % [global_base_dir, lang]):
			if file.get_extension() != "po":
				continue
			
			if not file.get_basename() in ["n_application", "course", "supplementary"]:
				DirAccess.remove_absolute("%s/%s/%s" % [global_base_dir, lang, file])
		DirAccess.rename_absolute("%s/%s/n_application.po" % [global_base_dir, lang], "%s/%s/application.po" % [global_base_dir, lang])


func _build_translated_lessons() -> void:
	if _building_translated_running:
		return
	_building_translated_running = true
	
	var lesson_files := []
	var stack := ["res://course"]
	
	print("Building translation block set...")
	await get_tree().process_frame
	await get_tree().process_frame
	
	var tr_blocks_set := {}
	for lang in DirAccess.get_directories_at("res://i18n/"):
		var tr_blocks := SHARED.build_tr_blocks("res://i18n/%s/course.po" % [lang])
		tr_blocks_set[lang] = tr_blocks
	
	while not stack.is_empty():
		var current := stack.pop_front()
		stack.append_array(Array(DirAccess.get_directories_at(current)).map(func(dir: String) -> String: return current.path_join(dir)))
		var files := Array(DirAccess.get_files_at(current)).filter(func(file: String) -> bool: return file.get_file() == "lesson.bbcode").map(func(file: String) -> String: return current.path_join(file))
		for file: String in files:
			var translation_reports := {}
			
			print("Processing %s..." % [file.get_base_dir().get_basename()])
			await get_tree().process_frame
			for lang in DirAccess.get_directories_at("res://i18n/"):
				var lesson_report := {"count": 0, "total": 0}
				translation_reports[lang] = lesson_report
				var lesson_text := LESSON_BUILDER.build_translated_lesson(file, lang, tr_blocks_set[lang], lesson_report)
				lesson_report["percent"] = float(lesson_report.count) / float(lesson_report.total)
				
				var new_path := "%s.%s.bbcode" % [file.get_basename(), lang]
				FileAccess.open(new_path, FileAccess.WRITE).store_string(lesson_text)
			
			FileAccess.open(file.get_basename() + ".meta", FileAccess.WRITE).store_string(JSON.stringify(translation_reports, "\t"))
	
	_building_translated_running = false
	print("Done")


func _slipstream_existing_translations() -> void:
	var global_base_dir := ProjectSettings.globalize_path("res://i18n")
	
	var global_course := ProjectSettings.globalize_path(COURSE_POT_PATH)
	var global_app := ProjectSettings.globalize_path(APPLICATION_POT_PATH)
	var global_supp := ProjectSettings.globalize_path(SUPPLEMENTARY_POT_PATH)
	
	for lang in DirAccess.get_directories_at(global_base_dir):
		if lang == "images":
			continue
		
		print("Processing %s..." % [lang])
		await get_tree().process_frame
		await get_tree().process_frame
		
		var global_lang_course := "%s/%s/course.po" % [global_base_dir, lang]
		var global_lang_app := "%s/%s/n_application.po" % [global_base_dir, lang]
		var global_lang_supp := "%s/%s/supplementary.po" % [global_base_dir, lang]
		
		var template := global_course
		var target := global_lang_course
		
		var sources := Array(DirAccess.get_files_at("%s/%s" % [global_base_dir, lang])).filter(func(file: String) -> bool:
			return file.get_extension() == "po" and file.begins_with("lesson-")
		).map(func(file: String) -> String:
			return "%s/%s/%s" % [global_base_dir, lang, file]
		)
		
		var temp_combined := "%s/%s/combined.po" % [global_base_dir, lang]
		OS.execute("msgcat", ["--no-wrap", "--use-first"] + sources + ["-o", temp_combined])
		OS.execute("msgmerge", ["--no-wrap", temp_combined, template, "-o", target])
		
		var global_og_lang_app := "%s/%s/application.po" % [global_base_dir, lang]
		OS.execute("msgmerge", ["--no-wrap", "-o", global_lang_app, global_og_lang_app, global_app])
		
		var global_og_lang_error := "%s/%s/error_database.po" % [global_base_dir, lang]
		var global_og_lang_glossary := "%s/%s/glossary_database.po" % [global_base_dir, lang]
		var global_og_lang_doc := "%s/%s/classref_database.po" % [global_base_dir, lang]
		
		sources = [global_og_lang_error, global_og_lang_glossary, global_og_lang_doc]
		template = global_supp
		target = global_lang_supp
		
		OS.execute("msgcat", ["--no-wrap", "--use-first"] + sources + ["-o", temp_combined])
		OS.execute("msgmerge", ["--no-wrap", temp_combined, template, "-o", target])
	
	print("Done")


func _wrap_and_quoted_string(s: String) -> String:
	if not "\\n" in s:
		return '"%s"' % [s]
	
	var lines := s.split("\\n")
	var string_builder := ['""']
	for i in lines.size():
		var line := lines[i]
		string_builder.append('"%s%s"' % [line, "\\n" if i < lines.size()-1 else ""])
	
	return "\n".join(string_builder)


func _generate_supplemantary_pots() -> void:
	await _set_pot_files([ERROR_DATABASE, GLOSSARY_PATH, DOCUMENTATION_PATH])
	
	var last_modified_time := 0
	if FileAccess.file_exists(SUPPLEMENTARY_POT_PATH):
		last_modified_time = FileAccess.get_modified_time(SUPPLEMENTARY_POT_PATH)
	
	ENGINE_CALLER.template_generate(SUPPLEMENTARY_POT_PATH)
	
	if FileAccess.file_exists(SUPPLEMENTARY_POT_PATH):
		if last_modified_time == 0 or (last_modified_time > 0 and FileAccess.get_modified_time(SUPPLEMENTARY_POT_PATH) > last_modified_time):
			print("Generated file at %s" % [SUPPLEMENTARY_POT_PATH])
		else:
			print("Failed to generate file at %s" % [SUPPLEMENTARY_POT_PATH])
	else:
		print("Failed to generate file at %s" % [SUPPLEMENTARY_POT_PATH])
	
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
	# x(tr(...)) and any 'return tr(...)', ', tr(...)', '\ttr(...), etc
	var tr_re := RegEx.create_from_string(r"[\s\(]tr\(")
	
	var dir := DirAccess.open(root)
	out_files.append_array(Array(dir.get_files()).filter(func(filename: String) -> bool:
		if filename.get_extension() != "gd":
			return false
		var text := FileAccess.open(root.path_join(filename), FileAccess.READ).get_as_text()
		if not tr_re.search(text):
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
