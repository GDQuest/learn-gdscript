# Single choice field for the code reference list.
#
# Displays buttons to sort and remove the field.
tool
class_name CodeRefItem
extends MarginContainer

signal text_changed
signal index_changed
signal removed

var list_index := -1 setget set_list_index

onready var _background_panel := $BackgroundPanel as PanelContainer

onready var _sort_up_button := $BackgroundPanel/Layout/SortButtons/SortUpButton as Button
onready var _sort_down_button := $BackgroundPanel/Layout/SortButtons/SortDownButton as Button

onready var _index_label := $BackgroundPanel/Layout/IndexLabel as Label
onready var _line_edit := $BackgroundPanel/Layout/LineEdit as LineEdit
onready var _remove_button := $BackgroundPanel/Layout/RemoveButton as Button

onready var _confirm_dialog := $ConfirmationDialog as ConfirmationDialog

onready var _parent := get_parent() as Container


func _ready() -> void:
	_sort_up_button.connect("pressed", self, "_change_position_in_parent", [-1])
	_sort_down_button.connect("pressed", self, "_change_position_in_parent", [1])

	_remove_button.connect("pressed", self, "_on_remove_requested")
	_line_edit.connect("text_changed", self, "_on_text_changed")

	_confirm_dialog.connect("confirmed", self, "_remove")

	_index_label.text = "%d." % [get_index()]

	# Update theme items
	var panel_style = get_stylebox("panel", "Panel").duplicate()
	if panel_style is StyleBoxFlat:
		panel_style.bg_color = get_color("base_color", "Editor")
		panel_style.corner_detail = 4
		panel_style.set_corner_radius_all(2)
	_background_panel.add_stylebox_override("panel", panel_style)

	_sort_up_button.icon = get_icon("ArrowUp", "EditorIcons")
	_sort_down_button.icon = get_icon("ArrowDown", "EditorIcons")
	_remove_button.icon = get_icon("Remove", "EditorIcons")


func set_text(value: String) -> void:
	if not _line_edit:
		yield(self, "ready")
	_line_edit.text = value


func get_text() -> String:
	return _line_edit.text


func set_list_index(index: int) -> void:
	_index_label.text = "%d." % [index]


func _on_remove_requested() -> void:
	_confirm_dialog.window_title = "Confirm"
	_confirm_dialog.dialog_text = "Are you sure you want to remove this choice?"
	_confirm_dialog.popup_centered(_confirm_dialog.rect_min_size)


func _on_text_changed(new_text: String) -> void:
	emit_signal("text_changed")


func _change_position_in_parent(offset: int) -> void:
	var new_index := get_index() + offset
	# The parent node has a header row which occupies the index 0.
	if new_index < 1 or new_index >= _parent.get_child_count():
		return
	_parent.move_child(self, new_index)
	emit_signal("index_changed")


func _remove() -> void:
	queue_free()
	emit_signal("removed")
