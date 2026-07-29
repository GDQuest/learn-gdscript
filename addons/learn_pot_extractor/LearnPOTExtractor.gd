@tool
extends EditorPlugin
## Editor plugin/script that extracts POT templates and rebuilds generated
## translated lessons.


const POT_FILES_PATH := "internationalization/locale/translations_pot_files"
const COURSE_POT_PATH := "res://i18n/course.pot"

const APPLICATION_POT_PATH := "res://i18n/application.pot"

const ERROR_DATABASE := "res://script_checking/error_database.csv"
const GLOSSARY_PATH := "res://course/glossary.csv"
const DOCUMENTATION_PATH := "res://course/documentation.csv"
const SUPPLEMENTARY_POT_PATH := "res://i18n/supplementary.pot"

const BBCODE_TRANSLATION_PARSER := preload("BBCodeTranslationParser.gd")
const CSV_TRANSLATION_PARSER := preload("CSVTranslationParser.gd")
const TSCN_TRANSLATION_PARSER := preload("TSCNTranslationParser.gd")
const LESSON_BUILDER := preload("TranslatedLessonBuilder.gd")
const ENGINE_CALLER := preload("EngineCaller.gd")
const SHARED := preload("Shared.gd")
const EXPORT_STEP := preload("TranslatedLessonExportStep.gd")

var _bbcode_parser := BBCODE_TRANSLATION_PARSER.new()
var _csv_parser := CSV_TRANSLATION_PARSER.new()
var _tscn_parser := TSCN_TRANSLATION_PARSER.new()
var _export_plugin := EXPORT_STEP.new()
var _current_pots: PackedStringArray
var _slipstream_running := false
var _building_translated_running := false
var _target_path := ""
var _gdscript_tr_re := RegEx.create_from_string(r"[\s\(]tr\(")

# Hash set of filepaths we do not want to even try parsing when building POT files
var _black_list := { }


func _enter_tree() -> void:
	add_translation_parser_plugin(_bbcode_parser)
	add_translation_parser_plugin(_csv_parser)
	add_translation_parser_plugin(_tscn_parser)
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
	remove_translation_parser_plugin(_tscn_parser)
	remove_export_plugin(_export_plugin)

	remove_tool_menu_item("i18n Tools")


## Generates the course, application, and supplementary POT template files.
func _generate_all_pot_files() -> void:
	var started_at := Time.get_ticks_msec()
	print("POT generation: generating course, application, and supplementary templates.")
	_target_path = ProjectSettings.globalize_path("res://i18n")

	await _generate_course_pot()
	await _generate_application_pot()
	await _generate_supplemantary_pots()
	print("POT generation: completed in %.2f seconds." % [_get_elapsed_seconds(started_at)])


# ⚠ Only use if you know what you're doing ⚠
func _slipstream_and_clean() -> void:
	await _slipstream_existing_translations()
	await _wipe_old_translations()


func _wipe_old_translations() -> void:
	var global_base_dir := _target_path

	for lang in DirAccess.get_directories_at(global_base_dir):
		if lang == "images":
			continue
		for file in DirAccess.get_files_at("%s/%s" % [global_base_dir, lang]):
			if file.get_extension() != "po":
				continue

			if not file.get_basename() in ["n_application", "course", "supplementary"]:
				DirAccess.remove_absolute("%s/%s/%s" % [global_base_dir, lang, file])
		DirAccess.rename_absolute("%s/%s/n_application.po" % [global_base_dir, lang], "%s/%s/application.po" % [global_base_dir, lang])


