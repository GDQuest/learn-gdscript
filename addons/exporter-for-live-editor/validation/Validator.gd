# Abstract class used as a child of any Goal node
extends Node
class_name Validator

const ScriptSlice := preload("../collections/ScriptSlice.gd")

# @type Signal<LanguageError[]>
signal validation_completed(errors)

const _ERROR = "You should extend the Validator class and implement your own `validate` method."


# @abstract
#
# Must emit the `validation_completed` signal to complete validation.
#
# The signal is an array of errors. If the array is empty, the validation is
# considered successful.
#
# Use the `_validation_success()` and `_validation_error([])` methods instead of
# emitting the signal directly
func validate(_scene: Node, _script_text: ScriptSlice) -> void:
	push_error(_ERROR)
	yield(get_tree(), "idle_frame")
	_validation_success()


func _validation_success() -> void:
	emit_signal("validation_completed", [])


func _validation_error(errors: Array) -> void:
	assert(errors.size() > 0, "validation error array should contain at least one element")
	emit_signal("validation_completed", errors)


# @abstract
#
# Use this method for small verifications along the way inside a validation. This
# is equivalent to an `assert`, but it dispatches `validation_completed` with
# errors if wrong.
#
# Example Usage:
#
# ```
# func validate(scene: Node, script_text: String) -> void:
#   if not verify(something, "oh no, something is wrong"):
#      return
#   if not verify(something else, "aargh"):
#      return
#   _validation_success()
# ```
func verify(thing: bool, message: String) -> bool:
	if thing:
		return true
	_validation_error([message])
	return false
