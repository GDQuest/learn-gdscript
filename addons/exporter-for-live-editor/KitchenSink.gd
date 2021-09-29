extends Control

const ScriptHandler := preload("./collection/ScriptHandler.gd")
const ScriptSlice := preload("./collection/ScriptSlice.gd")
const SlicesList := preload("./SlicesList.gd")
const SliceEditor := preload("./SliceEditor.gd")
const GameViewport := preload("./GameViewport.gd")
const GameConsole := preload("./GameConsole.gd")
const ScriptVerifier := preload("./ScriptVerifier.gd")
const LanguageServerError := preload("./LanguageServerError.gd")

onready var slices_list := $SlicesList as SlicesList
onready var slice_editor := $VBoxContainer/SliceEditor as SliceEditor
onready var game_viewport := $GameViewport as GameViewport
onready var save_button := $VBoxContainer/HBoxContainer/SaveButton as Button
onready var pause_button := $VBoxContainer/HBoxContainer/PauseButton as Button
onready var game_console := $VBoxContainer/Console as GameConsole

var current_slice: ScriptSlice
var current_script_handler: ScriptHandler

func _ready() -> void:
	save_button.connect("pressed", self, "_on_save_button_pressed")
	pause_button.connect("pressed", self, "_on_pause_button_pressed")
	
	slices_list.connect("slice_selected", self, "_on_slice_selected")


func _on_slice_selected(script_handler: ScriptHandler, script_slice: ScriptSlice) -> void:
	current_slice = script_slice
	current_script_handler = script_handler
	slice_editor.script_slice = script_slice


func _on_save_button_pressed() -> void:
	var script_text := current_slice.current_full_text
	var node_paths := current_script_handler.nodes
	var verifier = ScriptVerifier.new(self, script_text)
	verifier.test()
	var errors: Array = yield(verifier, "errors")
	if errors.size():
		slice_editor.errors = errors
		for index in errors.size():
			var error: LanguageServerError = errors[index]
			LiveEditorMessageBus.print_error(
				error.message, 
				error.error_range.start.line, 
				error.error_range.start.character
			)
		return
	script_text = LiveEditorMessageBus.replace_script(script_text)
	var script = GDScript.new()
	script.source_code = script_text
	var success = script.reload()
	if success != OK:
		LiveEditorMessageBus.print_error("The script has an error, but the language server didn't catch it. Are you connected?")
		return
	game_viewport.update_nodes(script, node_paths)


func _on_pause_button_pressed() -> void:
	game_viewport.toggle_scene_pause()
