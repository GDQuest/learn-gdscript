tool
extends MarginContainer

const UIPracticeScene := preload("res://ui/UIPractice.tscn")
const UILessonScene := preload("res://ui/UILesson.tscn")
const ResourceUtils := preload("../utils/ResourceUtils.gd")
const FileUtils := preload("../utils/FileUtils.gd")
const PluginUtils := preload("../utils/PluginUtils.gd")

# Private properties
var _current_lesson_index := -1
var _current_practice_index := -1
var editor_interface: EditorInterface

var _edited_course: Course
var _cache_file: ConfigFile

enum FileDialogMode {
	LOAD_COURSE,
	SAVE_COURSE,
}
var _file_dialog_mode := -1

enum ConfirmMode {
	CREATE_AND_IGNORE_UNSAVED,
	OPEN_AND_IGNORE_UNSAVED,
	OPEN_RECENT_AND_IGNORE_UNSAVED,
}
var _confirm_dialog_mode := -1

var _recent_course_index := -1

var _remove_on_save := []

onready var _new_course_button := $Layout/ToolBar/CreateButton as Button
onready var _open_course_button := $Layout/ToolBar/OpenButton as Button
onready var _recent_courses_button := $Layout/ToolBar/RecentButton as MenuButton
onready var _play_current_button := $Layout/ToolBar/PlayCurrentButton as Button
onready var _save_course_button := $Layout/ToolBar/SaveButton as Button
onready var _save_as_course_button := $Layout/ToolBar/SaveAsButton as Button
onready var _dirty_status_label := $Layout/ToolBar/DirtyStatusLabel as Label

onready var _no_content_block := $Layout/NoContent as Control
onready var _content_block := $Layout/Content as Control

onready var _course_path_value := $Layout/Content/CoursePath/LineEdit as LineEdit
onready var _course_title_value := $Layout/Content/CourseTitle/LineEdit as LineEdit
onready var _lesson_list := $Layout/Content/CourseData/LessonList as Control
onready var _lesson_details := $Layout/Content/CourseData/LessonDetails as Control

var _file_dialog: EditorFileDialog
onready var _accept_dialog := $AcceptDialog as AcceptDialog
onready var _confirm_dialog := $ConfirmDialog as ConfirmationDialog

onready var _search_bar := $Layout/ToolBar/SearcnBar as HBoxContainer


func _init() -> void:
	_file_dialog = EditorFileDialog.new()
	_file_dialog.display_mode = EditorFileDialog.DISPLAY_LIST
	_file_dialog.rect_min_size = Vector2(700, 480)
	add_child(_file_dialog)


func _ready() -> void:
	_update_theme()

	_load_or_create_cache()
	_restore_recent_courses()

	_content_block.hide()
	_no_content_block.show()

	_new_course_button.connect("pressed", self, "_on_create_course_requested")
	_open_course_button.connect("pressed", self, "_on_open_course_requested")
	_play_current_button.connect("pressed", self, "_on_play_current_requested")
	_save_course_button.connect("pressed", self, "_save_course", [true])
	_save_as_course_button.connect("pressed", self, "_save_course", [false])
	_file_dialog.connect("file_selected", self, "_on_file_dialog_confirmed")
	var recent_courses_popup := _recent_courses_button.get_popup()
	recent_courses_popup.connect("index_pressed", self, "_on_recent_course_requested")

	_course_title_value.connect("text_changed", self, "_on_course_title_changed")
	_lesson_list.connect("lesson_added", self, "_on_lesson_added")
	_lesson_list.connect("lesson_removed", self, "_on_lesson_removed")
	_lesson_list.connect("lesson_moved", self, "_on_lesson_moved")
	_lesson_list.connect("lesson_selected", self, "_on_lesson_selected")

	_lesson_details.connect("lesson_title_changed", self, "_on_lesson_title_changed")
	_lesson_details.connect("lesson_slug_changed", self, "_on_lesson_slug_changed")
	_lesson_details.connect("lesson_tab_selected", self, "_on_lesson_tab_selected")
	_lesson_details.connect("practice_tab_selected", self, "_on_practice_tab_selected")

	_lesson_details.connect("practice_got_edit_focus", self, "_on_practice_got_edit_focus")

	_confirm_dialog.connect("confirmed", self, "_on_confirm_dialog_confirmed")

	_search_bar.connect("next_match_requested", _lesson_details, "search")


