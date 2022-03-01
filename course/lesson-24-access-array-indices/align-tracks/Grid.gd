tool
extends Node2D

enum LABELS{
	HIDE,
	SHOW_COORDINATES,
	SHOW_POSITIONS
}

export var grid_size := Vector2(4, 4) setget set_grid_size
export var cell_size := 64 setget set_cell_size
export var line_width := 4 setget set_line_width
export var font_size: int setget set_font_size, get_font_size
export var text_shift := Vector2(-5, -5) setget set_text_shift
export(LABELS) var labels_type = LABELS.SHOW_COORDINATES setget set_labels_type

const font_file = preload("res://ui/theme/fonts/OpenSans-Regular.ttf")
var font := DynamicFont.new()

func _init() -> void:
	font.font_data = font_file
	font.size = 10


func _draw() -> void:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos := Vector2(x * cell_size, y * cell_size)
			var size := Vector2.ONE * cell_size
			var rect := Rect2(pos, size)
			draw_rect(rect, Color.white, false, line_width)
			if labels_type == LABELS.HIDE:
				continue
			var text_pos = pos + text_shift
			var text = '(%s,%s)'%[x, y] if labels_type == LABELS.SHOW_COORDINATES else '%s'%[pos]
			draw_string(font, text_pos, text)


func set_grid_size(new_grid_size: Vector2) -> void:
	grid_size = new_grid_size
	update()

func set_cell_size(new_cell_size: int) -> void:
	cell_size = new_cell_size
	update()

func set_line_width(new_line_width: int) -> void:
	line_width = new_line_width
	update()

func set_font_size(new_font_size: int) -> void:
	font.size = new_font_size

func get_font_size() -> int:
	return font.size

func set_text_shift(new_text_shift: Vector2) -> void:
	text_shift = new_text_shift
	update()

func set_labels_type(type: int) -> void:
	labels_type = type
	update()
