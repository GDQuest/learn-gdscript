extends Control

const ScriptHandler := preload("./collection/ScriptHandler.gd")
const ScriptSlice := preload("./collection/ScriptSlice.gd")
const SlicesList := preload("./SlicesList.gd")
const SliceEditor := preload("./SliceEditor.gd")
const GameViewport := preload("./GameViewport.gd")

onready var slices_list := $SlicesList as SlicesList
onready var slice_editor := $VBoxContainer/SliceEditor as SliceEditor
onready var save_button := $VBoxContainer/HBoxContainer/Button as Button
onready var game_viewport := $GameViewport as GameViewport

var current_slice: ScriptSlice
var current_script_handler: ScriptHandler

func _ready() -> void:
	save_button.connect("pressed", self, "_on_save_button_pressed")
	slices_list.connect("slice_selected", self, "_on_slice_selected")


func _on_slice_selected(script_handler: ScriptHandler, script_slice: ScriptSlice) -> void:
	current_slice = script_slice
	current_script_handler = script_handler
	slice_editor.script_slice = script_slice


func _on_save_button_pressed() -> void:
	game_viewport.update_nodes(current_script_handler, current_slice)
