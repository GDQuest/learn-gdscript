tool
extends MarginContainer

signal block_removed

enum ConfirmMode { REMOVE_BLOCK, CLEAR_FILE }

const VISUAL_ELEMENT_EXTENSIONS := ["png", "jpg", "svg", "gif", "tscn", "scn", "res"]

var _edited_content_block: ContentBlock
var _list_index := -1
var _confirm_dialog_mode := -1
var _drag_preview_style: StyleBox
var _file_dialog: EditorFileDialog
var _file_tester := File.new()

onready var _background_panel := $BackgroundPanel as PanelContainer
onready var _header_bar := $BackgroundPanel/Layout/HeaderBar as Control
onready var _drag_icon := $BackgroundPanel/Layout/HeaderBar/DragIcon as TextureRect
onready var _drop_target := $DropTarget as Control

onready var _title_label := $BackgroundPanel/Layout/HeaderBar/ContentTitle as Label
onready var _remove_button := $BackgroundPanel/Layout/HeaderBar/RemoveButton as Button

onready var _visual_element_value := $BackgroundPanel/Layout/VisualElement/LineEdit as LineEdit
onready var _select_file_button := $BackgroundPanel/Layout/VisualElement/SelectFileButton as Button
onready var _clear_file_button := $BackgroundPanel/Layout/VisualElement/ClearFileButton as Button
onready var _text_content_value := $BackgroundPanel/Layout/TextContent/Editor/TextEdit as TextEdit
onready var _text_content_expand_button := $BackgroundPanel/Layout/TextContent/Editor/ExpandButton as Button
onready var _text_content_dialog := $TextEditDialog as WindowDialog
onready var _text_label := $BackgroundPanel/Layout/TextContent/Editor/TextEdit/Label as Label

onready var _confirm_dialog := $ConfirmDialog as ConfirmationDialog


func _ready() -> void:
	_update_theme()
	_drag_icon.set_drag_forwarding(self)

	_text_content_dialog.rect_size = _text_content_dialog.rect_min_size

	_remove_button.connect("pressed", self, "_on_remove_block_requested")

	_select_file_button.connect("pressed", self, "_on_select_file_requested")
	_clear_file_button.connect("pressed", self, "_on_clear_file_requested")
	_visual_element_value.connect("text_changed", self, "_update_visual_element_file")

	_text_content_value.connect("text_changed", self, "_on_text_content_changed")
	_text_content_expand_button.connect("pressed", self, "_on_text_content_expand_pressed")
	_text_content_dialog.connect("confirmed", self, "_on_text_content_confirmed")

	_confirm_dialog.connect("confirmed", self, "_on_confirm_dialog_confirmed")


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

	_drag_icon.texture = get_icon("Sort", "EditorIcons")
	_remove_button.icon = get_icon("Remove", "EditorIcons")
	_text_content_expand_button.icon = get_icon("DistractionFree", "EditorIcons")


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


func set_content_block(content_block: ContentBlock) -> void:
	_edited_content_block = content_block

	_text_label.visible = content_block.text.empty()

	_visual_element_value.text = _edited_content_block.visual_element_path
	_text_content_value.text = _edited_content_block.text


# Helpers
func _show_confirm(message: String, title: String = "Confirm") -> void:
	_confirm_dialog.window_title = title
	_confirm_dialog.dialog_text = message
	_confirm_dialog.popup_centered(_confirm_dialog.rect_min_size)


# Handlers
func _on_confirm_dialog_confirmed() -> void:
	match _confirm_dialog_mode:
		ConfirmMode.REMOVE_BLOCK:
			_on_remove_block_confirmed()
		ConfirmMode.CLEAR_FILE:
			_update_visual_element_file("")

	_confirm_dialog_mode = -1


func _on_remove_block_requested() -> void:
	_confirm_dialog_mode = ConfirmMode.REMOVE_BLOCK
	_show_confirm("Are you sure you want to remove this block?")


func _on_remove_block_confirmed() -> void:
	emit_signal("block_removed")


func _on_select_file_requested() -> void:
	if not _file_dialog:
		_file_dialog = EditorFileDialog.new()
		_file_dialog.display_mode = EditorFileDialog.DISPLAY_LIST
		_file_dialog.rect_min_size = Vector2(700, 480)
		add_child(_file_dialog)

		_file_dialog.connect("file_selected", self, "_update_visual_element_file")

	_file_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	_file_dialog.clear_filters()

	_file_dialog.popup_centered()


func _on_clear_file_requested() -> void:
	_confirm_dialog_mode = ConfirmMode.CLEAR_FILE
	_show_confirm("Are you sure you want to clear the visual element?")


func _update_visual_element_file(file_path: String) -> void:
	if _visual_element_value.text != file_path:
		_visual_element_value.text = file_path

	var is_valid := file_path.empty() or file_path.get_extension() in VISUAL_ELEMENT_EXTENSIONS
	if not file_path.empty() and file_path.is_rel_path():
		file_path = _edited_content_block.resource_path.get_base_dir().plus_file(file_path)
		is_valid = is_valid and _file_tester.file_exists(file_path)

	if is_valid:
		_visual_element_value.modulate = Color.white
		_edited_content_block.visual_element_path = file_path
		_edited_content_block.emit_changed()
	else:
		_visual_element_value.modulate = Color.red


func _on_text_content_changed() -> void:
	_text_label.visible = _text_content_value.text.empty()

	_edited_content_block.text = _text_content_value.text
	_edited_content_block.emit_changed()


func _on_text_content_expand_pressed() -> void:
	_text_content_dialog.text = _edited_content_block.text
	_text_content_dialog.popup_centered()


func _on_text_content_confirmed() -> void:
	_edited_content_block.text = _text_content_dialog.text
	_text_content_value.text = _text_content_dialog.text
	_edited_content_block.emit_changed()
