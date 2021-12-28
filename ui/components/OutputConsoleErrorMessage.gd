extends PanelContainer

signal show_code_requested(file_name, line, character)
signal explain_error_requested(error_code, error_message)
signal external_explain_requested

var message_severity := -1 setget set_message_severity
var message_text := "" setget set_message_text
var message_code := -1

var external_error := false setget set_external_error
var origin_file := "" setget set_origin_file
var origin_line := -1 setget set_origin_line
var origin_char := -1 setget set_origin_char

onready var _severity_label := $Layout/Content/MessageRow/MessageSeverity as Label
onready var _message_label := $Layout/Content/MessageRow/MessageValue as Label
onready var _location_row := $Layout/Content/LocationRow as Control
onready var _file_name_label := $Layout/Content/LocationRow/FileName as Label
onready var _location_label := $Layout/Content/LocationRow/CodeLocation as Label
onready var _external_label := $Layout/Content/ExternalError as Label
onready var _message_explain_button := $Layout/ExplainButton as Button

onready var _tweener := $Tween as Tween


func _ready() -> void:
	_update_visuals()
	
	_message_explain_button.connect("pressed", self, "_on_explain_pressed")
	_location_row.connect("gui_input", self, "_location_row_gui_input")
	_external_label.connect("gui_input", self, "_external_label_gui_input")

	_tweener.stop_all()
	_tweener.interpolate_property(self, "self_modulate:a", 1.0, 0.25, 1.5)
	_tweener.start()


func _update_visuals() -> void:
	if not is_inside_tree():
		return
	
	_message_label.text = message_text
	if external_error:
		_location_row.hide()
		_external_label.show()
	else:
		_external_label.hide()
		_file_name_label.text = origin_file
		_location_label.text = "line %d, column %d" % [origin_line + 1, origin_char]
		_location_row.show()
	
	match message_severity:
		MessageBus.MESSAGE_TYPE.ASSERT:
			_severity_label.text = "ASSERT"
			_message_label.add_color_override("font_color", Color(1, 0.094118, 0.321569))
			_severity_label.add_color_override("font_color", Color(1, 0.094118, 0.321569))
		MessageBus.MESSAGE_TYPE.ERROR:
			_severity_label.text = "ERROR"
			_message_label.add_color_override("font_color", Color(1, 0.094118, 0.321569))
			_severity_label.add_color_override("font_color", Color(1, 0.094118, 0.321569))
		MessageBus.MESSAGE_TYPE.WARNING:
			_severity_label.text = "WARNING"
			_message_label.add_color_override("font_color", Color(1, 0.960784, 0.25098))
			_severity_label.add_color_override("font_color", Color(1, 0.960784, 0.25098))
		_:
			_severity_label.text = "INFO"
			_message_label.add_color_override("font_color", Color(0.572549, 0.560784, 0.721569))
			_severity_label.add_color_override("font_color", Color(0.572549, 0.560784, 0.721569))
			
			_external_label.hide()
			_message_explain_button.hide()

	if message_code == -1:
		_external_label.hide()
		_message_explain_button.hide()


func _location_row_gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == BUTTON_LEFT and not mb.pressed:
		emit_signal("show_code_requested", origin_file, origin_line, origin_char)


func _external_label_gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == BUTTON_LEFT and not mb.pressed:
		emit_signal("external_explain_requested")


func set_message_severity(value: int) -> void:
	message_severity = value
	_update_visuals()


func set_message_text(value: String) -> void:
	message_text = value
	_update_visuals()


func set_external_error(value: bool) -> void:
	external_error = value
	_update_visuals()


func set_origin_file(value: String) -> void:
	origin_file = value
	_update_visuals()


func set_origin_line(value: int) -> void:
	origin_line = value
	_update_visuals()


func set_origin_char(value: int) -> void:
	origin_char = value
	_update_visuals()


func _on_explain_pressed() -> void:
	emit_signal("explain_error_requested", message_code, message_text)
