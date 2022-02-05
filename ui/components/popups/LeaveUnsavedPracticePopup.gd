tool
extends ConfirmPopup

# Contains UINavigator.NAVIGATION_REQUEST_TYPE and a payload
# TODO: Create a NavigationRequest class that handles this?
var _navigation_type := -1
var _payload := []

func set_navigation_data(type: int, payload: Array) -> void:
	_navigation_type = type
	_payload = payload

func get_navigation_type() -> int:
	return _navigation_type
	
func get_payload() -> Array:
	return _payload
