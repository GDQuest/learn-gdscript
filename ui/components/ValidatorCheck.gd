class_name ValidatorCheck
extends "./Check.gd"

const GROUP_NAME = "validator_checks"
var _button := Button.new()

# Sends a request to the ValidationManager to run children validators
signal request_validation

# adds or removes a goal from the checks group.
# ValidationManager expects all checks to be in the group at `_ready()`, so if
# you activate a goal later, you'll have to rerun the ValidationManager's
# `connect_checks()`
export var is_active := true setget set_active, get_active


func _init() -> void:
	_button.text = "test"
	add_child(_button)
	# TODO: unhide once we decide how to handle individual checks
	_button.visible = false
	set_active(is_active)


func _ready() -> void:
	_button.connect("pressed", self, "request_validation")


func request_validation() -> void:
	emit_signal("request_validation")


func set_active(new_is_active: bool) -> void:
	is_active = new_is_active
	var _is_in_group = is_in_group(GROUP_NAME)
	if is_active:
		if not _is_in_group:
			add_to_group(GROUP_NAME)
	else:
		if _is_in_group:
			remove_from_group(GROUP_NAME)


func get_active() -> bool:
	return is_in_group(GROUP_NAME)


func _get_configuration_warning() -> String:
	for child in get_children():
		if child is Validator:
			return ""
	return "Goal requires at least one Validator"
