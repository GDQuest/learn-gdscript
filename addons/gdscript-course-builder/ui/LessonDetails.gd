tool
extends MarginContainer

signal lesson_title_changed(title)
signal lesson_slug_changed(slug)
signal lesson_tab_selected
signal practice_tab_selected
signal practice_got_edit_focus(index)

const LessonPractice := preload("LessonPractice.gd")

const ContentBlockScene := preload("LessonContentBlock.tscn")
const LessonContentBlock := preload("LessonContentBlock.gd")
const QuizContentBlockScene := preload("QuizContentBlock.tscn")
const PracticeScene := preload("LessonPractice.tscn")
const FileUtils := preload("../utils/FileUtils.gd")

const INDEX_LESSON_TAB := 0
const INDEX_PRACTICE_TAB := 1

var _edited_lesson: Lesson
var _last_search_result: SearchResult

onready var _no_content_block := $NoContent as Control
onready var _content_block := $Content as Control

onready var _lesson_path_value := $Content/LessonPath/LineEdit as LineEdit
onready var _lesson_title_value := $Content/LessonTitle/LineEdit as LineEdit
onready var _edit_slug_button := $Content/LessonPath/SlugButton as Button
onready var _edit_slug_dialog := $SlugDialog as WindowDialog

onready var _lesson_tabs := $Content/LessonContent as TabContainer
onready var _lesson_content_blocks := $Content/LessonContent/ContentBlocks/ItemList as SortableList
onready var _add_content_block_button := $Content/LessonContent/ContentBlocks/ToolBar/AddBlockButton as Button
onready var _add_quiz_button := $Content/LessonContent/ContentBlocks/ToolBar/AddQuizButton as Button
onready var _insert_content_block_dialog := $InsertContentBlockDialog as WindowDialog
onready var _lesson_practices := $Content/LessonContent/Practices/ItemList as Control
onready var _add_practice_button := $Content/LessonContent/Practices/ToolBar/AddPracticeButton as Button


func _ready() -> void:
	_update_theme()
	_lesson_tabs.set_tab_title(0, "Lesson Structure")

	_content_block.hide()
	_no_content_block.show()

	_lesson_tabs.connect("tab_changed", self, "_on_LessonContent_tab_changed")

	_lesson_title_value.connect("text_changed", self, "_on_title_text_changed")
	_add_content_block_button.connect("pressed", self, "_on_content_block_added")
	_add_quiz_button.connect("pressed", self, "_on_quiz_added")
	_lesson_content_blocks.connect("item_moved", self, "_on_content_block_moved")
	_lesson_content_blocks.connect("item_requested_at_index", self, "_on_content_block_requested")
	_add_practice_button.connect("pressed", self, "_on_practice_added")
	_lesson_practices.connect("item_moved", self, "_on_practice_moved")
	_lesson_practices.connect("item_requested_at_index", self, "_on_practice_added")

	_edit_slug_button.connect("pressed", self, "_on_edit_slug_pressed")
	_edit_slug_dialog.connect("confirmed", self, "_on_edit_slug_confirmed")

	_insert_content_block_dialog.connect("block_selected", self, "_on_content_block_added")
	_insert_content_block_dialog.connect("quiz_selected", self, "_on_quiz_added")


func _update_theme() -> void:
	if not is_inside_tree():
		return

	_lesson_path_value.add_color_override(
		"font_color_uneditable", get_color("disabled_font_color", "Editor")
	)
	_add_content_block_button.icon = get_icon("New", "EditorIcons")
	_add_quiz_button.icon = _add_content_block_button.icon
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


# Searches the lesson's content blocks for a matching string and scrolls to a matching UI element.
func search(query: String) -> void:
	var result: SearchResult = null
	var start_index := _last_search_result.block_index if _last_search_result else 0
	var block_count := _lesson_content_blocks.get_item_count()
	for index in range(start_index, block_count):
		var block = _lesson_content_blocks.get_item(index)
		if not block.has_method("search"):
			continue

		var start_line := _last_search_result.start_line if _last_search_result else 0
		var start_column := _last_search_result.end_column if _last_search_result else 0
		var text_edit_search_result: PoolIntArray = block.search(query, start_line, start_column)
		if not text_edit_search_result.empty():
			var line := text_edit_search_result[TextEdit.SEARCH_RESULT_LINE]
			var column := text_edit_search_result[TextEdit.SEARCH_RESULT_COLUMN]
			result = SearchResult.new(index, line, column, column + query.length(), "text")
			break

	_last_search_result = result


