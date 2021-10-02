extends Node
class_name Validator

signal validation_completed(errors)

const _ERROR = "You should extend the Validator class and implement your own `validate` method."


# Virtual method.
# Must emit the validation_completed signal to complete validation.
func validate(_scene: Node, _script_text: String):
	push_error(_ERROR)
	yield(get_tree(), "idle_frame")
	emit_signal("validation_completed", [])


func verify(thing, message: String) -> bool:
	if thing:
		return true
	emit_signal("validation_completed", [message])
	return false
