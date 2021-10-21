extends PanelContainer

onready var back_button := $VBoxContainer/Buttons/HBoxContainer/BackButton as Button
onready var title_label := $VBoxContainer/Buttons/HBoxContainer/BreadCrumbs as Label
onready var root_container := $VBoxContainer/PanelContainer as Container


func _ready() -> void:
	NavigationManager.root_container = root_container
	NavigationManager.connect("transition_in_completed", self, "_on_navigation_transition")
	NavigationManager.connect("transition_out_completed", self, "_on_navigation_transition")
	NavigationManager.open_url("/Course.tscn")


func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_back"):
		NavigationManager.back()


func _on_navigation_transition():
	var is_root_screen = NavigationManager.current_url.path == ""
	back_button.disabled = is_root_screen
	title_label.text = NavigationManager.breadcrumbs.join("/")
