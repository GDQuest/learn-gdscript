tool
extends MarginContainer

signal lesson_title_changed(title)
signal lesson_slug_changed(slug)
signal lesson_tab_selected
signal practice_tab_selected

const ContentBlockScene := preload("LessonContentBlock.tscn")
const QuizzContentBlockScene := preload("QuizzContentBlock.tscn")
const PracticeScene := preload("LessonPractice.tscn")
const FileUtils := preload("../utils/FileUtils.gd")

const INDEX_LESSON_TAB := 0
const INDEX_PRACTICE_TAB := 1

var _edited_lesson: Lesson

onready var _no_content_block := $NoContent as Control
onready var _content_block := $Content as Control

onready var _lesson_path_value := $Content/LessonPath/LineEdit as LineEdit
onready var _lesson_title_value := $Content/LessonTitle/LineEdit as LineEdit
onready var _edit_slug_button := $Content/LessonPath/SlugButton as Button
onready var _edit_slug_dialog := $SlugDialog as WindowDialog

onready var _lesson_tabs := $Content/LessonContent as TabContainer
onready var _lesson_content_blocks := $Content/LessonContent/ContentBlocks/ItemList as Control
onready var _add_content_block_button := (
	$Content/LessonContent/ContentBlocks/ToolBar/AddBlockButton
	as Button
)
onready var _add_quizz_button := (
	$Content/LessonContent/ContentBlocks/ToolBar/AddQuizzButton
	as Button
)
onready var _lesson_practices := $Content/LessonContent/Practices/ItemList as Control
onready var _add_practice_button := (
	$Content/LessonContent/Practices/ToolBar/AddPracticeButton
	as Button
)


func _ready() -> void:
	_update_theme()
	_lesson_tabs.set_tab_title(0, "Lesson Structure")

	_content_block.hide()
	_no_content_block.show()

	_lesson_tabs.connect("tab_changed", self, "_on_LessonContent_tab_changed")

	_lesson_title_value.connect("text_changed", self, "_on_title_text_changed")
	_add_content_block_button.connect("pressed", self, "_on_content_block_added")
	_add_quizz_button.connect("pressed", self, "_on_quizz_added")
	_lesson_content_blocks.connect("item_moved", self, "_on_content_block_moved")
	_add_practice_button.connect("pressed", self, "_on_practice_added")
	_lesson_practices.connect("item_moved", self, "_on_practice_moved")

	_edit_slug_button.connect("pressed", self, "_on_edit_slug_pressed")
	_edit_slug_dialog.connect("confirmed", self, "_on_edit_slug_confirmed")


func _update_theme() -> void:
	if not is_inside_tree():
		return

	_lesson_path_value.add_color_override(
		"font_color_uneditable", get_color("disabled_font_color", "Editor")
	)
	_add_content_block_button.icon = get_icon("New", "EditorIcons")
	_add_quizz_button.icon = _add_content_block_button.icon
	_add_practice_button.icon = get_icon("New", "EditorIcons")

	var tab_style = get_stylebox("panel", "TabContainer")
	if tab_style is StyleBoxFlat:
		tab_style.bg_color = get_color("base_color", "Editor").linear_interpolate(
			get_color("dark_color_1", "Editor"), 0.5
		)
	_lesson_tabs.add_stylebox_override("panel", tab_style)


func set_lesson(lesson: Lesson) -> void:
	if _edited_lesson:
		for block_data in _edited_lesson.content_blocks:
			block_data.disconnect("changed", self, "_on_lesson_resource_changed")
		for practice_data in _edited_lesson.practices:
			practice_data.disconnect("changed", self, "_on_lesson_resource_changed")

	_edited_lesson = lesson

	if not _edited_lesson:
		_lesson_path_value.text = ""
		_lesson_title_value.text = ""
		_lesson_content_blocks.clear_items()
		_lesson_practices.clear_items()

		_content_block.hide()
		_no_content_block.show()
		return

	_lesson_path_value.text = (
		"* unsaved"
		if _edited_lesson.resource_path.empty()
		else _edited_lesson.resource_path
	)
	_lesson_title_value.text = _edited_lesson.title

	_recreate_content_blocks()
	_recreate_practices()

	_no_content_block.hide()
	_content_block.show()

	for block_data in _edited_lesson.content_blocks:
		block_data.connect("changed", self, "_on_lesson_resource_changed")
	for practice_data in _edited_lesson.practices:
		practice_data.connect("changed", self, "_on_lesson_resource_changed")


func _recreate_content_blocks() -> void:
	_lesson_content_blocks.clear_items()
	if not _edited_lesson:
		return

	var index := 0
	for content_block in _edited_lesson.content_blocks:
		var scene_type := QuizzContentBlockScene if content_block is Quizz else ContentBlockScene
		var scene_instance = scene_type.instance()
		_lesson_content_blocks.add_item(scene_instance)
		scene_instance.connect("block_removed", self, "_on_content_block_removed", [index])

		if scene_type == QuizzContentBlockScene:
			scene_instance.connect("quizz_resource_changed", self, "_on_quizz_resource_changed")

		scene_instance.set_list_index(index)
		scene_instance.setup(content_block)
		index += 1


