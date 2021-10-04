## This overlay creates squiggly lines, and places them at the right
## offset in a SliceEditor.
## 
## When the squiggly line is hovered, a pop up with details about the
## related error appears.
##
## This overlay depends on having a custom theme set, with a custom
## font. It will not work otherwise.
extends Control

const LanguageServerError := preload("../lsp/LanguageServerError.gd")
const LanguageServerRange = LanguageServerError.LanguageServerRange

onready var _character_width: float = (
	theme.default_font.get_char_size(ord("0")).x
	if theme and theme.default_font
	else 1
)
onready var _line_spacing: int = (
	theme.get_constant("line_spacing", "TextEdit")
	if theme and theme.has_constant("line_spacing", "TextEdit")
	else 1
)
onready var _row_height: int = (
	(theme.default_font.get_height() if theme and theme.default_font else 1)
	+ _line_spacing
)
# The horizontal 30 px corresponds to the left gutter with line numbers. Found in the source code.
onready var _stylebox := (
	theme.get_stylebox("normal", "TextEdit")
	if theme and theme.has_stylebox("normal", "TextEdit")
	else StyleBoxFlat.new()
)


func clean() -> void:
	for overlay in get_children():
		overlay.queue_free()


func add_error(error: LanguageServerError, offset: Vector2, scroll_offset: Vector2) -> ErrorOverlay:
	var error_overlay := ErrorOverlay.new()
	var region := calculate_error_region(error.error_range, offset, scroll_offset)

	error_overlay.rect_position = region.position
	error_overlay.rect_size = region.size
	error_overlay.panel_position = region.position + Vector2(0, _row_height) + rect_global_position
	add_child(error_overlay)
	return error_overlay


func calculate_error_region(
	error_range: LanguageServerRange, offset: Vector2, scroll_offset: Vector2
) -> Rect2:
	var start := (
		Vector2(
			error_range.start.character * _character_width, error_range.start.line * _row_height
		)
		+ offset
		- scroll_offset
	)
	start.x = max(offset.x, start.x)
	start.y = max(0, start.y)

	var size := Vector2(
		error_range.end.character * _character_width - start.x - scroll_offset.x, _row_height
	)
	size.x = min(size.x, rect_size.x - offset.x - _stylebox.content_margin_right)
	return Rect2(start, size)


func calculate_scroll_offset(text_edit: TextEdit) -> Vector2:
	return Vector2(text_edit.scroll_horizontal, text_edit.scroll_vertical * _row_height)


func calculate_offset(text_edit: TextEdit) -> Vector2:
	var out := Vector2()
	var line_count := text_edit.get_line_count()
	var line_numbers_width := 0
	while line_count != 0:
		line_numbers_width += 1
		line_count /= 10
	out.x = _character_width * line_numbers_width + _stylebox.content_margin_left
	out.y = _stylebox.content_margin_top
	return out


class ErrorOverlay:
	extends Control
	var squiggly := SquigglyLine.new()
	var panel_position: Vector2

	func _init() -> void:
		rect_min_size = Vector2(40, 40)
		mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(squiggly)

	func _ready() -> void:
		squiggly.wave_width = rect_size.x
		squiggly.position.y = (
			rect_size.y
			- squiggly.WAVE_HEIGHT / 2.0
			- squiggly.LINE_THICKNESS / 2.0
		)


class SquigglyLine:
	extends Line2D
	const WAVE_WIDTH := 18.0
	const WAVE_HEIGHT := 4.0
	const LINE_THICKNESS := 2.0
	const VERTEX_COUNT := 16

	const COLOR_ERROR := Color("#d81946")
	const COLOR_WARNING := Color("#ffe478")

	var wave_width := 64.0 setget set_wave_width

	func update_drawing() -> void:
		points.empty()
		for i in VERTEX_COUNT * wave_width / WAVE_WIDTH:
			add_point(
				Vector2(
					WAVE_WIDTH * i / VERTEX_COUNT, WAVE_HEIGHT / 2.0 * sin(TAU * i / VERTEX_COUNT)
				)
			)

	func set_wave_width(value: float) -> void:
		wave_width = value
		update_drawing()
