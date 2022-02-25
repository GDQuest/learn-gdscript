tool
extends MarginContainer


signal practice_removed
signal got_edit_focus

enum ConfirmMode { REMOVE_PRACTICE, CLEAR_SLICE_FILE, CLEAR_VALIDATOR_FILE }
enum FileDialogMode { SELECT_SLICE_FILE, SELECT_VALIDATOR_FILE }
enum TextContentMode { GOAL_CONTENT, STARTING_CODE }

const HintScene := preload("LessonPracticeHint.tscn")

var list_index := -1

var _edited_practice: Practice
var _confirm_dialog_mode := -1
var _file_dialog_mode := -1
var _text_content_mode := -1
var _drag_preview_style: StyleBox
var _file_dialog: EditorFileDialog
var _file_tester := File.new()

onready var _background_panel := $BackgroundPanel as PanelContainer
onready var _header_bar := $BackgroundPanel/Layout/HeaderBar as Control
onready var _drag_icon := $BackgroundPanel/Layout/HeaderBar/DragIcon as TextureRect
onready var _drop_target := $DropTarget as Control

onready var _title_label := $BackgroundPanel/Layout/HeaderBar/ContentTitle/Label as Label
onready var _title := $BackgroundPanel/Layout/HeaderBar/ContentTitle/LineEdit as LineEdit
onready var _remove_button := $BackgroundPanel/Layout/HeaderBar/RemoveButton as Button

onready var _description := $BackgroundPanel/Layout/Description/LineEdit as LineEdit

onready var _script_slice := $BackgroundPanel/Layout/ScriptSlice/LineEdit as LineEdit
onready var _select_script_slice_button := (
	$BackgroundPanel/Layout/ScriptSlice/SelectFileButton as Button
)
onready var _clear_script_slice_button := (
	$BackgroundPanel/Layout/ScriptSlice/ClearFileButton as Button
)
onready var _validator := $BackgroundPanel/Layout/Validator/LineEdit as LineEdit
onready var _select_validator_button := $BackgroundPanel/Layout/Validator/SelectFileButton as Button
onready var _clear_validator_button := $BackgroundPanel/Layout/Validator/ClearFileButton as Button

onready var _goal_content := (
	$BackgroundPanel/Layout/MainSplit/Texts/GoalContent/Editor/TextEdit as TextEdit
)
onready var _goal_content_expand_button := (
	$BackgroundPanel/Layout/MainSplit/Texts/GoalContent/Editor/ExpandButton as Button
)
onready var _starting_code := (
	$BackgroundPanel/Layout/MainSplit/Texts/StartingCode/Editor/TextEdit as TextEdit
)
onready var _starting_code_expand_button := (
	$BackgroundPanel/Layout/MainSplit/Texts/StartingCode/Editor/ExpandButton as Button
)
onready var _text_content_dialog := $TextEditDialog as WindowDialog

onready var _add_hint_button := $BackgroundPanel/Layout/MainSplit/Column/Hints/Header/AddButton as Button
onready var _hints_panel := $BackgroundPanel/Layout/MainSplit/Column/Hints/HintsPanel as PanelContainer
onready var _hint_list := $BackgroundPanel/Layout/MainSplit/Column/Hints/HintsPanel/ItemList as Control

onready var _code_ref_list := $BackgroundPanel/Layout/MainSplit/Column/CodeRefList as CodeRefList

onready var _get_cursor_position_button := (
	$BackgroundPanel/Layout/CursorPosition/GetCursorPositionButton as Button
)
onready var _column_spinbox := $BackgroundPanel/Layout/CursorPosition/ColumnSpinBox as SpinBox
onready var _line_spinbox := $BackgroundPanel/Layout/CursorPosition/LineSpinBox as SpinBox

onready var _confirm_dialog := $ConfirmDialog as ConfirmationDialog


