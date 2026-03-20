extends PanelContainer

const HOVER_STYLE := preload("res://ui/theme/outliner_item_hover.tres")
const SELECTED_STYLE := preload("res://ui/theme/outliner_item_selected.tres")

signal selected()

var lesson_index := -1: set = set_lesson_index
var lesson_title := "": set = set_lesson_title
var completion := 0: set = set_completion
var is_selected := false: set = set_selected

var _mouse_hovering := false

@onready var _prefix_label := $MarginContainer/Layout/PrefixLabel as Label
@onready var _title_label := $MarginContainer/Layout/TitleLabel as Label
@onready var _progress_bar := $MarginContainer/Layout/ProgressBar as ProgressBar


func _ready() -> void:
	_update_visuals()
	
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))


func _draw() -> void:
	if not _mouse_hovering and not selected:
		return
	
	if selected:
		draw_style_box(SELECTED_STYLE, Rect2(Vector2.ZERO, size))
	
	if _mouse_hovering:
		draw_style_box(HOVER_STYLE, Rect2(Vector2.ZERO, size))


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		emit_signal("selected")


func set_lesson_index(value: int) -> void:
	lesson_index = value
	_update_visuals()


func set_lesson_title(value: String) -> void:
	lesson_title = value
	_update_visuals()


func set_completion(value: int) -> void:
	completion = value
	_update_visuals()


func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()


func _update_visuals() -> void:
	if not is_inside_tree():
		return
	
	_prefix_label.text = "Lesson %d" % [lesson_index + 1]
	_title_label.text = lesson_title
	_progress_bar.value = completion
	tooltip_text = lesson_title
	
	if completion == 0:
		_title_label.modulate.a = 0.65
	else:
		_title_label.modulate.a = 1.0


func _on_mouse_entered() -> void:
	_mouse_hovering = true
	queue_redraw()


func _on_mouse_exited() -> void:
	_mouse_hovering = false
	queue_redraw()