func _update_theme() -> void:
	if not is_inside_tree():
		return

	_recent_courses_button.icon = get_icon("History", "EditorIcons")
	_save_course_button.icon = get_icon("Save", "EditorIcons")
	_course_path_value.add_color_override(
		"font_color_uneditable", get_color("disabled_font_color", "Editor")
	)
	_dirty_status_label.add_color_override("font_color", get_color("disabled_font_color", "Editor"))


# Properties
func _set_edited_course(course: Course) -> void:
	_remove_on_save = []

	if _edited_course:
		_edited_course.disconnect("changed", self, "_on_course_resource_changed")
		for lesson_data in _edited_course.lessons:
			lesson_data.disconnect("changed", self, "_on_course_resource_changed")

	# Normalize the resource while assigning it.
	# In case of future data changes, apply compatibility updates.
	_edited_course = _normalize_course_resource(course)

	if not _edited_course:
		_save_course_button.disabled = true
		_save_as_course_button.disabled = true
		_dirty_status_label.visible = false

		_course_path_value.text = ""
		_course_title_value.text = ""
		_lesson_list.set_lessons([])
		_lesson_list.clear_selected_lesson()
		_lesson_details.set_lesson(null)

		_content_block.hide()
		_no_content_block.show()
		return

	_save_course_button.disabled = false
	_save_as_course_button.disabled = false
	_dirty_status_label.visible = false

	_course_path_value.text = (
		"* unsaved"
		if _edited_course.resource_path.empty()
		else _edited_course.resource_path
	)
	_course_title_value.text = _edited_course.title

	var base_path = _edited_course.resource_path.get_base_dir()
	_lesson_list.set_base_path(base_path)
	_lesson_list.set_lessons(_edited_course.lessons)
	_lesson_list.clear_selected_lesson()
	_lesson_details.set_lesson(null)

	_no_content_block.hide()
	_content_block.show()

	_edited_course.connect("changed", self, "_on_course_resource_changed")
	for lesson_data in _edited_course.lessons:
		lesson_data.connect("changed", self, "_on_course_resource_changed")


func _normalize_course_resource(course: Course) -> Course:
	if not course:
		return course

	# We used to store content blocks and practices outside in individual files.
	# Now lessons are self-contained, so we should update sub-resources to use
	# their id properties instead of paths. And also we should remove the old files.
	for lesson_data in course.lessons:
		for block_data in lesson_data.content_blocks:
			if not block_data.resource_path.empty():
				if block_data is Quiz and block_data.quiz_id.empty():
					block_data.quiz_id = block_data.resource_path
				elif block_data is ContentBlock and block_data.content_id.empty():
					block_data.content_id = block_data.resource_path

				_remove_on_save.append(block_data.resource_path)
				block_data.resource_path = ""

		for practice_data in lesson_data.practices:
			if not practice_data.resource_path.empty():
				if practice_data.practice_id.empty():
					practice_data.practice_id = practice_data.resource_path

				_remove_on_save.append(practice_data.resource_path)
				practice_data.resource_path = ""

	return course


# Helpers
func _show_warning(message: String, title: String = "Warning") -> void:
	_accept_dialog.window_title = title
	_accept_dialog.dialog_text = message
	_accept_dialog.popup_centered(_accept_dialog.rect_min_size)


func _show_confirm(message: String, title: String = "Confirm") -> void:
	_confirm_dialog.window_title = title
	_confirm_dialog.dialog_text = message
	_confirm_dialog.popup_centered(_confirm_dialog.rect_min_size)


