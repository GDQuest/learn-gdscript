# Abstract class used as a child of any Goal node
extends Node
class_name Validator

const ScriptHandler := preload("../collections/ScriptHandler.gd")
const ScriptSlice := preload("../collections/ScriptSlice.gd")
const _ERROR = "You should extend the Validator class and implement your own `validate` method."

# @type Signal[LanguageError[]]
signal validation_completed(errors)

# This is not used by the validator directly, but in some circumstances, the
# validator may be used by other modules to create UI nodes. In that case, the
# title attribute can be used to derive a check widget
export var title := ""


# DEPRECATED
# @abstract
#
# Must emit the `validation_completed` signal to complete validation.
#
# The signal is an array of errors. If the array is empty, the validation is
# considered successful.
#
# Use the `_validation_success()` and `_validation_error([])` methods instead of
# emitting the signal directly
func validate(_scene: Node, _script_handler: ScriptHandler, _script_text: ScriptSlice) -> void:
	push_error(_ERROR)
	_validation_success()

# @abstract
#
# Must emit the `validation_completed` signal to complete validation.
#
# The signal is an array of errors. If the array is empty, the validation is
# considered successful.
#
# Use the `_validation_success()` and `_validation_error([])` methods instead of
# emitting the signal directly
func validate_scene_and_script(_scene: Node, _slice_properties: SliceProperties) -> void:
	push_error(_ERROR)
	_validation_success()

func _validation_success() -> void:
	yield(get_tree(), "idle_frame")
	emit_signal("validation_completed", [])


func _validation_error(errors: Array) -> void:
	assert(errors.size() > 0, "validation error array should contain at least one element")
	yield(get_tree(), "idle_frame")
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
	push_warning("Validation error: %s" % [message])
	_validation_error([message])
	return false
