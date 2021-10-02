# Displays messages printed by the user in the interface. Uses BBCode to display
# different messages with different colors.
extends RichTextLabel

enum LogType { PLAIN, WARNING, ERROR }

export var color_warning := Color("#D09532")
export var color_error := Color("#D01C22")


func _init():
	bbcode_enabled = true
	EventBus.connect("print_log", self, "append", [LogType.PLAIN])
	EventBus.connect("print_error", self, "append", [LogType.WARNING])
	EventBus.connect("print_warning", self, "append", [LogType.ERROR])


func append(message: String, type: int) -> void:
	var new_bbcode := message
	if type in [LogType.WARNING, LogType.ERROR]:
		var color := color_warning if type == LogType.WARNING else color_error
		new_bbcode = "[color=#%s]%s[/color]" % [color.to_html(false), message]
	new_bbcode += "\n"
	# Modifying bbcode_text directly re-parses all bbcode every time. Using
	# append_bbcode() only parses the new string.
	append_bbcode(new_bbcode)
