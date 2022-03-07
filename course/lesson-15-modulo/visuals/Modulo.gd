tool
extends Node2D


const NORMAL_STYLEBOX := preload("res://course/lesson-15-modulo/visuals/Modulo/normal_stylebox.tres")
const REMAINDER_STYLEBOX := preload("res://course/lesson-15-modulo/visuals/Modulo/remainder_stylebox.tres")
const MODULO_SIZE_X := 48
const MODULO_GAP := 4

export (int, 1, 7) var number := 5 setget _set_number
export (int, 1, 7) var modulo := 3 setget _set_modulo

var number_color := Color.black
var modulo_color := Color.black

onready var _result := $Result as Control
onready var _result_blocks := $Result/HBoxContainerBlocks as HBoxContainer
onready var _result_modulo := $Result/HBoxContainerModulo as HBoxContainer
onready var _string := $String as RichTextLabel
onready var _remainder := $Remainder as Label

func _ready() -> void:
	number_color = NORMAL_STYLEBOX.border_color
	modulo_color = _result_modulo.get_child(0).get_stylebox("panel").border_color
	_update_visual()


func _update_visual() -> void:
	var remainder := number % modulo
	var cap := max(number, remainder)
	for i in range(_result_blocks.get_child_count()):
		var block: Panel = _result_blocks.get_child(i)
		block.visible = i < cap
		block.add_stylebox_override("panel", NORMAL_STYLEBOX if i < number - remainder else REMAINDER_STYLEBOX)

	var rest := int(number / modulo)
	for i in range(_result_modulo.get_child_count()):
		var modulo_highlight: Panel = _result_modulo.get_child(i)
		modulo_highlight.visible = i < rest
		modulo_highlight.rect_min_size.x = MODULO_SIZE_X * modulo + MODULO_GAP * (modulo - 1)

	_string.bbcode_text = (
		"[center][color=#%s]%s[/color] %% [color=#%s]%s[/color][/center]" %
		[number_color.to_html(), number, modulo_color.to_html(), modulo]
	)
	_remainder.text = "Remainder: %s" % [number % modulo]


func _set_number(value: int) -> void:
	number = value
	if not _result:
		return
	_update_visual()


func _set_modulo(value: int) -> void:
	modulo = value
	if not _result:
		return
	_update_visual()
