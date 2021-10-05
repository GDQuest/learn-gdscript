## A utility node that collects all goals in a scene, listens to
## their `request_validation` signal.
## when the validation request is dispatched, it collects all
## child Validator instances, runs them, and sets the result 
## ("valid" or "invalid", respectively 2 or 1) on the parent Goal.
##
## Note:
## 
## `scene` and `script_slice` property need to be set before any
## validation occurs
extends Node

enum STATUS { NONE, INVALID, VALID }

const ScriptSlice := preload("../collections/ScriptSlice.gd")
const GROUP_NAME = "validator_goals"
const SIGNAL_NAME = "request_validation"

signal validation_completed(errors)
signal validation_completed_all(errors)

var scene: Node
var script_slice: ScriptSlice

# keeps a cache of goals present in the project
var _goals := {}


func _ready() -> void:
	connect_goals()


# Connects all goals in the goals group to this validation manager.
# 
# This method is safe to run multiple times, because goals that have been
# processed already will be skipped.
func connect_goals() -> void:
	var goals := get_tree().get_nodes_in_group(GROUP_NAME)
	for goal in goals:
		# warning-ignore:unsafe_cast
		goal = goal as Node
		if OS.is_debug_build():
			var _is_valid = _goal_node_has_required_properties(goal)
		if not (goal in _goals):
			goal.connect(SIGNAL_NAME, self, "validate", [goal])
			_goals[goal] = true


# Disconnects all cached goals
func disconnect_goals() -> void:
	for goal in _goals:
		goal.disconnect(SIGNAL_NAME, self, "validate")
	_goals = {}


# Method used in debug builds to make sure a goal is conform to contract
func _goal_node_has_required_properties(goal: Node) -> bool:
	var _has_method := goal.has_method("set_status")
	assert(_has_method, "goal %s has no method `set_status`" % [goal.get_path()])
	var _has_signal := goal.has_signal(SIGNAL_NAME)
	assert(_has_signal, "goal %s has no signal `request_validation`" % [goal.get_path()])
	var _has_validators := _get_validators(goal).size() > 0
	if not _has_validators:
		push_warning("Goal has no validators and will always return true (%s)" % goal.get_path())
	return _has_method and _has_signal and _has_validators


# Returns all validators for a specific node
func _get_validators(goal: Node) -> Array:
	var validators = []
	for child in goal.get_children():
		if child is Validator:
			validators.append(child)
	return validators


# Validates a goal by validating in turn all its nested validators
func validate(goal: Node) -> void:
	if not scene or not script_slice:
		push_error("Either the playing scene, or the script slice aren't set. Make sure you set them before validating")
		return
	var validators := _get_validators(goal)
	var errors = []
	for index in validators.size():
		var validator: Validator = validators[index]
		validator.validate(scene, script_slice)
		errors += yield(validator, "validation_completed")
	var status:int = STATUS.VALID if errors.size() == 0 else STATUS.INVALID
	goal.set_status(status)
	emit_signal("validation_completed", errors)


# Validates all goals currently in the goals group 
func validate_all() -> void:
	var errors := []
	for goal in _goals:
		goal = goal as Node
		if goal.is_in_group(GROUP_NAME):
			validate(goal)
			errors += yield(self, "validation_completed")
	emit_signal("validation_completed_all", errors)
