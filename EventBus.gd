extends Node

signal print_log(thing_to_print)

func print_log(thing_to_print) -> void:
	emit_signal("print_log", thing_to_print)
	print(thing_to_print)
