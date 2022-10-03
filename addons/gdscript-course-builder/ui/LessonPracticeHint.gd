# Drag'n'drop is diabled for these items because there are some issues with overlapping
# sortable lists.
tool
extends MarginContainer

signal hint_text_changed(text)
signal hint_moved(index_shift)
signal hint_removed

var _list_index := -1
var _hint_text := ""
var _drag_preview_style: StyleBox

onready var _background_panel := $BackgroundPanel as PanelContainer
onready var _drag_icon := $BackgroundPanel/Layout/DragIcon as TextureRect
onready var _drop_target := $DropTarget as Control
onready var _sort_up_button := $BackgroundPanel/Layout/SortButtons/SortUpButton as Button
onready var _sort_down_button := $BackgroundPanel/Layout/SortButtons/SortDownButton as Button

onready var _index_label := $BackgroundPanel/Layout/IndexLabel as Label
onready var _hint_value := $BackgroundPanel/Layout/TextEdit as TextEdit
onready var _remove_hint_button := $BackgroundPanel/Layout/RemoveButton as Button

onready var _confirm_dialog := $ConfirmDialog as ConfirmationDialog


func _ready() -> void:
	_update_theme()

	_sort_up_button.connect("pressed", self, "_on_hint_moved_up")
	_sort_down_button.connect("pressed", self, "_on_hint_moved_down")
	_remove_hint_button.connect("pressed", self, "_on_remove_hint_requested")
	_hint_value.connect("text_changed", self, "_on_hint_text_changed")

	_confirm_dialog.connect("confirmed", self, "_on_remove_hint_confirmed")


func _update_theme() -> void:
	if not is_inside_tree():
		return

	var panel_style = get_stylebox("panel", "Panel").duplicate()
	if panel_style is StyleBoxFlat:
		panel_style.bg_color = get_color("base_color", "Editor")
		panel_style.corner_detail = 4
		panel_style.set_corner_radius_all(2)
	_background_panel.add_stylebox_override("panel", panel_style)

	_drag_preview_style = panel_style.duplicate()
	if _drag_preview_style is StyleBoxFlat:
		panel_style.bg_color = get_color("base_color", "Editor").linear_interpolate(
			get_color("dark_color_1", "Editor"), 0.2
		)

	_drag_icon.texture = get_icon("Sort", "EditorIcons")
	_sort_up_button.icon = get_icon("ArrowUp", "EditorIcons")
	_sort_down_button.icon = get_icon("ArrowDown", "EditorIcons")
	_remove_hint_button.icon = get_icon("Remove", "EditorIcons")


func get_drag_target_rect() -> Rect2:
	var target_rect = _drag_icon.get_global_rect()
	target_rect.position -= rect_global_position

	return target_rect


func get_drag_preview() -> Control:
	var drag_preview := Label.new()
	drag_preview.text = "Practice hint #%d" % [_list_index + 1]
	drag_preview.add_stylebox_override("normal", _drag_preview_style)
	return drag_preview


func enable_drop_target() -> void:
	_drop_target.visible = true


func disable_drop_target() -> void:
	_drop_target.visible = false


func set_list_index(index: int) -> void:
	_list_index = index
	_index_label.text = "%d." % [_list_index + 1]


func set_hint_text(value: String) -> void:
	_hint_text = tr(value)
	_hint_value.text = _hint_text


# Helpers
func _show_confirm(message: String, title: String = "Confirm") -> void:
	_confirm_dialog.window_title = title
	_confirm_dialog.dialog_text = message
	_confirm_dialog.popup_centered(_confirm_dialog.rect_min_size)


# Handlers
func _on_remove_hint_requested() -> void:
	_show_confirm("Are you sure you want to remove this hint?")


func _on_remove_hint_confirmed() -> void:
	emit_signal("hint_removed")


func _on_hint_text_changed() -> void:
	_hint_text = _hint_value.text
	emit_signal("hint_text_changed", _hint_value.text)


func _on_hint_moved_up() -> void:
	emit_signal("hint_moved", -1)


func _on_hint_moved_down() -> void:
	emit_signal("hint_moved", 1)
