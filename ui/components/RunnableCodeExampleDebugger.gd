class_name RunnableCodeExampleDebugger
extends MarginContainer

const DebuggerConsoleMonitoredVariable = preload("res://ui/components/DebuggerConsoleMonitoredVariable.tscn")

onready var variables_container := $VariablesContainer as VBoxContainer

onready var _scene_instance : Node = null
onready var _console_variables := []


func setup(runnable_code, scene_instance) -> void:
	assert(runnable_code.has_signal("code_updated"))
	runnable_code.connect("code_updated", self, "_on_code_updated")

	assert(scene_instance.get("monitored_variables"))
	_scene_instance = scene_instance

	for variable in scene_instance.monitored_variables:
		var console_variable := DebuggerConsoleMonitoredVariable.instance()
		variables_container.add_child(console_variable)
		_console_variables.append(console_variable)


	if not is_inside_tree():
		yield(self, "ready")
	_on_code_updated()


func _on_code_updated():
	for i in range(_scene_instance.monitored_variables.size()):
		var variable_name : String = _scene_instance.monitored_variables[i]
		var variable_value : String = str(_scene_instance.get(variable_name))
		_console_variables[i].set_values(["%s:" % variable_name, variable_value])
