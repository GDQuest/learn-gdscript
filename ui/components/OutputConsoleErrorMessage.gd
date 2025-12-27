extends PanelContainer

signal show_code_requested(file_name: String, line: int, character: int)
signal explain_error_requested(error_code: int, error_message: String)
signal external_explain_requested

var message_code: int = -1

var _message_severity: int = -1
var message_severity: int:
	set(value):
		_message_severity = value
		_update_visuals()
	get:
		return _message_severity

var _message_text: String = ""
var message_text: String:
	set(value):
		_message_text = value
		_update_visuals()
	get:
		return _message_text

var _external_error: bool = false
var external_error: bool:
	set(value):
		_external_error = value
		_update_visuals()
	get:
		return _external_error

var _origin_file: String = ""
var origin_file: String:
	set(value):
		_origin_file = value
		_update_visuals()
	get:
		return _origin_file

var _origin_line: int = -1
var origin_line: int:
	set(value):
		_origin_line = value
		_update_visuals()
	get:
		return _origin_line

var _origin_char: int = -1
var origin_char: int:
	set(value):
		_origin_char = value
		_update_visuals()
	get:
		return _origin_char

@onready var _severity_label: Label = $Layout/Content/MessageRow/MessageSeverity
@onready var _message_label: Label = $Layout/Content/MessageRow/MessageValue
@onready var _location_row: Control = $Layout/Content/LocationRow
@onready var _file_name_label: Label = $Layout/Content/LocationRow/FileName
@onready var _location_label: Label = $Layout/Content/LocationRow/CodeLocation
@onready var _external_label: Label = $Layout/Content/ExternalError
@onready var _message_explain_button: Button = $Layout/ExplainButton

var _tweener: Tween


func _ready() -> void:
	_update_visuals()

	_message_explain_button.pressed.connect(_on_explain_pressed)
	_location_row.gui_input.connect(_location_row_gui_input)
	_external_label.gui_input.connect(_external_label_gui_input)

	_restart_fade_tween()


func _restart_fade_tween() -> void:
	if _tweener:
		_tweener.kill()

	_tweener = create_tween()
	_tweener.tween_property(self, NodePath("self_modulate:a"), 0.25, 1.5)


func _update_visuals() -> void:
	if not is_inside_tree():
		return

	_message_label.text = _message_text

	if _external_error:
		_location_row.hide()
		_external_label.show()
	else:
		_external_label.hide()
		_file_name_label.text = _origin_file
		_location_label.text = "line %d, column %d" % [_origin_line + 1, _origin_char]
		_location_row.show()

	var col: Color
	match _message_severity:
		MessageBus.MESSAGE_TYPE.ASSERT, MessageBus.MESSAGE_TYPE.ERROR:
			_severity_label.text = "ASSERT" if _message_severity == MessageBus.MESSAGE_TYPE.ASSERT else "ERROR"
			col = Color(1, 0.094118, 0.321569)
		MessageBus.MESSAGE_TYPE.WARNING:
			_severity_label.text = "WARNING"
			col = Color(1, 0.960784, 0.25098)
		_:
			_severity_label.text = "INFO"
			col = Color(0.572549, 0.560784, 0.721569)

	# Godot 4: theme overrides
	_message_label.add_theme_color_override("font_color", col)
	_severity_label.add_theme_color_override("font_color", col)

	# Hide explain UI unless we have a code
	if message_code == -1:
		_external_label.hide()
		_message_explain_button.hide()
	else:
		_message_explain_button.show()
		# if external error, location row hidden above anyway


func _location_row_gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		show_code_requested.emit(_origin_file, _origin_line, _origin_char)


func _external_label_gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		external_explain_requested.emit()


func _on_explain_pressed() -> void:
	explain_error_requested.emit(message_code, _message_text)
