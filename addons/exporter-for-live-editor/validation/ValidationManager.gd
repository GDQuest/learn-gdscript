# A utility node that collects all checks in a scene, listens to
# their `request_validation` signal.
# when the validation request is dispatched, it collects all
# child Validator instances, runs them, and sets the result
# ("valid" or "invalid", respectively 2 or 1) on the parent check.
#
# Note:
#
# `scene` and `script_slice` property need to be set before any
# validation occurs
extends Node

enum STATUS { NONE, INVALID, VALID }

# DEPRECATED
const ScriptHandler := preload("../collections/ScriptHandler.gd")
# DEPRECATED
const ScriptSlice := preload("../collections/ScriptSlice.gd")
const GROUP_NAME = "validator_checks"
const SIGNAL_NAME = "request_validation"

signal validation_completed(errors)
signal validation_completed_all(errors)

var scene: Node
# DEPRECATED
var script_handler: ScriptHandler
# DEPRECATED
var script_slice: ScriptSlice

var slice_properties: SliceProperties

# keeps a cache of checks present in the project
var _checks := {}


# Connects all checks in the checks group to this validation manager.
#
# This method is safe to run multiple times, because checks that have been
# processed already will be skipped.
func connect_checks() -> void:
	var checks := get_tree().get_nodes_in_group(GROUP_NAME)
	for check in checks:
		# warning-ignore:unsafe_cast
		add_check(check as Node)


func add_check(check: Node) -> void:
	if OS.is_debug_build():
		var _is_valid = _check_node_has_required_properties(check)
	if not (check in _checks):
		check.connect(SIGNAL_NAME, self, "validate", [check])
		_checks[check] = true


# Disconnects all cached checks
func disconnect_checks() -> void:
	for check in _checks:
		check.disconnect(SIGNAL_NAME, self, "validate")
	_checks = {}


# Method used in debug builds to make sure a check is conform to contract
func _check_node_has_required_properties(check: Node) -> bool:
	var _has_method := check.has_method("set_status")
	assert(_has_method, "check %s has no method `set_status`" % [check.get_path()])
	var _has_signal := check.has_signal(SIGNAL_NAME)
	assert(_has_signal, "check %s has no signal `request_validation`" % [check.get_path()])
	var _has_validators := _get_validators(check).size() > 0
	if not _has_validators:
		push_warning("check has no validators and will always return true (%s)" % check.get_path())
	return _has_method and _has_signal and _has_validators


# Returns all validators for a specific node
func _get_validators(check: Node) -> Array:
	var validators = []
	for child in check.get_children():
		if child is Validator:
			validators.append(child)
	return validators


# Validates a check by validating in turn all its nested validators
func validate(check: Node) -> void:
	# DEPRECATED
	assert(scene, "scene is not set")
	# DEPRECATED
	assert(script_slice, "script_slice is not set")
	# DEPRECATED
	assert(script_handler, "script_handler is not set")
	# DEPRECATED
	if not scene or not script_slice or not script_handler:
		push_error(
			"Either the playing scene, or the script slice aren't set. Make sure you set them before validating"
		)
		return
	var slice := LiveEditorState.current_slice
	var validators := _get_validators(check)
	var errors = []
	for index in validators.size():
		var validator: Validator = validators[index]
		#validator.validate(scene, script_handler, script_slice)
		validator.validate_scene_and_script(scene, slice)
		errors += yield(validator, "validation_completed")
	var status: int = STATUS.VALID if errors.size() == 0 else STATUS.INVALID
	check.set_status(status)
	emit_signal("validation_completed", errors)


# Validates all checks currently in the checks group
func validate_all() -> void:
	var errors := []
	for check in _checks:
		check = check as Node
		if check.is_in_group(GROUP_NAME):
			validate(check)
			errors += yield(self, "validation_completed")
	yield(get_tree(), "idle_frame")
	emit_signal("validation_completed_all", errors)
