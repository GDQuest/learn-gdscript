tool
extends MarginContainer

signal block_removed
signal quiz_resource_changed(previous_quiz, new_quiz)

# Matches the quiz type options indices the user can select using the quiz
# type OptionButton.
enum { QUIZ_TYPE_MULTIPLE_CHOICE, QUIZ_TYPE_SINGLE_CHOICE, QUIZ_TYPE_TEXT_INPUT }

enum ConfirmMode { REMOVE_BLOCK, CHANGE_QUIZ_TYPE }

const QuizChoiceListScene := preload("QuizChoiceList.tscn")
const QuizInputFieldScene := preload("QuizInputField.tscn")

# Edited quiz resource. Can change between a QuizChoice or a QuizInputField.
var _quiz: Quiz
var _list_index := -1
var _confirm_dialog_mode := -1
# When the user confirms changing the quiz type, set quiz type to this type option.
var _change_quiz_type_target := -1
var _drag_preview_style: StyleBox

onready var _background_panel := $BackgroundPanel as PanelContainer
onready var _header_bar := $BackgroundPanel/Layout/HeaderBar as Control
onready var _drag_icon := $BackgroundPanel/Layout/HeaderBar/DragIcon as TextureRect
onready var _drop_target := $DropTarget as Control

onready var _title_label := $BackgroundPanel/Layout/HeaderBar/ContentTitle as Label
onready var _remove_button := $BackgroundPanel/Layout/HeaderBar/RemoveButton as Button

onready var _question_line_edit := $BackgroundPanel/Layout/Question/LineEdit as LineEdit
onready var _quiz_type_options := $BackgroundPanel/Layout/Settings/QuizTypeOption as OptionButton

onready var _body_text_edit := $BackgroundPanel/Layout/Body/Editor/TextEdit as TextEdit
onready var _body_expand_button := $BackgroundPanel/Layout/Body/Editor/ExpandButton as Button
onready var _body_info_label := $BackgroundPanel/Layout/Body/Editor/TextEdit/Label as Label

onready var _explanation_text_edit := $BackgroundPanel/Layout/Explanation/Editor/TextEdit as TextEdit
onready var _explanation_expand_button := $BackgroundPanel/Layout/Explanation/Editor/ExpandButton as Button
onready var _explanation_info_label := $BackgroundPanel/Layout/Explanation/Editor/TextEdit/Label as Label

onready var _answers_container := $BackgroundPanel/Layout/Answers as PanelContainer

onready var _text_edit_dialog := $TextEditDialog as WindowDialog
# Poup dialog used to confirm deleting items.
onready var _confirm_dialog := $ConfirmDialog as ConfirmationDialog


func _ready() -> void:
	_drag_icon.set_drag_forwarding(self)

	_text_edit_dialog.rect_size = _text_edit_dialog.rect_min_size

	_remove_button.connect("pressed", self, "_on_remove_block_requested")

	_body_text_edit.connect("text_changed", self, "_on_body_text_edit_text_changed")
	_body_expand_button.connect("pressed", self, "_open_text_edit_dialog", [_body_text_edit])

	_explanation_text_edit.connect("text_changed", self, "_on_explanation_text_edit_text_changed")
	_explanation_expand_button.connect(
		"pressed", self, "_open_text_edit_dialog", [_explanation_text_edit]
	)

	_body_text_edit.connect("gui_input", self, "_text_edit_gui_input", [_body_text_edit])
	_explanation_text_edit.connect(
		"gui_input", self, "_text_edit_gui_input", [_explanation_text_edit]
	)

	_question_line_edit.connect("text_changed", self, "_on_question_line_edit_text_changed")

	_confirm_dialog.connect("confirmed", self, "_on_confirm_dialog_confirmed")
	_confirm_dialog.get_cancel().connect("pressed", self, "_on_confirm_dialog_cancelled")

	_quiz_type_options.connect("item_selected", self, "_on_quiz_type_options_item_selected")

	# Update theme items
	var panel_style = get_stylebox("panel", "Panel").duplicate()
	if panel_style is StyleBoxFlat:
		panel_style.bg_color = get_color("base_color", "Editor")
		panel_style.border_color = get_color("prop_section", "Editor").linear_interpolate(
			get_color("accent_color", "Editor"), 0.1
		)
		panel_style.border_width_bottom = 2
		panel_style.border_width_top = (
			_header_bar.rect_size.y
			+ panel_style.get_margin(MARGIN_TOP) * 2
		)
		panel_style.content_margin_left = 10
		panel_style.content_margin_right = 10
		panel_style.content_margin_bottom = 12
		panel_style.corner_detail = 4
		panel_style.set_corner_radius_all(2)
	_background_panel.add_stylebox_override("panel", panel_style)

	_drag_preview_style = get_stylebox("panel", "Panel").duplicate()
	if _drag_preview_style is StyleBoxFlat:
		_drag_preview_style.bg_color = get_color("prop_section", "Editor").linear_interpolate(
			get_color("accent_color", "Editor"), 0.3
		)
		_drag_preview_style.corner_detail = 4
		_drag_preview_style.set_corner_radius_all(2)

	_drag_icon.texture = get_icon("Sort", "EditorIcons")
	_remove_button.icon = get_icon("Remove", "EditorIcons")
	_body_expand_button.icon = get_icon("DistractionFree", "EditorIcons")
	_explanation_expand_button.icon = _body_expand_button.icon


