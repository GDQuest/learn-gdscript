tool
extends Node2D

const color_green := Color("3dff6e")
const color_red := Color("928fb8")

export var _offset := Vector2.ZERO
export (int, 1, 7) var number := 5 setget _set_number, get_number
export (int, 1, 7) var divisor := 3 setget _set_divisor, get_divisor

onready var _blocks := $Blocks
onready var _string := $String
onready var _remainder := $Remainder


func _ready() -> void:
	_align_blocks()
	_update_visual()


func _align_blocks() -> void:
	for c in _blocks.get_children():
		c.modulate.a = 0.0
	
	var row := 0
	var column := 0
	for i in range(max(number, divisor)):
		_blocks.get_child(i).position = Vector2(40 * column, row * 40) + _offset
		row += 1
		if row % divisor == 0 and divisor < number:
			column += 1
			row = 0


func _update_visual() -> void:
	if number >= divisor:
		for i in range(number):
			_blocks.get_child(i).modulate.a = 0
			if i < number - (number % divisor):
				_blocks.get_child(i).modulate = color_red
			else:
				_blocks.get_child(i).modulate = color_green
	else:
		for i in range(divisor):
			_blocks.get_child(i).modulate = color_green
			
			if i >= number:
				_blocks.get_child(i).modulate = color_red
	
	_string.text = "%s %% %s" % [number, divisor]
	_remainder.text = "Remainder: %s" % [number % divisor]


func _set_number(value: int) -> void:
	number = value
	if not _blocks:
		return
	_align_blocks()
	_update_visual()


func _set_divisor(value: int) -> void:
	divisor = value
	if not _blocks:
		return
	_align_blocks()
	_update_visual()


func get_number() -> int:
	return number


func get_divisor() -> int:
	return divisor