func _load_or_create_cache() -> void:
	var cache_path = PluginUtils.get_cache_file(self)
	if cache_path.empty():
		printerr("Failed to get plugin cache data path, it's empty")
		return

	_cache_file = ConfigFile.new()
	var error = _cache_file.load(cache_path)
	if error == ERR_FILE_NOT_FOUND:
		var fs := Directory.new()
		if not fs.file_exists(cache_path.get_base_dir()):
			fs.make_dir_recursive(cache_path.get_base_dir())

		error = _cache_file.save(cache_path)

	if error != OK:
		printerr(
			"Failed to load plugin cache data at path '%s', error code: %d" % [cache_path, error]
		)
		_cache_file = null
		return

	print("Loaded cache data from path '%s'" % [cache_path])


func _restore_recent_courses() -> void:
	if not _cache_file:
		return

	var recent_courses_popup := _recent_courses_button.get_popup()
	recent_courses_popup.clear()

	var recent_courses = _cache_file.get_value("recent", "courses", [])
	if recent_courses.size() == 0:
		_recent_courses_button.disabled = true
		return

	_recent_courses_button.disabled = false
	for path in recent_courses:
		recent_courses_popup.add_item(path)


func _add_recent_course(new_path: String) -> void:
	if not _cache_file or new_path.empty():
		return
	var cache_path = PluginUtils.get_cache_file(self)
	if cache_path.empty():
		return

	var recent_courses = _cache_file.get_value("recent", "courses", [])
	if recent_courses.has(new_path):
		recent_courses.erase(new_path)

	recent_courses.push_front(new_path)
	_cache_file.set_value("recent", "courses", recent_courses)
	var error = _cache_file.save(cache_path)
	if error == OK:
		_recent_courses_button.disabled = false

		var recent_courses_popup := _recent_courses_button.get_popup()
		recent_courses_popup.clear()

		for path in recent_courses:
			recent_courses_popup.add_item(path)


# Handlers
func _on_confirm_dialog_confirmed() -> void:
	match _confirm_dialog_mode:
		ConfirmMode.CREATE_AND_IGNORE_UNSAVED:
			_on_create_course_confirmed()
		ConfirmMode.OPEN_AND_IGNORE_UNSAVED:
			_on_open_course_proceeded()
		ConfirmMode.OPEN_RECENT_AND_IGNORE_UNSAVED:
			_on_recent_course_confirmed()

	_confirm_dialog_mode = -1


## General workflow
func _on_create_course_requested() -> void:
	if _dirty_status_label.visible:
		_confirm_dialog_mode = ConfirmMode.CREATE_AND_IGNORE_UNSAVED
		_show_confirm("You have unsaved changes! Are you sure you want to create a new course?")
		return

	_on_create_course_confirmed()


func _on_create_course_confirmed() -> void:
	var course_resource := Course.new()
	_set_edited_course(course_resource)


func _on_open_course_requested() -> void:
	if _dirty_status_label.visible:
		_confirm_dialog_mode = ConfirmMode.OPEN_AND_IGNORE_UNSAVED
		_show_confirm("You have unsaved changes! Are you sure you want to open another course?")
		return

	_on_open_course_proceeded()


func _on_open_course_proceeded() -> void:
	_file_dialog_mode = FileDialogMode.LOAD_COURSE
	_file_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	_file_dialog.current_file = ""
	_file_dialog.clear_filters()
	_file_dialog.add_filter("*.tres; Resources")

	_file_dialog.popup_centered()


func _on_open_course_confirmed(file_path: String) -> void:
	if file_path.empty():
		_show_warning("The path to the course is empty.", "Error")
		return

	var course_resource = ResourceUtils.load_fresh(file_path)
	if not course_resource is Course:
		_show_warning("Selected file is not a Course resource.", "Error")
		return

	_set_edited_course(course_resource)
	_add_recent_course(course_resource.resource_path)


