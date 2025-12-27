class_name RunnableCodeExampleDebugger
extends PanelContainer

const DebuggerConsoleMonitoredVariable = preload("res://ui/components/DebuggerConsoleMonitoredVariable.tscn")
const UNINITIALIZED_VARIABLE_VALUE := "uninitialized"

@export var monitored_variables: Array[String] = []

@onready var variables_container := $MarginContainer/VariablesContainer as VBoxContainer

@onready var _scene_instance: Node = null
var _console_variables: Array[Control] = []


func setup(runnable_code: Node, scene_instance: Object) -> void:
	assert(runnable_code.has_signal("code_updated"))
	runnable_code.connect("code_updated", Callable(self, "_on_code_updated"))
	_scene_instance = scene_instance

	for variable in monitored_variables:
		var console_variable: Control = DebuggerConsoleMonitoredVariable.instantiate()
		variables_container.add_child(console_variable)
		_console_variables.append(console_variable)

	if not is_inside_tree():
		await ready
	_on_code_updated()


func _on_code_updated() -> void:
	for i in range(monitored_variables.size()):
		var variable_name: String = monitored_variables[i]
		var variable_value: String = str(_scene_instance.get(variable_name))

		_console_variables[i].call("set_values", ["%s:" % variable_name, variable_value])
		_console_variables[i].visible = variable_value != UNINITIALIZED_VARIABLE_VALUE