## Rebuilds every translated lesson from the English source BBCode and each
## locale's PO catalog.
func _build_translated_lessons() -> void:
	if _building_translated_running:
		push_error("Translation build: A translation build is already running. Cannot start a new one.")
		return
	_building_translated_running = true
	var started_at := Time.get_ticks_msec()
	var generated_files := 0
	var failures := 0
	var locales := _get_translation_locales()
	if locales.is_empty():
		print("Translation build: aborted; no valid locales with a course.po catalog were found.")
		_building_translated_running = false
		return

	print("Translation build: loading %d locale catalogs." % [locales.size()])
	var tr_blocks_set := {}
	for locale_index in locales.size():
		var lang := locales[locale_index]
		print("Translation build: catalog %d/%d (%s)." % [locale_index + 1, locales.size(), lang])
		var tr_blocks := SHARED.build_tr_blocks("res://i18n/%s/course.po" % [lang])
		tr_blocks_set[lang] = SHARED.build_tr_lookup(tr_blocks)
		await get_tree().process_frame

	var lesson_files := _get_lesson_files()
	print("Translation build: rebuilding %d lessons for %d locales." % [lesson_files.size(), locales.size()])
	for lesson_index in lesson_files.size():
		var file := lesson_files[lesson_index]
		print("Translation build: lesson %d/%d (%s)." % [lesson_index + 1, lesson_files.size(), file.get_base_dir().get_basename()])
		await get_tree().process_frame
		var lesson := LESSON_BUILDER.parse_lesson(file)
		if not lesson:
			failures += 1
			continue

		var translation_reports := {}
		for lang in locales:
			var lesson_report := {"count": 0, "total": 0}
			translation_reports[lang] = lesson_report
			var lesson_text := LESSON_BUILDER.build_translated_lesson(lesson, tr_blocks_set[lang], lesson_report)
			lesson_report["percent"] = float(lesson_report.count) / float(lesson_report.total)

			var new_path := "%s.%s.bbcode" % [file.get_basename(), lang]
			var output_file := FileAccess.open(new_path, FileAccess.WRITE)
			if not output_file:
				failures += 1
				printerr("Translation build: failed to write '%s' (error %d)." % [new_path, FileAccess.get_open_error()])
				continue
			output_file.store_string(lesson_text)
			generated_files += 1

		var meta_path := file.get_basename() + ".meta"
		var meta_file := FileAccess.open(meta_path, FileAccess.WRITE)
		if not meta_file:
			failures += 1
			printerr("Translation build: failed to write '%s' (error %d)." % [meta_path, FileAccess.get_open_error()])
			continue
		meta_file.store_string(JSON.stringify(translation_reports, "\t"))

	_building_translated_running = false
	print("Translation build: completed in %.2f seconds. Lessons: %d, locales: %d, generated files: %d, failures: %d." % [_get_elapsed_seconds(started_at), lesson_files.size(), locales.size(), generated_files, failures])