func _recreate_practices() -> void:
	_lesson_practices.clear_items()
	if not _edited_lesson:
		return

	var i := 0
	for practice in _edited_lesson.practices:
		_create_practice_item(practice, i)
		i += 1


func _create_practice_item(practice: Practice, i: int) -> void:
	var scene_instance = PracticeScene.instance()
	_lesson_practices.add_item(scene_instance)
	scene_instance.connect("practice_removed", self, "_on_practice_removed", [i])

	scene_instance.set_list_index(i)
	scene_instance.set_practice(practice)


# Handlers
func _on_lesson_resource_changed() -> void:
	_edited_lesson.emit_changed()


func _on_title_text_changed(value: String) -> void:
	if not _edited_lesson:
		return

	_edited_lesson.title = value
	_edited_lesson.emit_changed()
	emit_signal("lesson_title_changed", value)


func _on_edit_slug_pressed() -> void:
	if not _edited_lesson:
		return

	var slug_text = ""
	if not _edited_lesson.resource_path.empty():
		slug_text = _edited_lesson.resource_path.get_base_dir().get_file().trim_prefix("lesson-")

	_edit_slug_dialog.slug_text = slug_text
	_edit_slug_dialog.popup_centered(_edit_slug_dialog.rect_min_size)


func _on_edit_slug_confirmed() -> void:
	if not _edited_lesson:
		return

	emit_signal("lesson_slug_changed", _edit_slug_dialog.slug_text)


## Content blocks
func _on_content_block_added() -> void:
	if not _edited_lesson:
		return

	var block_data = ContentBlock.new()
	var block_path = FileUtils.generate_random_lesson_subresource_path(_edited_lesson)
	block_data.take_over_path(block_path)

	_edited_lesson.content_blocks.append(block_data)
	_edited_lesson.emit_changed()

	_recreate_content_blocks()
	block_data.connect("changed", self, "_on_lesson_resource_changed")


func _on_quizz_added() -> void:
	if not _edited_lesson:
		return

	var block_data := QuizzChoice.new()
	var block_path = FileUtils.generate_random_lesson_subresource_path(_edited_lesson, "quizz")
	block_data.take_over_path(block_path)

	_edited_lesson.content_blocks.append(block_data)
	_edited_lesson.emit_changed()

	_recreate_content_blocks()
	block_data.connect("changed", self, "_on_lesson_resource_changed")


func _on_content_block_moved(item_index: int, new_index: int) -> void:
	if not _edited_lesson or _edited_lesson.content_blocks.size() <= item_index:
		return

	new_index = clamp(new_index, 0, _edited_lesson.content_blocks.size())
	if new_index == item_index:
		return

	if new_index > item_index:
		new_index -= 1

	var block_data = _edited_lesson.content_blocks.pop_at(item_index)
	_edited_lesson.content_blocks.insert(new_index, block_data)
	_edited_lesson.emit_changed()

	_recreate_content_blocks()


func _on_content_block_removed(item_index: int) -> void:
	if not _edited_lesson or _edited_lesson.content_blocks.size() <= item_index:
		return

	var block_data = _edited_lesson.content_blocks.pop_at(item_index)
	block_data.disconnect("changed", self, "_on_lesson_resource_changed")
	_edited_lesson.emit_changed()

	_recreate_content_blocks()


## Practices
func _on_practice_added() -> void:
	if not _edited_lesson:
		return

	var practice_data = Practice.new()
	var practice_path = FileUtils.generate_random_lesson_subresource_path(
		_edited_lesson, "practice"
	)
	practice_data.take_over_path(practice_path)

	_edited_lesson.practices.append(practice_data)
	_edited_lesson.emit_changed()

	_recreate_practices()
	practice_data.connect("changed", self, "_on_lesson_resource_changed")


func _on_practice_moved(item_index: int, new_index: int) -> void:
	if not _edited_lesson or _edited_lesson.practices.size() <= item_index:
		return

	new_index = clamp(new_index, 0, _edited_lesson.practices.size())
	if new_index == item_index:
		return

	if new_index > item_index:
		new_index -= 1

	var practice_data = _edited_lesson.practices.pop_at(item_index)
	_edited_lesson.practices.insert(new_index, practice_data)
	_edited_lesson.emit_changed()

	_recreate_practices()


func _on_practice_removed(item_index: int) -> void:
	if not _edited_lesson or _edited_lesson.practices.size() <= item_index:
		return

	var practice_data = _edited_lesson.practices.pop_at(item_index)
	practice_data.disconnect("changed", self, "_on_lesson_resource_changed")
	_edited_lesson.emit_changed()

	_recreate_practices()


func _on_LessonContent_tab_changed(index: int) -> void:
	if index == INDEX_PRACTICE_TAB:
		emit_signal("practice_tab_selected")
	elif index == INDEX_LESSON_TAB:
		emit_signal("lesson_tab_selected")


func _on_quizz_resource_changed(previous_quizz: Quizz, new_quizz: Quizz) -> void:
	var index := _edited_lesson.content_blocks.find(previous_quizz)
	_edited_lesson.content_blocks[index] = new_quizz
	_recreate_content_blocks()
