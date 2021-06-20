extends Node
class_name Validator

const _ERROR = "you should extend the Validator class and implement your own `validate` method"

signal validation_completed(errors)

func validate(_scene: Node, _script_text: String):
	push_error(_ERROR)
	yield(get_tree(),"idle_frame")
	emit_signal("validation_completed",[])

func verify(thing, message: String) -> bool:
	if thing:
		return true
	emit_signal("validation_completed", [message])
	return false