func _ready() -> void:
	_update_theme()
	_drag_icon.set_drag_forwarding(self)

	_text_content_dialog.rect_size = _text_content_dialog.rect_min_size

	_remove_button.connect("pressed", self, "_on_remove_practice_requested")
	_title.connect("text_changed", self, "_on_title_text_changed")
	_description.connect("text_changed", self, "_on_description_text_changed")

	_select_script_slice_button.connect("pressed", self, "_on_select_script_slice_requested")
	_clear_script_slice_button.connect("pressed", self, "_on_clear_script_slice_requested")
	_script_slice.connect("text_changed", self, "_change_script_slice_script")

	_select_validator_button.connect("pressed", self, "_on_select_validator_requested")
	_clear_validator_button.connect("pressed", self, "_on_clear_validator_requested")
	_validator.connect("text_changed", self, "_change_validator_script")

	_goal_content.connect("text_changed", self, "_on_goal_content_changed")
	_goal_content_expand_button.connect("pressed", self, "_on_goal_content_expand_pressed")
	_starting_code.connect("text_changed", self, "_on_starting_code_changed")
	_starting_code_expand_button.connect("pressed", self, "_on_starting_code_expand_pressed")

	_add_hint_button.connect("pressed", self, "_on_practice_hint_added")
	_hint_list.connect("item_moved", self, "_on_practice_hint_moved")

	_text_content_dialog.connect("confirmed", self, "_on_text_content_confirmed")
	_confirm_dialog.connect("confirmed", self, "_on_confirm_dialog_confirmed")
	
	_get_cursor_position_button.connect("pressed", self, "_on_get_cursor_position_button")
	_line_spinbox.connect("value_changed", self, "_on_line_spinbox_value_changed")
	_column_spinbox.connect("value_changed", self, "_on_column_spinbox_value_changed")

	for control in [_script_slice, _validator, _goal_content, _starting_code]:
		control.connect("focus_entered", self, "_on_text_field_focus_entered")


func _update_theme() -> void:
	if not is_inside_tree():
		return

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

	var hints_panel_style = get_stylebox("panel", "Panel").duplicate()
	if hints_panel_style is StyleBoxFlat:
		hints_panel_style.bg_color = get_color("dark_color_1", "Editor")
	_hints_panel.add_stylebox_override("panel", hints_panel_style)

	_drag_icon.texture = get_icon("Sort", "EditorIcons")
	_remove_button.icon = get_icon("Remove", "EditorIcons")
	_goal_content_expand_button.icon = get_icon("DistractionFree", "EditorIcons")
	_starting_code_expand_button.icon = get_icon("DistractionFree", "EditorIcons")
	_starting_code.add_font_override("font", get_font("source", "EditorFonts"))


func get_drag_target_rect() -> Rect2:
	var target_rect = _drag_icon.get_global_rect()
	target_rect.position -= rect_global_position

	return target_rect


func get_drag_preview() -> Control:
	var drag_preview := Label.new()
	drag_preview.text = "Lesson practice #%d" % [list_index + 1]
	drag_preview.add_stylebox_override("normal", _drag_preview_style)
	return drag_preview


func enable_drop_target() -> void:
	_drop_target.visible = true


func disable_drop_target() -> void:
	_drop_target.visible = false


func set_list_index(index: int) -> void:
	list_index = index
	_title_label.text = "%d." % [list_index + 1]


func set_practice(practice: Practice) -> void:
	_edited_practice = practice

	_title.text = _edited_practice.title
	_description.text = _edited_practice.description
	_script_slice.text = _edited_practice.script_slice_path
	_validator.text = _edited_practice.validator_script_path
	_goal_content.text = _edited_practice.goal
	_starting_code.text = _edited_practice.starting_code
	_line_spinbox.value = _edited_practice.cursor_line
	_column_spinbox.value = _edited_practice.cursor_column

	_rebuild_hints()
	_code_ref_list.setup(practice)


# Helpers
func _show_confirm(message: String, title: String = "Confirm") -> void:
	_confirm_dialog.window_title = title
	_confirm_dialog.dialog_text = message
	_confirm_dialog.popup_centered(_confirm_dialog.rect_min_size)


func _ensure_file_dialog() -> void:
	if not _file_dialog:
		_file_dialog = EditorFileDialog.new()
		_file_dialog.display_mode = EditorFileDialog.DISPLAY_LIST
		_file_dialog.rect_min_size = Vector2(700, 480)
		add_child(_file_dialog)

		_file_dialog.connect("file_selected", self, "_on_file_dialog_confirmed")


