## This is the base class for the different output consoles that print messages
## to the user, both in the practice and in the lessons.
##
## This script itself does not do much. See the classes that extend it.
class_name OutputConsole
extends Control

signal messages_changed

@export var print_message_scene: PackedScene

@onready var _scroll_container: ScrollContainer = %ScrollContainer
@onready var _message_list: VBoxContainer = %MessageList


func clear_messages() -> void:
	if not is_inside_tree():
		return

	for message in _message_list.get_children():
		_message_list.remove_child(message)
		message.queue_free()
	messages_changed.emit()


func print_output(values: Array) -> void:
	if not is_inside_tree():
		return

	var message := print_message_scene.instantiate() as Control
	message.get_node("Label").text = " ".join(PackedStringArray(values))
	_add_message(message)


func _add_message(message: Control) -> void:
	_message_list.add_child(message)
	messages_changed.emit()
	# TODO: Verify if we need to keep this.
	await get_tree().process_frame
	if is_instance_valid(message) and message.get_parent() == _message_list:
		_scroll_container.ensure_control_visible(message)


# TODO: unnecessary indirection? Check and if so, remove this in favor of
# calling clear messages directly.
func reset() -> void:
	clear_messages()
