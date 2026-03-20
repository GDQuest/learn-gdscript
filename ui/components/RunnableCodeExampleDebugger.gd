class_name RunnableCodeExampleDebugger
extends PanelContainer

const DebuggerConsoleMonitoredVariable = preload("res://ui/components/DebuggerConsoleMonitoredVariable.tscn")
const UNINITIALIZED_VARIABLE_VALUE := "uninitialized"

@export var monitored_variables: Array # (Array, String)

@export var variables_container: VBoxContainer

@onready var _scene_instance: Node = null
@onready var _console_variables := []


func setup(runnable_code, scene_instance) -> void:
	assert(runnable_code.has_signal("code_updated"))
	runnable_code.connect("code_updated", Callable(self, "_on_code_updated"))
	_scene_instance = scene_instance

	for variable in monitored_variables:
		var console_variable := DebuggerConsoleMonitoredVariable.instantiate()
		variables_container.add_child(console_variable)
		_console_variables.append(console_variable)

	if not is_inside_tree():
		await self.ready
	_on_code_updated()


func _on_code_updated():
	for i in range(monitored_variables.size()):
		var variable_name: String = monitored_variables[i]
		var variable_value: String = str(_scene_instance.get(variable_name))

		_console_variables[i].set_values(["%s:" % variable_name, variable_value])
		_console_variables[i].visible = variable_value != UNINITIALIZED_VARIABLE_VALUE
