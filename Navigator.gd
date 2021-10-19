extends PanelContainer


func _ready() -> void:
	NavigationManager.root_container = $VBoxContainer/PanelContainer
	NavigationManager.connect("transition_in_completed", self, "_on_navigation_transition")
	NavigationManager.connect("transition_out_completed", self, "_on_navigation_transition")


func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_back"):
		NavigationManager.back()


func _on_navigation_transition():
	var is_root_screen = NavigationManager.current_url.path == ""
	$VBoxContainer/Buttons/HBoxContainer/BackButton.disabled = is_root_screen
	$VBoxContainer/Buttons/HBoxContainer/LoadPage.disabled = not is_root_screen
