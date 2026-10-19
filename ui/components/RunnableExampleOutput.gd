class_name RunnableExampleOutput
extends OutputConsole

signal line_highlight_requested(line_number)
signal animate_arrow_requested(chars1, chars2)

const MAX_OUTPUT_HEIGHT := 180.0

@onready var _empty_output: Label = %EmptyOutput


func _ready() -> void:
	messages_changed.connect(_update_output_height)
	_message_list.minimum_size_changed.connect(_update_output_height)
	_update_output_height()


func _update_output_height() -> void:
	var has_messages := _message_list.get_child_count() > 0
	_empty_output.visible = not has_messages
	_scroll_container.visible = has_messages
	_scroll_container.custom_minimum_size.y = minf(
		_message_list.get_combined_minimum_size().y,
		MAX_OUTPUT_HEIGHT,
	)
