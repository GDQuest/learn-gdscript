tool
extends TextEdit

const ErrorOverlay := preload("ErrorOverlay.tscn")

export var class_color := Color(0.6, 0.6, 1.0)
export var member_color := Color(0.6, 1.0, 0.6)
export var keyword_color := Color(1.0, 0.6, 0.6)
export var quotes_color := Color(1.0, 1.0, 0.6)
export (String, FILE, "*.json") var keyword_data_path := "res://slide/widgets/text_edit/keywords.json"

## Stores errors
var errors := [] setget set_errors


var _font_size: float = get_theme().default_font.size
var _line_spacing := 4.0
var _row_height := _font_size + _line_spacing * 2
# The horizontal 30 px corresponds to the left gutter with line numbers. Found in the source code.
var _stylebox: StyleBox = theme.get_stylebox("normal", "TextEdit")
var _offset := Vector2(
	30.0 + _stylebox.content_margin_left,
	_stylebox.content_margin_top + _line_spacing
)

var _hscrollbar: HScrollBar
var _vscrollbar: VScrollBar

onready var _error_panel: Control = $ErrorFloatingPanel
## Keeps track of overlays to free them without risking destroying other TextEdit child nodes.
onready var _overlays: Control = $Overlays

func _ready() -> void:
	if Engine.editor_hint:
		return

	_enhance_syntax_highlighting()
	for child in get_children():
		if child is VScrollBar:
			_vscrollbar = child
		elif child is HScrollBar:
			_hscrollbar = child

	_hscrollbar.connect("value_changed", self, "update_overlays")
	_vscrollbar.connect("value_changed", self, "update_overlays")
	set_errors(
		[
			{
				message = "Test error",
				range = {start = {character = 0, line = 22}, end = {character = 40, line = 22}}
			}
		]
	)


func update_overlays(value) -> void:
	for overlay in _overlays.get_children():
		overlay.queue_free()

	for error in errors:
		var overlay: ColorRect = ErrorOverlay.instance()
		_overlays.add_child(overlay)

		overlay.connect("mouse_entered", _error_panel, "display", [error.message])
		overlay.connect("mouse_exited", _error_panel, "hide")
		var region := calculate_error_region(error.range)
		
		overlay.rect_position = region.position
		overlay.rect_size = region.size


func calculate_error_region(error_range: Dictionary) -> Rect2:
	var scroll_offset := Vector2(scroll_horizontal, scroll_vertical * _row_height)
	var start := (
		Vector2(
			error_range.start.character * _font_size,
			error_range.start.line * _row_height - _line_spacing
		)
		+ _offset - scroll_offset
	)
	start.x = max(_offset.x, start.x)
	start.y = max(0, start.y)
	
	var size := (
		Vector2(error_range.end.character * _font_size, (error_range.end.line + 1) * _row_height)
		- start
		+ _offset - scroll_offset
	)
	size.x = min(size.x, rect_size.x - _offset.x - _stylebox.content_margin_right)
	return Rect2(start, size)


func set_errors(value: Array) -> void:
	errors = value
	update_overlays(0)


func _enhance_syntax_highlighting() -> void:
	add_color_region('"', '"', quotes_color)
	add_color_region("'", "'", quotes_color)
	for c in ClassDB.get_class_list():
		add_keyword_color(c, class_color)
		for m in ClassDB.class_get_property_list(c):
			for key in m:
				add_keyword_color(key, member_color)

	var file := File.new()
	file.open(keyword_data_path, file.READ)
	var keywords: Dictionary = parse_json(file.get_as_text())
	file.close()
	for k in keywords["list"]:
		add_keyword_color(k, keyword_color)
