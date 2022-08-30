# This console displays messages. It adds new lines automatically
class_name OutputConsole
extends PanelContainer

signal reference_clicked(file_name, line_nb, character)
signal line_highlight_requested(line_number)
signal animate_arrow_requested(chars1, chars2)

const OutputConsoleErrorMessage := preload("./OutputConsoleErrorMessage.gd")
const OutputConsoleErrorMessageScene := preload("./OutputConsoleErrorMessage.tscn")
const OutputConsolePrintMessageScene := preload("./OutputConsolePrintMessage.tscn")

var _slice_properties: SliceProperties

onready var _scroll_container := $MarginContainer/VBoxContainer/ScrollContainer as ScrollContainer
onready var _message_list := $MarginContainer/VBoxContainer/ScrollContainer/MessageList as Control

onready var _error_popup := $ErrorPopup as Control
onready var _error_overlay_popup := $ErrorPopup/ErrorOverlayPopup as ErrorOverlayPopup
onready var _external_error_popup := $ExternalErrorPopup as Control


func _ready() -> void:
	_external_error_popup.set_as_toplevel(true)
	_error_popup.set_as_toplevel(true)
	_error_overlay_popup.connect("hide", _error_popup, "hide")
	connect("resized", self, "_on_resized")

	MessageBus.connect("print_request", self, "print_bus_message")


func setup(slice_properties: SliceProperties) -> void:
	_slice_properties = slice_properties


# Adds a message related to a specific line in a specific file
func print_bus_message(
	type: int, text: String, file_name: String, line: int, character: int, code: int
) -> void:
	if not is_inside_tree():
		return

	if type in [
		MessageBus.MESSAGE_TYPE.ASSERT,
		MessageBus.MESSAGE_TYPE.ERROR,
		MessageBus.MESSAGE_TYPE.WARNING
	]:
		print_error(type, text, file_name, line, character, code)
		return

	print_output([ text ])


# Removes all children
func clear_messages() -> void:
	if not is_inside_tree():
		return

	for message_node in _message_list.get_children():
		if message_node is OutputConsoleErrorMessage:
			message_node.disconnect("external_explain_requested", self, "_on_external_requested")
			message_node.disconnect("show_code_requested", self, "_on_code_requested")
			message_node.disconnect("explain_error_requested", self, "_on_explain_requested")

		_message_list.remove_child(message_node)
		message_node.queue_free()


# Prints plain text output. Use this when you want to display the output of a
# print statement.
func print_output(values: Array) -> void:
	if not is_inside_tree():
		return

	var message_node = OutputConsolePrintMessageScene.instance()
	message_node.values = values
	_message_list.add_child(message_node)

	yield(get_tree(), "idle_frame")
	_scroll_container.ensure_control_visible(message_node)


func print_error(type: int, text: String, file_name: String, line: int, character: int, code: int) -> void:
	if not is_inside_tree():
		return

	# We need to adjust the reported range to show the lines as the student sees them
	# in the slice editor.
	var show_lines_from := _slice_properties.start_offset
	var show_lines_to := _slice_properties.end_offset
	var character_offset := _slice_properties.leading_spaces

	var message_node := OutputConsoleErrorMessageScene.instance() as OutputConsoleErrorMessage
	message_node.message_severity = type
	message_node.message_text = text
	message_node.message_code = code

	if line >= show_lines_from and line <= show_lines_to:
		message_node.origin_file = file_name
		message_node.origin_line = line - show_lines_from
		message_node.origin_char = character - character_offset
	else:
		message_node.external_error = true

	_message_list.add_child(message_node)
	message_node.connect("external_explain_requested", self, "_on_external_requested")
	message_node.connect("show_code_requested", self, "_on_code_requested")
	message_node.connect("explain_error_requested", self, "_on_explain_requested")

	yield(get_tree(), "idle_frame")
	_scroll_container.ensure_control_visible(message_node)


func _on_external_requested() -> void:
	_external_error_popup.show()


func _on_code_requested(file_name: String, line: int, character: int) -> void:
	emit_signal("reference_clicked", file_name, line, character)


func _on_explain_requested(error_code: int, error_message: String) -> void:
	_error_overlay_popup.error_code = error_code
	_error_overlay_popup.error_message = error_message
	_error_overlay_popup.show()
	_error_popup.show()


func _on_resized() -> void:
	_error_popup.set_margins_preset(Control.PRESET_WIDE)


func reset():
	clear_messages()
