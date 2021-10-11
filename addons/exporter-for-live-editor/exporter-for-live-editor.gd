tool
extends EditorPlugin

const LiveEditorMessageBus := preload("./utils/LiveEditorMessageBus.gd")
var container := PluginButtons.new()
var file_dialog := ScenesFileDialog.new()
var config := preload("./utils/config.gd").new(self)

const SceneFiles := preload("./collections/SceneFiles.gd")


func _enter_tree() -> void:
	add_autoload_singleton("LiveEditorMessageBus", LiveEditorMessageBus.resource_path)

	connect("scene_changed", self, "_on_scene_changed")
	connect("main_screen_changed", self, "_on_screen_changed")
	config.load_settings()

	container.scene_path = config.scene_path
	container.file_browser_button.icon = config.get_icon("File")
	container.run_button.icon = config.get_icon("Play")
	container.remove_button.icon = config.get_icon("Close")
	container.pin_button.icon = config.get_icon("Pin")
	container.pin_button.pressed = config.was_manually_set

	container.connect("scene_path_changed", self, "_on_scene_path_changed")
	container.connect("file_browser_requested", file_dialog, "popup_centered_ratio")
	container.connect("run_button_pressed", self, "_on_run_button_pressed")
	container.connect("pin_button_toggled", config, "set_was_manually_set")

	add_control_to_container(CONTAINER_TOOLBAR, container)

	file_dialog.connect("file_selected", self, "_on_file_dialog_file_selected")
	get_editor_interface().get_base_control().add_child(file_dialog)


func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_TOOLBAR, container)
	container.queue_free()
	file_dialog.queue_free()
	remove_autoload_singleton("LiveEditorMessageBus")


func _on_file_dialog_file_selected(path: String) -> void:
	if path:
		container.scene_path = path
		config.scene_path = path
		config.was_manually_set = true
		container.pin_button.pressed = true
	else:
		container.scene_path = get_current_scene_path()
		config.was_manually_set = false
		container.pin_button.pressed = false


func get_current_scene_path() -> String:
	var current_scene: Node = get_editor_interface().get_edited_scene_root()
	if current_scene:
		return current_scene.filename
	return ""


func _on_scene_path_changed(new_text: String) -> void:
	if new_text == "":
		config.was_manually_set = false
		container.pin_button.pressed = false
		config.scene_path = ""


func _on_scene_changed(new_scene: Node):
	if config.was_manually_set:
		return
	container.scene_path = new_scene.filename
	config.scene_path = new_scene.filename


func _on_screen_changed(new_screen: String) -> void:
	if new_screen == "2D" or new_screen == "3D":
		container.show()


func _save(collector: SceneFiles) -> void:
	var file_name = config.scene_path.get_basename() + ".live-editor.tres"
	var success = ResourceSaver.save(file_name, collector)
	if success == OK:
		print("Wrote the configuration to %s" % [file_name])
	else:
		push_error("Could not write the configuration to %s" % [file_name])


func _on_run_button_pressed() -> void:
	if not config.scene_path:
		return

	var packed_scene: PackedScene = load(config.scene_path)
	var scene = packed_scene.instance()

	# Add the scene to a node so we can hide the node
	# hiding the scene directly can fail if the scene
	# doesn't extend CanvasItem
	var node := Node2D.new()
	add_child(node)
	node.hide()
	node.add_child(scene)

	var collector: SceneFiles = SceneFiles.new()
	collector.collect_scripts(packed_scene, scene)
	_save(collector)

	remove_child(node)
	node.remove_child(scene)
	scene.queue_free()


class PluginButtons:
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


class ScenesFileDialog:
	extends FileDialog

	func _init() -> void:
		mode = FileDialog.MODE_OPEN_FILE
		access = FileDialog.ACCESS_RESOURCES
		set_filters(PoolStringArray(["*.tscn ; Godot Scenes"]))
