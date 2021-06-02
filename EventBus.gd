extends Node

signal print_log(thing_to_print)
signal print_warning(thing_to_print)
signal print_error(thing_to_print)

export var local_print := false


func print_log(thing_to_print: Array) -> void:
	emit_signal("print_log", PoolStringArray(thing_to_print).join(" "))
	if local_print:
		prints(thing_to_print)


func print_error(thing_to_print) -> void:
	emit_signal("print_error", thing_to_print)
	if local_print:
		push_error(thing_to_print)


func print_warning(thing_to_print) -> void:
	emit_signal("print_warning", thing_to_print)
	if local_print:
		push_warning(thing_to_print)
