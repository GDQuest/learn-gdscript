# This console displays messages. It adds new lines automatically
class_name OutputConsole
extends PanelContainer

signal reference_clicked(file_name, line_nb, character)

const OutputConsoleMessage := preload("res://ui/components/OutputConsoleMessage.gd")
const OutputConsoleMessageScene := preload("res://ui/components/OutputConsoleMessage.tscn")

onready var _scroll_container := $MarginContainer/ScrollContainer as ScrollContainer
onready var _message_list := $MarginContainer/ScrollContainer/MarginContainer/MessageList as Control
onready var _external_error_popup := $ExternalErrorPopup as Control


func _ready() -> void:
	_external_error_popup.set_as_toplevel(true)
	
	LiveEditorMessageBus.connect("print_request", self, "record_message_for_line")


# Adds a message related to a specific line in a specific file
func record_message_for_line(
	type: int, text: String, file_name: String, line: int, character: int
) -> void:
	# We need to adjust the reported range to show the lines as the student sees them
	# in the slice editor.
	var slice_properties := LiveEditorState.current_slice
	var show_lines_from = slice_properties.start_offset
	var show_lines_to = slice_properties.end_offset

	var message_node := OutputConsoleMessageScene.instance() as OutputConsoleMessage
	message_node.message_severity = type
	message_node.message_text = text
	
	if line >= show_lines_from and line <= show_lines_to:
		message_node.origin_file = file_name
		message_node.origin_line = line - show_lines_from + 1
		message_node.origin_char = character
	else:
		message_node.external_error = true
	
	_message_list.add_child(message_node)
	message_node.connect("external_explain_requested", self, "_on_external_requested")
	message_node.connect("show_code_requested", self, "_on_code_requested")
	
	yield(get_tree(), "idle_frame")
	_scroll_container.ensure_control_visible(message_node)


func _on_external_requested() -> void:
	_external_error_popup.show()


func _on_code_requested(file_name: String, line: int, character: int) -> void:
	emit_signal("reference_clicked", file_name, line, character)