func _recreate_content_blocks() -> void:
	_lesson_content_blocks.clear_items()
	if not _edited_lesson:
		return

	var index := 0
	for content_block in _edited_lesson.content_blocks:
		var scene_type := QuizContentBlockScene if content_block is Quiz else ContentBlockScene
		var scene_instance = scene_type.instance()
		_lesson_content_blocks.add_item(scene_instance)
		scene_instance.connect("block_removed", self, "_on_content_block_removed", [index])

		if scene_type == QuizContentBlockScene:
			scene_instance.connect("quiz_resource_changed", self, "_on_quiz_resource_changed")

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
	var instance: LessonPractice = PracticeScene.instance()
	_lesson_practices.add_item(instance)
	instance.connect("practice_removed", self, "_on_practice_removed", [i])
	instance.connect("got_edit_focus", self, "_on_practice_got_edit_focus", [instance])

	instance.set_list_index(i)
	instance.set_practice(practice)


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
func _on_content_block_added(at_index: int = -1) -> void:
	if not _edited_lesson:
		return

	var block_data = ContentBlock.new()
	block_data.content_id = FileUtils.generate_random_lesson_subresource_path(_edited_lesson, "content")

	if at_index >= 0 and at_index < _edited_lesson.content_blocks.size():
		_edited_lesson.content_blocks.insert(at_index, block_data)
	else:
		_edited_lesson.content_blocks.append(block_data)
	_edited_lesson.emit_changed()

	_recreate_content_blocks()
	block_data.connect("changed", self, "_on_lesson_resource_changed")


func _on_quiz_added(at_index: int = -1) -> void:
	if not _edited_lesson:
		return

	var block_data := QuizChoice.new()
	block_data.quiz_id = FileUtils.generate_random_lesson_subresource_path(_edited_lesson, "quiz")

	if at_index >= 0 and at_index < _edited_lesson.content_blocks.size():
		_edited_lesson.content_blocks.insert(at_index, block_data)
	else:
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


func _on_content_block_requested(at_index: int) -> void:
	if not _edited_lesson or _edited_lesson.content_blocks.size() <= at_index:
		return

	_insert_content_block_dialog.insert_at_index = at_index
	_insert_content_block_dialog.popup_centered(_insert_content_block_dialog.rect_min_size)


func _on_content_block_removed(item_index: int) -> void:
	if not _edited_lesson or _edited_lesson.content_blocks.size() <= item_index:
		return

	var block_data = _edited_lesson.content_blocks.pop_at(item_index)
	block_data.disconnect("changed", self, "_on_lesson_resource_changed")
	_edited_lesson.emit_changed()

	_recreate_content_blocks()


## Practices
func _on_practice_added(at_index: int = -1) -> void:
	if not _edited_lesson:
		return

	var practice_data = Practice.new()
	practice_data.practice_id = FileUtils.generate_random_lesson_subresource_path(
		_edited_lesson, "practice"
	)

	if at_index >= 0 and at_index < _edited_lesson.practices.size():
		_edited_lesson.practices.insert(at_index, practice_data)
	else:
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


func _on_quiz_resource_changed(previous_quiz: Quiz, new_quiz: Quiz) -> void:
	var index := _edited_lesson.content_blocks.find(previous_quiz)
	_edited_lesson.content_blocks[index] = new_quiz
	_recreate_content_blocks()


func _on_practice_got_edit_focus(lesson_practice: LessonPractice) -> void:
	emit_signal("practice_got_edit_focus", lesson_practice.list_index)


class SearchResult:
	var block_index := 0
	var start_line := 0
	var start_column := 0
	var end_column := 0
	var property := ""

	func _init(
		p_block_index: int,
		p_start_line: int,
		p_start_column: int,
		p_end_column: int,
		p_property: String
	) -> void:
		block_index = p_block_index
		property = p_property
		start_line = p_start_line
		start_column = p_start_column
		end_column = p_end_column