func _rebuild_hints() -> void:
	_hint_list.clear_items()

	var i := 0
	for hint in _edited_practice.hints:
		var scene_instance = HintScene.instance()
		_hint_list.add_item(scene_instance)
		scene_instance.connect("hint_moved", self, "_on_practice_hint_shifted", [i])
		scene_instance.connect("hint_text_changed", self, "_on_practice_hint_changed", [i])
		scene_instance.connect("hint_removed", self, "_on_practice_hint_removed", [i])

		scene_instance.set_list_index(i)
		scene_instance.set_hint_text(hint)

		i += 1


# Handlers
func _on_file_dialog_confirmed(file_path: String) -> void:
	match _file_dialog_mode:
		FileDialogMode.SELECT_SLICE_FILE:
			_change_script_slice_script(file_path)
		FileDialogMode.SELECT_VALIDATOR_FILE:
			_change_validator_script(file_path)

	_file_dialog_mode = -1


func _on_confirm_dialog_confirmed() -> void:
	match _confirm_dialog_mode:
		ConfirmMode.REMOVE_PRACTICE:
			_on_remove_practice_confirmed()
		ConfirmMode.CLEAR_SLICE_FILE:
			_change_script_slice_script("")
		ConfirmMode.CLEAR_VALIDATOR_FILE:
			_change_validator_script("")

	_confirm_dialog_mode = -1


func _on_text_content_confirmed() -> void:
	match _text_content_mode:
		TextContentMode.GOAL_CONTENT:
			_on_goal_content_confirmed(_text_content_dialog.text)
		TextContentMode.STARTING_CODE:
			_on_starting_code_confirmed(_text_content_dialog.text)

	_text_content_mode = -1


# Practice
func _on_title_text_changed(new_text: String) -> void:
	if not _edited_practice:
		return

	_edited_practice.title = new_text
	_edited_practice.emit_changed()


func _on_description_text_changed(new_text: String) -> void:
	if not _edited_practice:
		return

	_edited_practice.description = new_text
	_edited_practice.emit_changed()


func _on_remove_practice_requested() -> void:
	_confirm_dialog_mode = ConfirmMode.REMOVE_PRACTICE
	_show_confirm("Are you sure you want to remove this practice?")


func _on_remove_practice_confirmed() -> void:
	emit_signal("practice_removed")


# Script slice
func _on_select_script_slice_requested() -> void:
	_ensure_file_dialog()
	_file_dialog_mode = FileDialogMode.SELECT_SLICE_FILE
	_file_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	_file_dialog.clear_filters()

	_file_dialog.popup_centered()


func _on_clear_script_slice_requested() -> void:
	_confirm_dialog_mode = ConfirmMode.CLEAR_SLICE_FILE
	_show_confirm("Are you sure you want to clear the script slice?")


func _change_script_slice_script(file_path: String) -> void:
	if _script_slice.text != file_path:
		_script_slice.text = file_path

	var is_valid := file_path.empty() or file_path.get_extension() == "tres"
	var test_path := file_path
	if not test_path.empty() and test_path.is_rel_path():
		# TODO: Probably shouldn't rely on ID to get the path, but so far it matches the expected path.
		test_path = _edited_practice.practice_id.get_base_dir().plus_file(test_path)
		is_valid = is_valid and _file_tester.file_exists(test_path)

	if is_valid:
		_script_slice.modulate = Color.white
		_script_slice.text = file_path
		_edited_practice.script_slice_path = file_path
		_edited_practice.emit_changed()
	else:
		_script_slice.modulate = Color.red


# Validator script
func _on_select_validator_requested() -> void:
	_ensure_file_dialog()
	_file_dialog_mode = FileDialogMode.SELECT_VALIDATOR_FILE
	_file_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	_file_dialog.clear_filters()
	_file_dialog.add_filter(".gd; GDScript scripts")

	_file_dialog.popup_centered()


