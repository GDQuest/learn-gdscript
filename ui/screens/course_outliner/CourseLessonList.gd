extends PanelContainer

signal lesson_selected(lesson_index)

const CourseLessonItem := preload("res://ui/screens/course_outliner/CourseLessonItem.gd")
const CourseLessonItemScene := preload("res://ui/screens/course_outliner/CourseLessonItem.tscn")

onready var _lesson_items := $ScrollContainer/MarginContainer/Items as Control
onready var _scroll_container := $ScrollContainer as ScrollContainer


func _ready() -> void:
	_scroll_container.grab_focus()


func add_item(lesson_index: int, lesson_title: String, completion: int) -> void:
	var item_node := CourseLessonItemScene.instance() as CourseLessonItem
	item_node.lesson_index = lesson_index
	item_node.lesson_title = lesson_title
	item_node.completion = completion

	_lesson_items.add_child(item_node)
	item_node.connect("selected", self, "_on_item_selected", [lesson_index])


func clear() -> void:
	for child_node in _lesson_items.get_children():
		var item_node = child_node as CourseLessonItem
		if item_node:
			item_node.disconnect("selected", self, "_on_item_selected")

		_lesson_items.remove_child(child_node)
		child_node.queue_free()


func select(lesson_index: int) -> void:
	for child_node in _lesson_items.get_children():
		var item_node = child_node as CourseLessonItem
		if not item_node:
			continue

		item_node.selected = item_node.lesson_index == lesson_index


func _on_item_selected(lesson_index: int) -> void:
	for child_node in _lesson_items.get_children():
		var item_node = child_node as CourseLessonItem
		if not item_node:
			continue

		item_node.selected = item_node.lesson_index == lesson_index

	emit_signal("lesson_selected", lesson_index)