func _slipstream_existing_translations() -> void:
	var global_base_dir := _target_path

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

		var temp_combined_course := "%s/%s/combined_course.po" % [global_base_dir, lang]
		OS.execute("msgcat", ["--no-wrap", "--use-first"] + sources + ["-o", temp_combined_course])
		OS.execute("msgmerge", ["--no-wrap", temp_combined_course, template, "-o", target])

		var global_og_lang_app := "%s/%s/application.po" % [global_base_dir, lang]
		OS.execute("msgmerge", ["--no-wrap", "-o", global_lang_app, global_og_lang_app, global_app])


		# post process to match old format, since godot handles linebroken paragraphs whole
		var header := []
		var tr_blocks := SHARED.build_tr_blocks(global_lang_app, true, header)
		var unsure_tr_blocks := SHARED.get_unsure_tr_blocks(global_lang_app)

		for i in range(unsure_tr_blocks.size()-1, -1, -1):
			var unsure_block: Dictionary = unsure_tr_blocks[i]
			for block in tr_blocks:
				if unsure_block.id in block.id and "\\n" in block.id:
					block.comments.comments.erase("fuzzy")
					block.str = "%s\\n\\n%s" % [unsure_block.str, block.str]

		SHARED.write_from_tr_blocks(global_lang_app, "\n".join(header), tr_blocks)

		var global_og_lang_error := "%s/%s/error_database.po" % [global_base_dir, lang]
		var global_og_lang_glossary := "%s/%s/glossary_database.po" % [global_base_dir, lang]
		var global_og_lang_doc := "%s/%s/classref_database.po" % [global_base_dir, lang]

		sources = [global_og_lang_error, global_og_lang_glossary, global_og_lang_doc]
		template = global_supp
		target = global_lang_supp

		var temp_combined_doc := "%s/%s/combined_docs.po" % [global_base_dir, lang]
		OS.execute("msgcat", ["--no-wrap", "--use-first"] + sources + ["-o", temp_combined_doc])
		OS.execute("msgmerge", ["--no-wrap", temp_combined_doc, template, "-o", target])

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
	## Generates the template for translation strings stored in the support CSV databases.
	print("POT generation: supplementary template.")
	await _set_pot_files([ERROR_DATABASE, GLOSSARY_PATH, DOCUMENTATION_PATH])

	var last_modified_time := 0
	if FileAccess.file_exists(SUPPLEMENTARY_POT_PATH):
		last_modified_time = FileAccess.get_modified_time(SUPPLEMENTARY_POT_PATH)

	ENGINE_CALLER.template_generate(SUPPLEMENTARY_POT_PATH)

	if FileAccess.file_exists(SUPPLEMENTARY_POT_PATH):
		if last_modified_time == 0 or (last_modified_time > 0 and FileAccess.get_modified_time(SUPPLEMENTARY_POT_PATH) > last_modified_time):
			print("POT generation: generated supplementary template at '%s'." % [SUPPLEMENTARY_POT_PATH])
		else:
			printerr("POT generation: supplementary template was not updated at '%s'." % [SUPPLEMENTARY_POT_PATH])
	else:
		printerr("POT generation: supplementary template was not created at '%s'." % [SUPPLEMENTARY_POT_PATH])

	_recover_pot_files()


func _generate_application_pot() -> void:
	## Discovers translatable application resources before asking Godot to generate their template.
	print("POT generation: discovering application scenes and scripts.")
	var translatable_files := []
	_get_all_tscns("res://", translatable_files)
	_get_all_gdscript_with_tr("res://", translatable_files)
	print("POT generation: generating application template from %d files." % [translatable_files.size()])

	await _set_pot_files(translatable_files)

	var last_modified_time := 0
	if FileAccess.file_exists(APPLICATION_POT_PATH):
		last_modified_time = FileAccess.get_modified_time(APPLICATION_POT_PATH)

	ENGINE_CALLER.template_generate(APPLICATION_POT_PATH)

	if FileAccess.file_exists(APPLICATION_POT_PATH):
		if last_modified_time == 0 or (last_modified_time > 0 and FileAccess.get_modified_time(APPLICATION_POT_PATH) > last_modified_time):
			print("POT generation: generated application template at '%s'." % [APPLICATION_POT_PATH])
		else:
			printerr("POT generation: application template was not updated at '%s'." % [APPLICATION_POT_PATH])
	else:
		printerr("POT generation: application template was not created at '%s'." % [APPLICATION_POT_PATH])

	_recover_pot_files()


func _get_all_tscns(root: String, out_files: Array) -> void:
	## Collects scene paths without loading them; the registered parser performs the single required parse.
	var dir := DirAccess.open(root)
	out_files.append_array(Array(dir.get_files()).filter(func(filename: String) -> bool:
		return filename.get_extension() == "tscn" and not _black_list.has(root.path_join(filename))
	).map(func(filename: String) -> String:
		return root.path_join(filename)
	))
	for other_dir in dir.get_directories():
		_get_all_tscns(root.path_join(other_dir), out_files)