func get_drag_target_rect() -> Rect2:
	var target_rect = _drag_icon.get_global_rect()
	target_rect.position -= rect_global_position
	return target_rect


func get_drag_preview() -> Control:
	var drag_preview := Label.new()
	drag_preview.text = "Lesson step #%d" % [_list_index + 1]
	drag_preview.add_stylebox_override("normal", _drag_preview_style)
	return drag_preview


func enable_drop_target() -> void:
	_drop_target.visible = true


func disable_drop_target() -> void:
	_drop_target.visible = false


func set_list_index(index: int) -> void:
	_list_index = index
	_title_label.text = "%d." % [_list_index + 1]


# Set by the LessonDetails resource when loading a course.
#
# Updates the interface based on the passed quiz resource.
func setup(quiz_block: Quiz) -> void:
	_quiz = quiz_block

	_question_line_edit.text = _quiz.question

	_body_text_edit.text = _quiz.content_bbcode
	_body_info_label.visible = _quiz.content_bbcode.empty()

	_explanation_text_edit.text = _quiz.explanation_bbcode
	_explanation_info_label.visible = _quiz.explanation_bbcode.empty()

	if _quiz is QuizInputField:
		_quiz_type_options.selected = 2
	elif _quiz is QuizChoice:
		_quiz_type_options.selected = 0 if _quiz.is_multiple_choice else 1
	else:
		printerr("Trying to load unsupported quiz type: %s" % [_quiz.get_class()])

	_rebuild_answers()


func search(search_text: String, from_line := 0, from_column := 0) -> PoolIntArray:
	var result := PoolIntArray()
	for text_edit in [_body_text_edit, _explanation_text_edit]:
		result = text_edit.search(search_text, TextEdit.SEARCH_MATCH_CASE, from_line, from_column)
		if not result.empty():
			var line := result[TextEdit.SEARCH_RESULT_LINE]
			var column := result[TextEdit.SEARCH_RESULT_COLUMN]
			text_edit.grab_focus()
			text_edit.select(line, column, line, column + search_text.length())
			break
	return result


func _rebuild_answers() -> void:
	for child in _answers_container.get_children():
		child.queue_free()

	var scene = QuizChoiceListScene if _quiz is QuizChoice else QuizInputFieldScene
	var instance = scene.instance()
	_answers_container.add_child(instance)
	instance.setup(_quiz)


# Helpers
func _show_confirm(message: String, title: String = "Confirm") -> void:
	_confirm_dialog.window_title = title
	_confirm_dialog.dialog_text = message
	_confirm_dialog.popup_centered(_confirm_dialog.rect_min_size)


# Handlers
func _on_confirm_dialog_confirmed() -> void:
	match _confirm_dialog_mode:
		ConfirmMode.REMOVE_BLOCK:
			emit_signal("block_removed")
		ConfirmMode.CHANGE_QUIZ_TYPE:
			_change_quiz_type(_change_quiz_type_target)

	_confirm_dialog_mode = -1


