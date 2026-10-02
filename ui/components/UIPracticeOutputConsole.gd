class_name UIPracticeOutputConsole
extends OutputConsole

signal reference_clicked(file_name, line_nb, character)

const OutputConsoleErrorMessage := preload("./OutputConsoleErrorMessage.gd")
const OutputConsoleErrorMessageScene := preload("./OutputConsoleErrorMessage.tscn")

var _slice_properties: ScriptSlice

@onready var _error_popup: Control = %ErrorPopup
@onready var _error_overlay_popup: ErrorOverlayPopup = %ErrorOverlayPopup
@onready var _external_error_popup: Control = %ExternalErrorPopup


func _ready() -> void:
	_external_error_popup.set_as_top_level(true)
	_error_popup.set_as_top_level(true)
	_error_overlay_popup.hidden.connect(_error_popup.hide)
	resized.connect(_on_resized)
	MessageBus.print_requested.connect(print_bus_message)


func setup(slice: ScriptSlice) -> void:
	_slice_properties = slice


func print_bus_message(
		type: int,
		text: String,
		file_name: String,
		line: int,
		character: int,
		code: int,
) -> void:
	if not is_inside_tree():
		return

	if type in [
		MessageBus.MESSAGE_TYPE.ASSERT,
		MessageBus.MESSAGE_TYPE.ERROR,
		MessageBus.MESSAGE_TYPE.WARNING,
	]:
		print_error(type, text, file_name, line, character, code)
	else:
		print_output([text])


func print_error(type: int, text: String, file_name: String, line: int, character: int, code: int) -> void:
	if not is_inside_tree():
		return

	# Map engine line numbers to the student's editable script slice.
	var show_lines_from := _slice_properties.get_start_offset()
	var show_lines_to := _slice_properties.get_end_offset()
	var character_offset := _slice_properties.leading_spaces
	var message := OutputConsoleErrorMessageScene.instantiate() as OutputConsoleErrorMessage
	message.message_severity = type
	message.message_text = text
	message.message_code = code

	if line >= show_lines_from and line <= show_lines_to:
		message.origin_file = file_name
		message.origin_line = line - show_lines_from
		message.origin_char = character - character_offset
	else:
		message.external_error = true

	message.external_explain_requested.connect(_on_external_requested)
	message.show_code_requested.connect(_on_code_requested)
	message.explain_error_requested.connect(_on_explain_requested)
	_add_message(message)


func _on_external_requested() -> void:
	_external_error_popup.show()


func _on_code_requested(file_name: String, line: int, character: int) -> void:
	reference_clicked.emit(file_name, line, character)


func _on_explain_requested(error_code: int, error_message: String) -> void:
	_error_overlay_popup.error_code = error_code
	_error_overlay_popup.error_message = error_message
	_error_overlay_popup.show()
	_error_popup.show()


func _on_resized() -> void:
	_error_popup.set_offsets_preset(Control.PRESET_FULL_RECT)
