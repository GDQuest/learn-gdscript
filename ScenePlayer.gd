extends HBoxContainer

const ScriptManager = preload("./ScriptManager.gd")
const ScriptsRepository = preload("./ScriptsRepository.gd")
const ScriptsUtils = preload("./ScriptsUtils.gd")

export(NodePath) var file_list_node := "MarginContainer/HBoxContainer/ItemList"
onready var file_list: ItemList = get_node(file_list_node)

export(NodePath) var text_edit_node := "MarginContainer/HBoxContainer/VBoxContainer/TextEdit" 
onready var text_edit: TextEdit = get_node(text_edit_node)

export(NodePath) var save_button_node := "MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Button" 
onready var save_button: Button = get_node(save_button_node)

export(NodePath) var viewport_node := "VBoxContainer/Panel/MarginContainer/ViewportContainer/Viewport"
onready var viewport: Viewport = get_node(viewport_node)

export(NodePath) var pause_button_node := "VBoxContainer/HBoxContainer/ToolButton"
onready var pause_button: Button = get_node(pause_button_node)

export(NodePath) var errors_label_node := "MarginContainer/HBoxContainer/VBoxContainer/LabelErrors"
onready var errors_label: Label = get_node(errors_label_node)

export(PackedScene) var scene_file:PackedScene = preload("res://game/Game.tscn") setget set_scene_file

var _scene_is_paused = false
var _scene: Node

func _ready():
	file_list.connect("item_activated", self, "_on_file_selected")
	save_button.connect("pressed", self, "_on_save_pressed")
	pause_button.connect("pressed", self, "_on_pause_pressed")
	unpack_scene_file()

func set_scene_file(new_scene: PackedScene) -> void:
	scene_file = new_scene
	unpack_scene_file()

# Reads all the scripts and loads them in the editor
func unpack_scene_file() -> void:
	_scene = scene_file.instance()
	viewport.add_child(_scene)
	_clear_file_list()
	for script in ScriptsUtils.collect_scripts(_scene):
		file_list.add_item(script.name, null, true)
		file_list.set_item_metadata(file_list.get_item_count() - 1, script)
	file_list.select(0)
	_on_file_selected(0)

func _on_file_selected(file_index: int) -> void:
	var script: ScriptManager = file_list.get_item_metadata(file_index)
	text_edit.text = script.current_script

func _on_save_pressed() -> void:
	var file_index := file_list.get_selected_items()[0]
	var current_script: ScriptManager = file_list.get_item_metadata(file_index)
	var new_text = text_edit.text
	current_script.attempt_apply(new_text)
	errors_label.text = ""
	var errors = yield(current_script, "errors")
	if errors.size():
		for error in errors:
			#var code = error.code
			var message = error.message
			var range_start = error.range.start
			#var range_end = error.range.end
			#var severity = error.severity
			var error_string = "ERROR: %s:%s:%s"%[message, range_start.line, range_start.character]
			errors_label.text += error_string

func _on_pause_pressed() -> void:
	_scene_is_paused = not _scene_is_paused
	ScriptsUtils.pause_scene(_scene, _scene_is_paused)

func _clear_file_list() -> void:
	for item_idx in file_list.get_item_count():
		file_list.remove_item(item_idx)
