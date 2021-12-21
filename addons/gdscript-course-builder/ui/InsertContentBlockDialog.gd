tool
extends WindowDialog

signal block_selected(at_index)
signal quiz_selected(at_index)

var insert_at_index := -1

onready var _add_block_button := $MarginContainer/Layout/Options/AddBlockButton as Button
onready var _add_quiz_button := $MarginContainer/Layout/Options/AddQuizButton as Button
onready var _cancel_button := $MarginContainer/Layout/Buttons/CancelButton as Button


func _ready() -> void:
	_add_block_button.connect("pressed", self, "_on_add_block_pressed")
	_add_quiz_button.connect("pressed", self, "_on_add_quiz_pressed")
	_cancel_button.connect("pressed", self, "_on_cancelled")


func _on_add_block_pressed() -> void:
	emit_signal("block_selected", insert_at_index)
	hide()


func _on_add_quiz_pressed() -> void:
	emit_signal("quiz_selected", insert_at_index)
	hide()


func _on_cancelled() -> void:
	hide()
