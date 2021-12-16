tool
extends MarginContainer

signal block_removed
signal quizz_resource_changed(previous_quizz, new_quizz)

# Matches the quizz type options indices the user can select using the quizz
# type OptionButton.
enum { ITEM_MULTIPLE_CHOICE, ITEM_SINGLE_CHOICE, ITEM_TEXT_INPUT }

enum ConfirmMode { REMOVE_BLOCK, CHANGE_QUIZZ_TYPE }

const QuizzChoiceListScene := preload("QuizzChoiceList.tscn")
const QuizzInputFieldScene := preload("QuizzInputField.tscn")

# Edited quizz resource. Can change between a QuizzChoice or a QuizzInputField.
var _quizz: Quizz
var _list_index := -1
var _confirm_dialog_mode := -1
var _drag_preview_style: StyleBox

onready var _background_panel := $BackgroundPanel as PanelContainer
onready var _header_bar := $BackgroundPanel/Layout/HeaderBar as Control
onready var _drag_icon := $BackgroundPanel/Layout/HeaderBar/DragIcon as TextureRect
onready var _drop_target := $DropTarget as Control

onready var _title_label := $BackgroundPanel/Layout/HeaderBar/ContentTitle as Label
onready var _remove_button := $BackgroundPanel/Layout/HeaderBar/RemoveButton as Button

onready var _question_line_edit := $BackgroundPanel/Layout/Question/LineEdit as LineEdit
onready var _quizz_type_options := $BackgroundPanel/Layout/Settings/QuizzTypeOption as OptionButton

onready var _body_text_edit := $BackgroundPanel/Layout/Body/Editor/TextEdit as TextEdit
onready var _body_expand_button := $BackgroundPanel/Layout/Body/Editor/ExpandButton as Button
onready var _body_info_label := $BackgroundPanel/Layout/Body/Editor/TextEdit/Label as Label

onready var _explanation_text_edit := (
	$BackgroundPanel/Layout/Explanation/Editor/TextEdit
	as TextEdit
)
onready var _explanation_expand_button := (
	$BackgroundPanel/Layout/Explanation/Editor/ExpandButton
	as Button
)
onready var _explanation_info_label := (
	$BackgroundPanel/Layout/Explanation/Editor/TextEdit/Label
	as Label
)

onready var _answers_container := $BackgroundPanel/Layout/Answers as PanelContainer

# TODO: make this popup panel work with text body and explanation fields
onready var _text_content_dialog := $TextEditDialog as WindowDialog
# Poup dialog used to confirm deleting items.
onready var _confirm_dialog := $ConfirmDialog as ConfirmationDialog


func _ready() -> void:
	_drag_icon.set_drag_forwarding(self)

	_text_content_dialog.rect_size = _text_content_dialog.rect_min_size

	_remove_button.connect("pressed", self, "_on_remove_block_requested")

	_body_text_edit.connect("text_changed", self, "_on_body_text_edit_text_changed")
	_body_expand_button.connect("pressed", self, "_on_body_expand_button_pressed")
	_text_content_dialog.connect("confirmed", self, "_on_text_content_confirmed")

	_explanation_text_edit.connect("text_changed", self, "_on_explanation_text_edit_text_changed")

	_question_line_edit.connect("text_changed", self, "_on_question_line_edit_text_changed")

	_confirm_dialog.connect("confirmed", self, "_on_confirm_dialog_confirmed")

	_quizz_type_options.connect("item_selected", self, "_on_quizz_type_options_item_selected")

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
# Updates the interface based on the passed quizz resource.
func setup(quizz_block: Quizz) -> void:
	_quizz = quizz_block

	_question_line_edit.text = _quizz.question

	_body_text_edit.text = _quizz.content_bbcode
	_body_info_label.visible = _quizz.content_bbcode.empty()

	_explanation_text_edit.text = _quizz.explanation_bbcode
	_explanation_info_label.visible = _quizz.explanation_bbcode.empty()

	if _quizz is QuizzInputField:
		_quizz_type_options.selected = 2
	elif _quizz is QuizzChoice:
		_quizz_type_options.selected = 0 if _quizz.is_multiple_choice else 1
	else:
		printerr("Trying to load unsupported quizz type: %s" % [_quizz.get_class()])

	_rebuild_answers()


func _rebuild_answers() -> void:
	for child in _answers_container.get_children():
		child.queue_free()

	var scene = QuizzChoiceListScene if _quizz is QuizzChoice else QuizzInputFieldScene
	var instance = scene.instance()
	_answers_container.add_child(instance)
	instance.setup(_quizz)


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

	_confirm_dialog_mode = -1


func _on_remove_block_requested() -> void:
	_confirm_dialog_mode = ConfirmMode.REMOVE_BLOCK
	_show_confirm("Are you sure you want to remove this block?")


func _on_question_line_edit_text_changed(new_text: String) -> void:
	_quizz.question = new_text
	_quizz.emit_changed()


func _on_body_text_edit_text_changed() -> void:
	_body_info_label.visible = _body_text_edit.text.empty()
	_quizz.content_bbcode = _body_text_edit.text
	_quizz.emit_changed()


func _on_body_expand_button_pressed() -> void:
	_text_content_dialog.text = _quizz.content_bbcode
	_text_content_dialog.popup_centered()


func _on_explanation_text_edit_text_changed() -> void:
	_explanation_info_label.visible = _explanation_text_edit.text.empty()
	_quizz.explanation_bbcode = _explanation_text_edit.text
	_quizz.emit_changed()


func _on_text_content_confirmed() -> void:
	_quizz.content_bbcode = _text_content_dialog.text
	_body_text_edit.text = _text_content_dialog.text
	_quizz.emit_changed()


# TODO: Confirm with confirmation dialog first
func _on_quizz_type_options_item_selected(index: int) -> void:
	if index in [ITEM_MULTIPLE_CHOICE, ITEM_SINGLE_CHOICE]:
		if _quizz is QuizzChoice:
			_quizz.set_is_multiple_choice(index == ITEM_MULTIPLE_CHOICE)
		else:
			_create_new_quizz_resource(QuizzChoice, _quizz)
	elif index == ITEM_TEXT_INPUT:
		_create_new_quizz_resource(QuizzInputField, _quizz)
	else:
		printerr("Selected unsupported item type: %s" % [index])


func _create_new_quizz_resource(new_type, from: Quizz) -> void:
	var previous_quizz = _quizz
	_quizz = new_type.new()
	_quizz.content_bbcode = from.content_bbcode
	_quizz.question = from.question
	_quizz.hint = from.hint
	_quizz.explanation_bbcode = from.explanation_bbcode
	_quizz.take_over_path(previous_quizz.resource_path)
	emit_signal("quizz_resource_changed", previous_quizz, _quizz)
	_rebuild_answers()