func _on_recent_course_requested(item_index: int) -> void:
	_recent_course_index = item_index

	if _dirty_status_label.visible:
		_confirm_dialog_mode = ConfirmMode.OPEN_RECENT_AND_IGNORE_UNSAVED
		_show_confirm("You have unsaved changes! Are you sure you want to open another course?")
		return

	_on_recent_course_confirmed()


func _on_recent_course_confirmed() -> void:
	var recent_courses_popup := _recent_courses_button.get_popup()
	var item_text = recent_courses_popup.get_item_text(_recent_course_index)
	_on_open_course_confirmed(item_text)


func _save_course(overwrite_existing := false) -> void:
	if not _edited_course:
		return

	if overwrite_existing and not _edited_course.resource_path.empty():
		_on_save_course_confirmed(_edited_course.resource_path)
		return

	_file_dialog_mode = FileDialogMode.SAVE_COURSE
	_file_dialog.mode = EditorFileDialog.MODE_SAVE_FILE
	_file_dialog.current_file = "course.tres"
	_file_dialog.clear_filters()
	_file_dialog.add_filter("*.tres; Resources")

	_file_dialog.popup_centered()


func _on_save_course_confirmed(file_path: String) -> void:
	if not _edited_course:
		return

	if FileUtils.save_course(_edited_course, file_path):
		_course_path_value.text = _edited_course.resource_path
		_add_recent_course(_edited_course.resource_path)

		FileUtils.remove_obsolete(_remove_on_save)
		_remove_on_save = []

		_dirty_status_label.hide()


func _on_file_dialog_confirmed(file_path: String) -> void:
	match _file_dialog_mode:
		FileDialogMode.LOAD_COURSE:
			_on_open_course_confirmed(file_path)
		FileDialogMode.SAVE_COURSE:
			_on_save_course_confirmed(file_path)

	_file_dialog_mode = -1


## Course data changes
func _on_course_resource_changed() -> void:
	_dirty_status_label.show()


func _on_course_title_changed(value: String) -> void:
	if not _edited_course:
		return

	_edited_course.title = value.strip_edges()
	_edited_course.emit_changed()


func _on_lesson_added() -> void:
	if not _edited_course:
		return

	var lesson_data = Lesson.new()
	var lesson_path = FileUtils.random_lesson_path(_edited_course)
	lesson_data.take_over_path(lesson_path)

	var lesson_index = _edited_course.lessons.size()
	_edited_course.lessons.append(lesson_data)
	_edited_course.emit_changed()

	_lesson_list.set_lessons(_edited_course.lessons)
	_lesson_list.set_selected_lesson(lesson_index)
	_lesson_details.set_lesson(lesson_data)

	lesson_data.connect("changed", self, "_on_course_resource_changed")


func _on_lesson_removed(lesson_index: int) -> void:
	if not _edited_course or _edited_course.lessons.size() <= lesson_index:
		return

	var lesson_data = _edited_course.lessons.pop_at(lesson_index)
	lesson_data.disconnect("changed", self, "_on_course_resource_changed")
	_edited_course.emit_changed()

	_lesson_list.set_lessons(_edited_course.lessons)
	_lesson_list.clear_selected_lesson()
	_lesson_details.set_lesson(null)


func _on_lesson_selected(lesson_index: int) -> void:
	if not _edited_course or _edited_course.lessons.size() <= lesson_index:
		return

	var lesson_data = _edited_course.lessons[lesson_index]
	_lesson_details.set_lesson(lesson_data)
	_current_lesson_index = lesson_index

	_play_current_button.disabled = false
	_search_bar.is_active = true


