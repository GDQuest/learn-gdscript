# Single choice field for a multiple or single option quiz.
#
# Displays buttons to sort and remove the field.
@tool
class_name QuizChoiceItem
extends MarginContainer

signal choice_changed
signal index_changed
signal removed

var list_index: int = -1:
	set(value):
		set_list_index(value)

var is_radio: bool = false:
	set(value):
		set_is_radio(value)

var button_group: ButtonGroup

@onready var _background_panel := $BackgroundPanel as PanelContainer

@onready var _sort_up_button := $BackgroundPanel/Layout/SortButtons/SortUpButton as Button
@onready var _sort_down_button := $BackgroundPanel/Layout/SortButtons/SortDownButton as Button

@onready var _index_label := $BackgroundPanel/Layout/IndexLabel as Label
@onready var _choice_line_edit := $BackgroundPanel/Layout/LineEdit as LineEdit
@onready var _valid_answer_checkbox := $BackgroundPanel/Layout/CheckBox as CheckBox
@onready var _remove_choice_button := $BackgroundPanel/Layout/RemoveButton as Button

@onready var _confirm_dialog := $ConfirmationDialog as ConfirmationDialog

@onready var _parent := get_parent() as Container


func _ready() -> void:
	_sort_up_button.pressed.connect(_change_position_in_parent.bind(-1))
	_sort_down_button.pressed.connect(_change_position_in_parent.bind(1))

	_remove_choice_button.pressed.connect(_on_remove_choice_requested)
	_choice_line_edit.text_changed.connect(_on_choice_text_changed)

	_confirm_dialog.confirmed.connect(_remove)

	_valid_answer_checkbox.pressed.connect(func(): choice_changed.emit())

	_index_label.text = "%d." % [get_index()]

	# Update theme items
	var editor_iface := Engine.get_singleton("EditorInterface")
	var theme: Theme = editor_iface.get_editor_theme()

	var panel_style := theme.get_stylebox("panel", "Panel").duplicate()
	if panel_style is StyleBoxFlat:
		panel_style.bg_color = theme.get_color("base_color", "Editor")
		panel_style.corner_detail = 4
		panel_style.set_corner_radius_all(2)

	_background_panel.add_theme_stylebox_override("panel", panel_style)

	_sort_up_button.icon = theme.get_icon("ArrowUp", "EditorIcons")
	_sort_down_button.icon = theme.get_icon("ArrowDown", "EditorIcons")
	_remove_choice_button.icon = theme.get_icon("Remove", "EditorIcons")


func set_answer_text(value: String) -> void:
	if not _choice_line_edit:
		await ready
	_choice_line_edit.text = value


func set_valid_answer(is_valid: bool) -> void:
	if not _valid_answer_checkbox:
		await ready
	_valid_answer_checkbox.button_pressed = is_valid


func get_answer_text() -> String:
	return _choice_line_edit.text


func is_valid_answer() -> bool:
	return _valid_answer_checkbox.button_pressed


func set_list_index(index: int) -> void:
	_index_label.text = "%d." % [index]


func set_is_radio(value: bool) -> void:
	is_radio = value
	if not _valid_answer_checkbox:
		await ready
	_valid_answer_checkbox.button_group = button_group if is_radio else null
	_valid_answer_checkbox.button_pressed = false


func _on_remove_choice_requested() -> void:
	_confirm_dialog.window_title = "Confirm"
	_confirm_dialog.dialog_text = "Are you sure you want to remove this choice?"
	_confirm_dialog.popup_centered(_confirm_dialog.custom_minimum_size)


func _on_choice_text_changed(new_text: String) -> void:
	emit_signal("choice_changed")


func _change_position_in_parent(offset: int) -> void:
	var new_index := get_index() + offset
	# The parent node has a header row which occupies the index 0
	if new_index < 1 or new_index >= _parent.get_child_count():
		return
	_parent.move_child(self, new_index)
	emit_signal("index_changed")


func _remove() -> void:
	queue_free()
	emit_signal("removed")
