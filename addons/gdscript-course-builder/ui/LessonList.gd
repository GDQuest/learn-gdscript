tool
extends VBoxContainer

signal lesson_added
signal lesson_moved(lesson_index, new_index)
signal lesson_removed(lesson_index)
signal lesson_selected(lesson_index)

const ListItemScene := preload("LessonListItem.tscn")

var _base_path := ""
var _drop_highlight: TreeItem
var _selected_lesson := -1

onready var _background_panel := $BackgroundPanel as PanelContainer
onready var _lesson_items := $BackgroundPanel/ItemList as Control
onready var _add_lesson_button := $ToolBar/AddButton as Button


func _ready() -> void:
	_update_theme()
	_lesson_items.set_drag_source_tag("lesson_list")

	_lesson_items.connect("item_moved", self, "_on_lesson_moved")
	_add_lesson_button.connect("pressed", self, "_on_lesson_added")


func _update_theme() -> void:
	if not is_inside_tree():
		return

	_background_panel.add_stylebox_override("panel", get_stylebox("panel", "Panel"))


func set_base_path(base_path: String) -> void:
	_base_path = base_path

	for i in _lesson_items.get_item_count():
		var item_node = _lesson_items.get_item(i)
		item_node.set_base_path(_base_path)


func set_lessons(lessons: Array) -> void:
	_lesson_items.clear_items()

	var item_index := 0
	for lesson in lessons:
		var instance = ListItemScene.instance()
		_lesson_items.add_item(instance)
		instance.connect("item_select_requested", self, "_on_lesson_selected", [item_index])
		instance.connect("item_removed", self, "_on_lesson_removed", [item_index])

		instance.set_list_index(item_index)
		instance.set_base_path(_base_path)
		instance.set_lesson(lesson)
		item_index += 1


func set_selected_lesson(lesson_index: int) -> void:
	if lesson_index < 0 or lesson_index >= _lesson_items.get_item_count():
		return
	if lesson_index == _selected_lesson:
		return

	if _selected_lesson >= 0:
		var selected_node = _lesson_items.get_item(_selected_lesson)
		selected_node.set_selected(false)

	_selected_lesson = lesson_index
	var item_node = _lesson_items.get_item(lesson_index)
	item_node.set_selected(true)


func get_selected_lesson() -> int:
	return _selected_lesson


func clear_selected_lesson() -> void:
	if _selected_lesson >= 0 and _selected_lesson < _lesson_items.get_item_count():
		var selected_node = _lesson_items.get_item(_selected_lesson)
		selected_node.set_selected(false)

	_selected_lesson = -1


# Handlers
func _on_lesson_added() -> void:
	emit_signal("lesson_added")


func _on_lesson_selected(item_index: int) -> void:
	if item_index == _selected_lesson:
		return

	if _selected_lesson >= 0 and _selected_lesson < _lesson_items.get_item_count():
		var selected_node = _lesson_items.get_item(_selected_lesson)
		selected_node.set_selected(false)

	_selected_lesson = item_index
	var item_node = _lesson_items.get_item(item_index)
	item_node.set_selected(true)

	emit_signal("lesson_selected", item_index)


func _on_lesson_moved(item_index: int, new_index: int) -> void:
	emit_signal("lesson_moved", item_index, new_index)


func _on_lesson_removed(item_index: int) -> void:
	emit_signal("lesson_removed", item_index)
