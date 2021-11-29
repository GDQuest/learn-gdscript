extends PanelContainer

export var scene_file: PackedScene

onready var _back_button := $VBoxContainer/Buttons/HBoxContainer/BackButton as Button
onready var _label := $VBoxContainer/Buttons/HBoxContainer/BreadCrumbs as Label
onready var _root_container := $VBoxContainer/PanelContainer as Container

onready var _scene_path := scene_file.resource_path


func _ready() -> void:
	_back_button.connect("pressed", NavigationManager, "back")
	NavigationManager.root_container = _root_container
	NavigationManager.connect("transition_in_completed", self, "_on_navigation_transition")
	NavigationManager.connect("transition_out_completed", self, "_on_navigation_transition")
	NavigationManager.open_url(_scene_path)


func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_back"):
		NavigationManager.back()


func _on_navigation_transition():
	var is_root_screen = NavigationManager.current_url.path == _scene_path
	_back_button.disabled = is_root_screen
	_label.text = NavigationManager.breadcrumbs.join("/")
