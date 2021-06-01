extends ColorRect

onready var _panel: MarginContainer = $Panel
onready var _label: Label = $Panel/Label


func _ready() -> void:
	_panel.hide()
	connect("mouse_entered", _panel, "show")
	connect("mouse_exited", _panel, "hide")


func setup(message: String, region: Rect2) -> void:
	rect_position = region.position
	rect_size = region.size
	_label.text = message


func _on_ErrorOverlay_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	
	_panel.rect_position = get_local_mouse_position()
	accept_event()
