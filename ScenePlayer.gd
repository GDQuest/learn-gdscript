extends Control

const ScriptManager = preload("./ScriptManager.gd")
const ScriptsRepository = preload("./ScriptsRepository.gd")
const ScriptsUtils = preload("./ScriptsUtils.gd")

export (PackedScene) var scene_file := preload("res://game/Game.tscn") setget set_scene_file

var _scene_is_paused := false
var _scene: Node

onready var file_list: ItemList = find_node("FileList")
onready var code_editor: TextEdit = find_node("CodeEditor")

onready var viewport: Viewport = find_node("Viewport")
onready var game_view: ViewportContainer = find_node("GameView")
onready var game_container: Control = find_node("GamePanel")

onready var save_button: Button = find_node("SaveButton")
onready var undo_button: Button = find_node("UndoButton")
onready var pause_button: Button = find_node("PauseButton")
onready var restart_button: Button = find_node("RestartButton")

onready var errors_label: Label = find_node("LabelErrors")


func _ready():
	file_list.connect("item_activated", self, "_on_file_selected")
	save_button.connect("pressed", self, "_on_save_pressed")
	pause_button.connect("pressed", self, "_on_pause_pressed")
	restart_button.connect("pressed", self, "_on_restart_pressed")
	unpack_scene_file()
	errors_label.visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_file_list"):
		file_list.visible = not file_list.visible
		accept_event()
	elif event.is_action_pressed("toggle_distraction_free_mode"):
		game_container.visible = not game_container.visible


func set_scene_file(new_scene: PackedScene) -> void:
	scene_file = new_scene
	unpack_scene_file()


## Reads all the scripts and loads them in the editor.
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
	code_editor.text = script.current_script


func _on_save_pressed() -> void:
	var file_index := file_list.get_selected_items()[0]
	var current_script: ScriptManager = file_list.get_item_metadata(file_index)
	var new_text = code_editor.text
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
			var error_string = (
				"ERROR: %s:%s:%s"
				% [message, range_start.line, range_start.character]
			)
			errors_label.text += error_string
	errors_label.visible = errors_label.text != ""
	game_view.grab_focus()
	code_editor.release_focus()

func _on_restart_pressed() -> void:
	_scene.queue_free()
	var packed_scene = PackedScene.new()
	packed_scene.pack(_scene)
	#ResourceSaver.save("res://TempScene.tscn", packed_scene)
	set_scene_file(packed_scene)

func _on_pause_pressed() -> void:
	_scene_is_paused = not _scene_is_paused
	ScriptsUtils.pause_scene(_scene, _scene_is_paused)


func _clear_file_list() -> void:
	for item_idx in range(file_list.get_item_count() - 1, -1, -1):
		file_list.remove_item(item_idx)
