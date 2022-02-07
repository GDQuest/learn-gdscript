# UIResourceView
# Defines required overridable functions for interaction with NavigationManager.gd
# Defaults to always accept being unlaoded unless overriden.
class_name UIResourceView
extends Control

var _is_current_screen := false

func _ready():
	NavigationManager.connect("confirmation_of_all_screens_unload_needed", self, "_on_all_screens_unload_requested")


func set_is_current_screen(value: bool) -> void:
	if _is_current_screen == value:
		return

	_is_current_screen = value

	if _is_current_screen:
		NavigationManager.connect("confirmation_of_last_screen_unload_needed", self, "_on_current_screen_unload_requested")
	else:
		NavigationManager.disconnect("confirmation_of_last_screen_unload_needed", self, "_on_current_screen_unload_requested")


func _accept_unload():
	NavigationManager.confirm_unload()


func _deny_unload():
	NavigationManager.deny_unload()


# To be overridden if unload requires waiting
func _on_current_screen_unload_requested() -> void:
	_accept_unload()


# TODO: Add support for checking unloading all screens
func _on_all_screens_unload_requested() -> void:
	if _is_current_screen:
		_on_current_screen_unload_requested()