func _on_confirm_dialog_cancelled() -> void:
	if _confirm_dialog_mode == ConfirmMode.CHANGE_QUIZ_TYPE:
		if _quiz is QuizInputField:
			_quiz_type_options.selected = QUIZ_TYPE_TEXT_INPUT
		elif _quiz is QuizChoice:
			_quiz_type_options.selected = (
				QUIZ_TYPE_MULTIPLE_CHOICE
				if _quiz.is_multiple_choice
				else QUIZ_TYPE_SINGLE_CHOICE
			)
		else:
			printerr("Trying to load unsupported quiz type: %s" % [_quiz.get_class()])
		_change_quiz_type_target = -1

	_confirm_dialog_mode = -1


func _on_remove_block_requested() -> void:
	_confirm_dialog_mode = ConfirmMode.REMOVE_BLOCK
	_show_confirm("Are you sure you want to remove this block?")


func _on_question_line_edit_text_changed(new_text: String) -> void:
	_quiz.question = new_text
	_quiz.emit_changed()


func _on_body_text_edit_text_changed() -> void:
	_body_info_label.visible = _body_text_edit.text.empty()
	_quiz.content_bbcode = _body_text_edit.text
	_quiz.emit_changed()


func _on_explanation_text_edit_text_changed() -> void:
	_explanation_info_label.visible = _explanation_text_edit.text.empty()
	_quiz.explanation_bbcode = _explanation_text_edit.text
	_quiz.emit_changed()


func _on_quiz_type_options_item_selected(index: int) -> void:
	_change_quiz_type_target = index
	_confirm_dialog_mode = ConfirmMode.CHANGE_QUIZ_TYPE
	_show_confirm("Are you sure you want to change the quiz type? You may lose all answer data.")


func _change_quiz_type(target := -1) -> void:
	if target in [QUIZ_TYPE_MULTIPLE_CHOICE, QUIZ_TYPE_SINGLE_CHOICE]:
		if _quiz is QuizChoice:
			_quiz.set_is_multiple_choice(target == QUIZ_TYPE_MULTIPLE_CHOICE)
		else:
			_create_new_quiz_resource(QuizChoice, _quiz)
	elif target == QUIZ_TYPE_TEXT_INPUT:
		_create_new_quiz_resource(QuizInputField, _quiz)
	else:
		printerr("Selected unsupported quiz type: %s" % [target])


func _create_new_quiz_resource(new_type, from: Quiz) -> void:
	var previous_quiz = _quiz
	_quiz = new_type.new()
	_quiz.content_bbcode = from.content_bbcode
	_quiz.question = from.question
	_quiz.hint = from.hint
	_quiz.explanation_bbcode = from.explanation_bbcode
	emit_signal("quiz_resource_changed", previous_quiz, _quiz)
	_rebuild_answers()


# Both TextEdit nodes in the scene forward their inputs to this function to
# handle keyboard shortcuts.
func _text_edit_gui_input(event: InputEvent, source: TextEdit) -> void:
	if not event is InputEventKey:
		return
	if event.control and event.pressed and event.scancode == KEY_SPACE:
		_open_text_edit_dialog(source)


func _open_text_edit_dialog(source: TextEdit) -> void:
	if _text_edit_dialog.is_connected("confirmed", self, "_transfer_text_edit_dialog_text"):
		_text_edit_dialog.disconnect("confirmed", self, "_transfer_text_edit_dialog_text")

	_text_edit_dialog.popup_centered()
	_text_edit_dialog.text = source.text
	_text_edit_dialog.set_line_column(source.cursor_get_line(), source.cursor_get_column())
	_text_edit_dialog.popup_centered()
	_text_edit_dialog.connect(
		"confirmed", self, "_transfer_text_edit_dialog_text", [source], CONNECT_ONESHOT
	)


func _transfer_text_edit_dialog_text(target: TextEdit) -> void:
	target.set_text(_text_edit_dialog.text)
	target.emit_signal("text_changed")
	_quiz.emit_changed()
	target.cursor_set_line(_text_edit_dialog.get_line())
	target.cursor_set_column(_text_edit_dialog.get_column())
	target.grab_focus()
