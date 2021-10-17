class_name CodeEditor
extends PanelContainer

const SliceEditor := preload("../ui/SliceEditor.gd")

onready var slice_editor := find_node("SliceEditor") as SliceEditor
onready var save_button := find_node("SaveButton") as Button
onready var pause_button := find_node("PauseButton") as Button
onready var solution_button := find_node("SolutionButton") as Button