func _change_validator_script(file_path: String) -> void:
	if not _validator.text == file_path:
		_validator.text = file_path

	var is_valid := file_path.empty() or file_path.get_extension() == "gd"
	var test_path := file_path
	if not test_path.empty() and test_path.is_rel_path():
		# TODO: Probably shouldn't rely on ID to get the path, but so far it matches the expected path.
		test_path = _edited_practice.practice_id.get_base_dir().plus_file(test_path)
		is_valid = is_valid and _file_tester.file_exists(test_path)

	if is_valid:
		_validator.modulate = Color.white
		_edited_practice.validator_script_path = file_path
		_edited_practice.emit_changed()
	else:
		_validator.modulate = Color.red


func _on_clear_validator_requested() -> void:
	_confirm_dialog_mode = ConfirmMode.CLEAR_VALIDATOR_FILE
	_show_confirm("Are you sure you want to clear the validator script?")


# Goal text
func _on_goal_content_changed() -> void:
	_edited_practice.goal = _goal_content.text
	_edited_practice.emit_changed()


func _on_goal_content_expand_pressed() -> void:
	_text_content_mode = TextContentMode.GOAL_CONTENT
	_text_content_dialog.window_title = "Goal Content"
	_text_content_dialog.text = _edited_practice.goal
	_text_content_dialog.content_type = _text_content_dialog.ContentType.TEXT
	_text_content_dialog.popup_centered()


func _on_goal_content_confirmed(text: String) -> void:
	_edited_practice.goal = text
	_goal_content.text = text
	_edited_practice.emit_changed()


# Starting code
func _on_starting_code_changed() -> void:
	_edited_practice.starting_code = _starting_code.text
	_edited_practice.emit_changed()


func _on_starting_code_expand_pressed() -> void:
	_text_content_mode = TextContentMode.STARTING_CODE
	_text_content_dialog.window_title = "Starting Code"
	_text_content_dialog.text = _edited_practice.starting_code
	_text_content_dialog.content_type = _text_content_dialog.ContentType.CODE
	_text_content_dialog.popup_centered()


func _on_starting_code_confirmed(text: String) -> void:
	_edited_practice.starting_code = text
	_starting_code.text = text
	_edited_practice.emit_changed()


# Hints
func _on_practice_hint_added() -> void:
	if not _edited_practice:
		return

	var hints = _edited_practice.hints
	hints.append("")
	_edited_practice.hints = hints
	_edited_practice.emit_changed()

	_rebuild_hints()


func _on_practice_hint_changed(text: String, item_index: int) -> void:
	if not _edited_practice or item_index >= _edited_practice.hints.size():
		return

	var hints = _edited_practice.hints
	hints[item_index] = text
	_edited_practice.hints = hints
	_edited_practice.emit_changed()


func _on_practice_hint_moved(item_index: int, new_index: int) -> void:
	if not _edited_practice or item_index >= _edited_practice.hints.size():
		return

	new_index = clamp(new_index, 0, _edited_practice.hints.size())
	if new_index == item_index:
		return

	if new_index > item_index:
		new_index -= 1

	var hints = Array(_edited_practice.hints)
	var hint_text = hints.pop_at(item_index)
	hints.insert(new_index, hint_text)
	_edited_practice.hints = PoolStringArray(hints)
	_edited_practice.emit_changed()

	_rebuild_hints()


func _on_practice_hint_shifted(index_shift: int, item_index: int) -> void:
	if not _edited_practice or item_index >= _edited_practice.hints.size():
		return

	var new_index = item_index + index_shift
	if index_shift > 0:
		new_index += 1
	_on_practice_hint_moved(item_index, new_index)


func _on_practice_hint_removed(item_index: int) -> void:
	if not _edited_practice or item_index >= _edited_practice.hints.size():
		return

	var hints = _edited_practice.hints
	hints.remove(item_index)
	_edited_practice.hints = hints
	_edited_practice.emit_changed()

	_rebuild_hints()


func _on_text_field_focus_entered() -> void:
	emit_signal("got_edit_focus")


func _on_get_cursor_position_button() -> void:
	_line_spinbox.value = _starting_code.cursor_get_line() + 1
	_column_spinbox.value = _starting_code.cursor_get_column() + 1


func _on_line_spinbox_value_changed(value: int) -> void:
	_edited_practice.cursor_line = value


func _on_column_spinbox_value_changed(value: int) -> void:
	_edited_practice.cursor_column = value
