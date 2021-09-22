extends HBoxContainer

var scene_path_control := LineEdit.new()
var file_browser_button := ToolButton.new()
var run_button := ToolButton.new()
var remove_button := ToolButton.new()
var pin_button := ToolButton.new()
var scene_path: String setget set_scene_path, get_scene_path

signal scene_path_changed(text)
signal file_browser_requested
signal run_button_pressed
signal pin_button_toggled


func _init() -> void:
	scene_path_control.rect_min_size = Vector2(250, 20)
	pin_button.toggle_mode = true

	add_child(scene_path_control)
	add_child(file_browser_button)
	add_child(remove_button)
	add_child(pin_button)
	add_child(run_button)

	scene_path_control.connect("text_changed", self, "_on_scene_path_text_changed")
	file_browser_button.connect("pressed", self, "emit_signal", ["file_browser_requested"])
	remove_button.connect("pressed", self, "_on_remove_button_pressed")
	pin_button.connect("toggled", self, "_on_pin_button_toggled")
	run_button.connect("pressed", self, "emit_signal", ["run_button_pressed"])


func _on_scene_path_text_changed(new_text: String):
	emit_signal("scene_path_changed", new_text)


func _on_remove_button_pressed():
	scene_path_control.text = ""
	_on_scene_path_text_changed("")


func _on_pin_button_toggled(button_pressed: bool) -> void:
	emit_signal("pin_button_toggled", button_pressed)


func set_scene_path(new_path: String) -> void:
	scene_path_control.text = new_path


func get_scene_path() -> String:
	return scene_path_control.text