func _on_lesson_moved(lesson_index: int, new_index: int) -> void:
	if not _edited_course or _edited_course.lessons.size() <= lesson_index:
		return

	new_index = clamp(new_index, 0, _edited_course.lessons.size())
	if new_index == lesson_index:
		return

	if new_index > lesson_index:
		new_index -= 1

	var lesson_data = _edited_course.lessons.pop_at(lesson_index)
	_edited_course.lessons.insert(new_index, lesson_data)
	_edited_course.emit_changed()

	_lesson_list.set_lessons(_edited_course.lessons)
	_lesson_list.set_selected_lesson(new_index)
	_lesson_details.set_lesson(lesson_data)


func _on_lesson_title_changed(_lesson_title: String) -> void:
	var lesson_index = _lesson_list.get_selected_lesson()
	_lesson_list.set_lessons(_edited_course.lessons)
	_lesson_list.set_selected_lesson(lesson_index)


func _on_lesson_slug_changed(lesson_slug: String) -> void:
	var lesson_index = _lesson_list.get_selected_lesson()
	var lesson_data = _edited_course.lessons[lesson_index]

	var lesson_path

	if lesson_slug.empty():
		lesson_path = FileUtils.random_lesson_path(_edited_course)
	else:
		lesson_path = FileUtils.slugged_lesson_path(_edited_course, lesson_slug)

	var old_base_path = lesson_data.resource_path.get_base_dir()
	var base_path = lesson_path.get_base_dir()

	_remove_on_save.append(lesson_data.resource_path)
	lesson_data.take_over_path(lesson_path)

	for block_data in lesson_data.content_blocks:
		if block_data is Quiz:
			block_data.quiz_id = block_data.quiz_id.replace(old_base_path, base_path)
		else:
			block_data.content_id = block_data.content_id.replace(old_base_path, base_path)

	for practice_data in lesson_data.practices:
		practice_data.practice_id = practice_data.practice_id.replace(old_base_path, base_path)

	# Rebuild the list.
	_lesson_list.set_lessons(_edited_course.lessons)
	_lesson_list.set_selected_lesson(lesson_index)
	_lesson_details.set_lesson(lesson_data)

	# Mark as changed.
	_on_course_resource_changed()


func _on_play_current_requested() -> void:
	# No course, no lesson, and no practice is selected, so nothing to run.
	if not _edited_course or _current_lesson_index < 0:
		print("No lesson or practice is selected, nothing to play.")
		return

	# Get a temp folder for running files.
	var temp_path = PluginUtils.get_temp_play_path(self)
	if temp_path.empty():
		printerr("Cannot play the scene because the temporary folder cannot be created.")
		return
	var fs := Directory.new()
	if not fs.file_exists(temp_path):
		fs.make_dir_recursive(temp_path)

	# Like Godot, we want to save changes before playing the scene.
	if _dirty_status_label.visible:
		_save_course(true)

	var play_scene: PackedScene
	var error

	var lesson_data := _edited_course.lessons[_current_lesson_index] as Lesson
	# If there is a practice selected, play it.
	if _current_practice_index >= 0:
		var practice_data = lesson_data.practices[_current_practice_index]

		var instance: UIPractice = UIPracticeScene.instance()
		instance.test_practice = practice_data
		var packed_instance := FileUtils.pack_playable_scene(instance, temp_path, "practice")
		if not packed_instance:
			return

		play_scene = packed_instance

	# Otherwise, play the selected lesson itself.
	elif _current_lesson_index >= 0:
		var instance: UILesson = UILessonScene.instance()
		instance.test_lesson = lesson_data
		var packed_instance := FileUtils.pack_playable_scene(instance, temp_path, "lesson")
		if not packed_instance:
			return

		play_scene = packed_instance

	if play_scene:
		print("Starting the scene at '%s'..." % [play_scene.resource_path])
		editor_interface.play_custom_scene(play_scene.resource_path)


func _on_lesson_tab_selected() -> void:
	_current_practice_index = -1


func _on_practice_tab_selected() -> void:
	_current_practice_index = 0


func _on_practice_got_edit_focus(index: int) -> void:
	_current_practice_index = index
