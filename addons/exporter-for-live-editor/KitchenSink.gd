extends Control

const SlicesList := preload("./SlicesList.gd")
const ScriptSlice := preload("./collection/ScriptSlice.gd")
const SliceEditor := preload("./SliceEditor.gd")

onready var slices_list := $SlicesList as SlicesList
onready var slice_editor := $VBoxContainer/SliceEditor as SliceEditor
onready var save_button := $VBoxContainer/HBoxContainer/Button as Button


var current_slice: ScriptSlice


func _ready() -> void:
	save_button.connect("pressed", self, "_on_save_button_pressed")
	slices_list.connect("slice_selected", self, "_on_slice_selected")


func _on_slice_selected(script_slice: ScriptSlice) -> void:
	current_slice = script_slice
	slice_editor.script_slice = script_slice


func _on_save_button_pressed() -> void:
	print(current_slice.current_full_text)
