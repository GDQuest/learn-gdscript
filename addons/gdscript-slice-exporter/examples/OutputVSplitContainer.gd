# Split container for the game viewport and output console.
class_name OutputVSplitContainer
extends VSplitContainer

onready var game_viewport := $GameViewport
onready var output_console := $Console


func toggle_game_view(is_visible: bool) -> void:
	game_viewport.visible = is_visible


func toggle_console_view(is_visible: bool) -> void:
	output_console.visible = is_visible
