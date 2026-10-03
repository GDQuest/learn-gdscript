class_name RunnableCodeExampleDebugger
extends Control

const DebuggerConsoleMonitoredVariable := preload(
	"res://ui/components/DebuggerConsoleMonitoredVariable.gd"
)
const DebuggerConsoleMonitoredVariableScene := preload(
	"res://ui/components/DebuggerConsoleMonitoredVariable.tscn"
)
const UNINITIALIZED_VARIABLE_VALUE := "uninitialized"

@export var monitored_variables: Array[String] = []

var _scene_instance: Node
var _console_variables: Array[DebuggerConsoleMonitoredVariable] = []

var _is_stepping_active := false

@onready var _variables_container: VBoxContainer = %VariablesContainer


func _ready() -> void:
	for variable in monitored_variables:
		var console_variable := DebuggerConsoleMonitoredVariableScene.instantiate()
		console_variable.variable_name = variable
		_variables_container.add_child(console_variable)
		_console_variables.append(console_variable)

	var name_width := 0.0
	for console_variable in _console_variables:
		name_width = maxf(name_width, console_variable.get_name_width())
	for console_variable in _console_variables:
		console_variable.set_name_width(name_width)


func setup(runnable_code: RunnableCodeExample) -> void:
	runnable_code.code_updated.connect(_on_code_updated)


func bind_scene_to_debug(scene_instance: Node) -> void:
	_scene_instance = scene_instance
	_is_stepping_active = false
	_on_code_updated()


func set_stepping_active(active: bool) -> void:
	_is_stepping_active = active


func _on_code_updated() -> void:
	for i in range(monitored_variables.size()):
		var variable_name: String = monitored_variables[i]
		var variable_value: String = str(_scene_instance.get(variable_name))

		var is_initialized := variable_value != UNINITIALIZED_VARIABLE_VALUE
		_console_variables[i].set_value(
			variable_value if is_initialized else tr("Not set"),
			_is_stepping_active and is_initialized,
		)
