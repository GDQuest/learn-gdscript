extends PanelContainer

signal lesson_selected(lesson_index)

const CourseLessonItem := preload("res://ui/screens/course_outliner/CourseLessonItem.gd")
const CourseLessonItemScene := preload("res://ui/screens/course_outliner/CourseLessonItem.tscn")

@onready var _lesson_items: Control = %Items
@onready var _scroll_container: ScrollContainer = %ScrollContainer
@onready var _translation_status: Label = %TranslationStatus
@onready var translation_status_margin_container: MarginContainer = %TranslationStatusMarginContainer

var _lesson_item_nodes: Array[CourseLessonItem] = []


func _ready() -> void:
	_scroll_container.focus_mode = Control.FOCUS_ALL
	_scroll_container.grab_focus()
	TranslationManager.translation_changed.connect(_update_translation_status)
	_update_translation_status()


func _update_translation_status() -> void:
	if TranslationManager.current_language == TranslationManager.DEFAULT_LOCALE:
		translation_status_margin_container.hide()
		return

	var summary := TranslationManager.get_translation_summary()
	if summary.completeness >= 1.0:
		translation_status_margin_container.hide()
		return

	_translation_status.text = tr(
		"This course is {percentage}% translated. Incomplete lessons will contain English text."
	).format({
		"percentage": floori(summary.completeness * 100.0),
	})
	translation_status_margin_container.show()


func add_item(lesson: BBCodeParser.ParseNode, lesson_index: int, lesson_title: String, completion: int) -> void:
	var item_node := CourseLessonItemScene.instantiate() as CourseLessonItem
	item_node.lesson_index = lesson_index
	item_node.lesson_title = lesson_title
	item_node.completion = completion

	if TranslationManager.current_language != TranslationManager.DEFAULT_LOCALE:
		var completeness := TranslationManager.get_translation_completeness(lesson.bbcode_path)
		if completeness < 1.0:
			item_node.translation_status = "A/文 %d%%" % floori(completeness * 100.0)

	_lesson_items.add_child(item_node)
	_lesson_item_nodes.append(item_node)
	item_node.selected.connect(_on_item_selected.bind(lesson_index))
	
func clear() -> void:
	for item_node in _lesson_item_nodes:
		item_node.selected.disconnect(_on_item_selected)
		_lesson_items.remove_child(item_node)
		item_node.queue_free()
	_lesson_item_nodes.clear()


func select(lesson_index: int) -> void:
	for item_node in _lesson_item_nodes:
		item_node.is_selected = item_node.lesson_index == lesson_index


func _on_item_selected(lesson_index: int) -> void:
	for item_node in _lesson_item_nodes:
		item_node.is_selected = item_node.lesson_index == lesson_index

	lesson_selected.emit(lesson_index)
