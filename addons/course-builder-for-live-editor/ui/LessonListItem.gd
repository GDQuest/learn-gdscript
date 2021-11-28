tool
extends MarginContainer

signal item_select_requested
signal item_removed

enum ConfirmMode { REMOVE_ITEM }

var _edited_lesson: Lesson
var _list_index := -1

var _base_path := ""
var _is_selected := false

var _normal_style: StyleBox
var _selected_style: StyleBox
var _drag_preview_style: StyleBox

var _confirm_dialog_mode := -1

onready var _background_panel := $BackgroundPanel as PanelContainer
onready var _lesson_name_label := $BackgroundPanel/Layout/Header/LessonName as Label
onready var _lesson_path_label := $BackgroundPanel/Layout/LessonPath as Label

onready var _remove_item_button := $BackgroundPanel/Layout/Header/RemoveButton as Button
onready var _confirm_dialog := $ConfirmDialog as ConfirmationDialog


func _ready() -> void:
	_update_theme()

	_remove_item_button.connect("pressed", self, "_on_remove_item_requested")
	_confirm_dialog.connect("confirmed", self, "_on_confirm_dialog_confirmed")


func _update_theme() -> void:
	if not is_inside_tree():
		return

	_normal_style = get_stylebox("panel", "Panel").duplicate()
	if _normal_style is StyleBoxFlat:
		_normal_style.bg_color = get_color("base_color", "Editor")
		_normal_style.corner_detail = 4
		_normal_style.set_corner_radius_all(2)

	_selected_style = _normal_style.duplicate()
	if _selected_style is StyleBoxFlat:
		_selected_style.bg_color = get_color("base_color", "Editor").linear_interpolate(
			get_color("contrast_color_1", "Editor"), 0.35
		)

	_drag_preview_style = _normal_style.duplicate()
	if _drag_preview_style is StyleBoxFlat:
		_drag_preview_style.bg_color = get_color("base_color", "Editor").linear_interpolate(
			get_color("dark_color_1", "Editor"), 0.35
		)

	_background_panel.add_stylebox_override("panel", _normal_style)

	_lesson_name_label.add_font_override("font", get_font("title", "EditorFonts"))
	_lesson_path_label.add_color_override("font_color", get_color("disabled_font_color", "Editor"))
	_remove_item_button.icon = get_icon("Remove", "EditorIcons")


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == BUTTON_LEFT:
		emit_signal("item_select_requested")


func get_drag_preview() -> Control:
	var drag_preview := Label.new()
	drag_preview.text = "Lesson #%d" % [_list_index + 1]
	drag_preview.add_stylebox_override("normal", _drag_preview_style)
	return drag_preview


# Properties
func set_list_index(index: int) -> void:
	_list_index = index


func set_base_path(value: String) -> void:
	_base_path = value

	if _edited_lesson:
		_lesson_path_label.text = _edited_lesson.resource_path.trim_prefix(_base_path)


func set_lesson(lesson: Lesson) -> void:
	_edited_lesson = lesson

	_lesson_name_label.text = (
		"[ Untitled Lesson ]"
		if _edited_lesson.title.empty()
		else _edited_lesson.title
	)
	_lesson_path_label.text = _edited_lesson.resource_path.trim_prefix(_base_path)
	_lesson_path_label.hint_tooltip = _edited_lesson.resource_path


func set_selected(value: bool) -> void:
	_is_selected = value

	if _is_selected:
		_background_panel.add_stylebox_override("panel", _selected_style)
	else:
		_background_panel.add_stylebox_override("panel", _normal_style)


# Helpers
func _show_confirm(message: String, title: String = "Confirm") -> void:
	_confirm_dialog.window_title = title
	_confirm_dialog.dialog_text = message
	_confirm_dialog.popup_centered(_confirm_dialog.rect_min_size)


# Handlers
func _on_confirm_dialog_confirmed() -> void:
	match _confirm_dialog_mode:
		ConfirmMode.REMOVE_ITEM:
			_on_remove_item_confiremd()

	_confirm_dialog_mode = -1


func _on_remove_item_requested() -> void:
	_confirm_dialog_mode = ConfirmMode.REMOVE_ITEM
	_show_confirm("Are you sure you want to remove this lesson?")


func _on_remove_item_confiremd() -> void:
	emit_signal("item_removed")
