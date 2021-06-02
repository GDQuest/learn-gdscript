extends RichTextLabel

enum LOG_TYPE{
	LOG,
	WARNING,
	ERROR
}

func _init():
	bbcode_enabled = true
	EventBus.connect("print_log", self, "append", [LOG_TYPE.LOG])
	EventBus.connect("print_error", self, "append", [LOG_TYPE.WARNING])
	EventBus.connect("print_warning", self, "append", [LOG_TYPE.ERROR])

func append(thing_to_print: String, type: int) -> void:
	if bbcode_text != "":
		bbcode_text += "\n"
	var message = thing_to_print if type == LOG_TYPE.LOG \
		else "[color=#D09532]"+thing_to_print+"[/color]" if type == LOG_TYPE.WARNING \
		else "[color=#D01C22]"+thing_to_print+"[/color]"
	bbcode_text += str(message)
