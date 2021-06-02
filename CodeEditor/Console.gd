extends RichTextLabel


func _init():
	EventBus.connect("print_log", self, "append")

func append(thing_to_print) -> void:
	if text != "":
		text += "\n"
	text += str(thing_to_print)
