# Base class for lesson and practice pages. Provides an interface for navigation
# in relation with NavigationManager.
#
# Defines required overridable functions for interaction with
# NavigationManager.gd.
#
# Defaults to always accept being unlaoded unless overriden.
class_name UINavigatablePage
extends Control

var _is_current_screen := false


func _ready() -> void:
	NavigationManager.connect(
		"all_screens_unload_requested", self, "_on_all_screens_unload_requested"
	)


func set_is_current_screen(value: bool) -> void:
	if _is_current_screen == value:
		return

	_is_current_screen = value

	if _is_current_screen:
		NavigationManager.connect(
			"last_screen_unload_requested", self, "_on_current_screen_unload_requested"
		)
	else:
		NavigationManager.disconnect(
			"last_screen_unload_requested", self, "_on_current_screen_unload_requested"
		)


func _accept_unload() -> void:
	NavigationManager.confirm_unload()


func _deny_unload() -> void:
	NavigationManager.deny_unload()


# Overridde if unload requires waiting
func _on_current_screen_unload_requested() -> void:
	_accept_unload()


# Overridde if unload requires waiting
func _on_all_screens_unload_requested() -> void:
	if _is_current_screen:
		_on_current_screen_unload_requested()
