extends Node

const RegExp := preload("./utils/RegExp.gd")

enum MESSAGE_TYPE { PRINT, PRINTS, ERROR, WARNING, ASSERT }

signal print_request(type, thing_to_print, line_nb, character)

var script_replacements := RegExp.collection(
	{
		"\\b(?<command>prints)\\((?<args>.*?)\\)":
		"LiveEditorMessageBus.print_log([{args}], {line}, {char})",
		"\\b(?<command>print)\\((?<args>.*?)\\)":
		"LiveEditorMessageBus.print_log([{args}], {line}, {char})",
		"\\b(?<command>push_error)\\((?<args>.*?)\\)":
		"LiveEditorMessageBus.print_error({args}, {line}, {char})",
		"\\b(?<command>push_warning)\\((?<args>.*?)\\)":
		"LiveEditorMessageBus.print_warning({args}, {line}, {char})",
		"\\b(?<command>assert)\\((?<args>.*?)\\)":
		"LiveEditorMessageBus.print_assert({args}, {line}, {char})",
	}
)

export var local_print: bool = bool(OS.is_debug_build())


func replace_script(script_text: String) -> String:
	var lines = script_text.split("\n")
	for line_nb in lines.size():
		var line: String = lines[line_nb]
		for _regex in script_replacements._regexes:
			var regex := _regex as RegEx
			var replacement: String = script_replacements._regexes[regex]
			var start := 0
			var end := line.length()
			while start < end:
				var maybe_match = regex.search(line, start)
				if not maybe_match:
					start = end
					break
				else:
					var m := maybe_match as RegExMatch
					var starting_char := m.get_start()
					var ending_char := m.get_end()
					var args = m.get_string("args")
					if args[0] == '"':
						# Godot somehow removes `"` if they are the first
						# character of a string
						args = " " + args
					var command = m.get_string("command")
					var config = {
						"command": command, "args": args, "char": starting_char, "line": line_nb
					}
					var slice_middle := replacement.format(config)
					var slice_beginning := line.left(starting_char)
					var slice_end := line.right(ending_char)
					var replaced_line := slice_beginning + slice_middle + slice_end
					var diff: int = abs(replaced_line.length() - line.length())
					start = ending_char + diff
					lines[line_nb] = replaced_line
	return lines.join("\n")


func print_log(thing_to_print: Array, line_nb: int = 0, character: int = 0) -> void:
	var line = PoolStringArray(thing_to_print).join(" ")
	print_request(MESSAGE_TYPE.PRINT, line, line_nb, character)
	if local_print:
		prints(thing_to_print)


func print_error(thing_to_print, line_nb: int = 0, character: int = 0) -> void:
	print_request(MESSAGE_TYPE.ERROR, String(thing_to_print), line_nb, character)
	if local_print:
		push_error(thing_to_print)


func print_warning(thing_to_print, line_nb: int = 0, character: int = 0) -> void:
	print_request(MESSAGE_TYPE.WARNING, String(thing_to_print), line_nb, character)
	if local_print:
		push_warning(thing_to_print)


func print_assert(assertion: bool, provided_message := "", line_nb: int = 0, character: int = 0) -> void:
	var message = (
		""
		if assertion
		else "Assertion failed" if provided_message == "" else provided_message
	)
	if not assertion:
		print_request(MESSAGE_TYPE.ASSERT, message, line_nb, character)
	if local_print:
		push_error(message)


func print_request(message_type: int, message: String, line_nb: int, character: int) -> void:
	emit_signal("print_request", message_type, message, line_nb, character)
