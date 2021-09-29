extends RichTextLabel


func _ready() -> void:
	LiveEditorMessageBus.connect("print_request", self, "_on_print_request")


func _on_print_request(type: int, thing_to_print: String, line_nb: int, character: int) -> void:
	var prefix = "(%s:%s)"%[line_nb, character]
	match type:
		LiveEditorMessageBus.MESSAGE_TYPE.ASSERT:
			prefix = " ASSERT: "
		LiveEditorMessageBus.MESSAGE_TYPE.ERROR:
			prefix = " ERROR: "
		LiveEditorMessageBus.MESSAGE_TYPE.WARNING:
			prefix = " WARNING: "
	add_line(prefix + thing_to_print)


func add_line(line: String) -> void:
	append_bbcode(line)
	newline()