func _get_all_gdscript_with_tr(root: String, out_files: Array) -> void:
	## Collects scripts containing tr() calls so Godot does not parse unrelated scripts for translations.
	var dir := DirAccess.open(root)
	out_files.append_array(Array(dir.get_files()).filter(func(filename: String) -> bool:
		if filename.get_extension() != "gd":
			return false
		if root.path_join(filename) in _black_list:
			return false
		var text := FileAccess.open(root.path_join(filename), FileAccess.READ).get_as_text()
		if not _gdscript_tr_re.search(text):
			return false
		return true
	).map(func(filename: String) -> String:
		return root.path_join(filename)
	))
	for other_dir in dir.get_directories():
		_get_all_gdscript_with_tr(root.path_join(other_dir), out_files)


func _set_pot_files(paths: PackedStringArray) -> void:
	## Temporarily replaces Godot's configured POT inputs and refreshes its localization editor.
	if ProjectSettings.has_setting(POT_FILES_PATH):
		_current_pots = ProjectSettings.get_setting(POT_FILES_PATH)
		ProjectSettings.clear(POT_FILES_PATH)
	ProjectSettings.set_setting(POT_FILES_PATH, paths)
	var localization_editor := ENGINE_CALLER.get_localization_editor()
	localization_editor.call("update_translations")
	localization_editor.call("emit_signal", "localization_changed")

	await get_tree().process_frame


func _recover_pot_files() -> void:
	## Restores the configured POT inputs after a template generation pass.
	if _current_pots.is_empty() and ProjectSettings.has_setting(POT_FILES_PATH):
		ProjectSettings.clear(POT_FILES_PATH)
	else:
		ProjectSettings.set_setting(POT_FILES_PATH, _current_pots)
		var localization_editor := ENGINE_CALLER.get_localization_editor()
		localization_editor.call("update_translations")
		localization_editor.call("emit_signal", "localization_changed")
		_current_pots.clear()


func _generate_course_pot() -> void:
	## Generates the course template from lessons in their numeric course order.
	print("POT generation: discovering course lessons.")
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
	print("POT generation: generating course template from %d lessons." % [lesson_files.size()])

	await _set_pot_files(lesson_files)

	var last_modified_time := 0
	if FileAccess.file_exists(COURSE_POT_PATH):
		last_modified_time = FileAccess.get_modified_time(COURSE_POT_PATH)

	ENGINE_CALLER.template_generate(COURSE_POT_PATH)

	if FileAccess.file_exists(COURSE_POT_PATH):
		if last_modified_time == 0 or (last_modified_time > 0 and FileAccess.get_modified_time(COURSE_POT_PATH) > last_modified_time):
			print("POT generation: generated course template at '%s'." % [COURSE_POT_PATH])
		else:
			printerr("POT generation: course template was not updated at '%s'." % [COURSE_POT_PATH])
	else:
		printerr("POT generation: course template was not created at '%s'." % [COURSE_POT_PATH])

	_recover_pot_files()


func _get_translation_locales() -> PackedStringArray:
	## Returns locale directories with a usable course catalog for generated lesson rebuilding.
	var locales := PackedStringArray()
	for lang in DirAccess.get_directories_at("res://i18n"):
		if lang == "images":
			continue
		var course_catalog := "res://i18n/%s/course.po" % [lang]
		if not FileAccess.file_exists(course_catalog):
			printerr("Translation build: skipping locale '%s'; missing '%s'." % [lang, course_catalog])
			continue
		locales.append(lang)
	return locales


func _get_lesson_files() -> PackedStringArray:
	## Recursively collects and sorts source lessons for deterministic rebuild progress and output.
	var lesson_files := PackedStringArray()
	var stack: Array[String] = ["res://course"]
	while not stack.is_empty():
		var current: String = stack.pop_back()
		for directory in DirAccess.get_directories_at(current):
			stack.append(current.path_join(directory))
		var lesson_path := current.path_join("lesson.bbcode")
		if FileAccess.file_exists(lesson_path):
			lesson_files.append(lesson_path)
	lesson_files.sort()
	return lesson_files


func _get_elapsed_seconds(started_at: int) -> float:
	return float(Time.get_ticks_msec() - started_at) / 1000.0
