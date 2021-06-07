tool
extends TextEdit

const ErrorOverlay := preload("ErrorOverlay.tscn")

const COLOR_CLASS := Color(0.6, 0.6, 1.0)
const COLOR_MEMBER := Color(0.6, 1.0, 0.6)
const COLOR_KEYWORD := Color(1.0, 0.6, 0.6)
const COLOR_QUOTES := Color(1.0, 1.0, 0.6)
const COLOR_COMMENTS := Color("#80ccced3")

export var disallow_line_returns := false

export var lines_from := 1
export var lines_to := 0
export var rows_offset := 0

var _text_before := ""
var _text_after := ""
var _text_middle := PoolStringArray()
var _original_text := ""

export (String, FILE, "*.json") var keyword_data_path := "res://slide/widgets/text_edit/keywords.json"

## Stores errors
var errors := [] setget set_errors

var _character_width: float = theme.default_font.get_char_size(ord("0")).x
var _line_spacing := theme.get_constant("line_spacing", "TextEdit")
var _row_height := get_theme().default_font.get_height() + _line_spacing
# The horizontal 30 px corresponds to the left gutter with line numbers. Found in the source code.
var _stylebox: StyleBox = theme.get_stylebox("normal", "TextEdit")
# We need to recalculate this when the line count changes, as the number of lines 
# affects line count display in the gutter.
var _offset: Vector2

var _hscrollbar: HScrollBar
var _vscrollbar: VScrollBar

onready var _error_panel: Control = $ErrorFloatingPanel
## Keeps track of overlays to free them without risking destroying other TextEdit child nodes.
onready var _overlays: Control = $Overlays


func _ready() -> void:
	if Engine.editor_hint:
		return
	_enhance_syntax_highlighting()
	connect("text_changed", self, "_on_text_changed")
	for child in get_children():
		if child is VScrollBar:
			_vscrollbar = child
		elif child is HScrollBar:
			_hscrollbar = child

	_hscrollbar.connect("value_changed", self, "update_overlays")
	_vscrollbar.connect("value_changed", self, "update_overlays")

	_offset = _calculate_offset()


#	set_errors(
#		[
#			{
#				message = "Test error",
#				range = {start = {character = 0, line = 4}, end = {character = 40, line = 4}}
#			},
#			{
#				message = "Test error",
#				range = {start = {character = 0, line = 20}, end = {character = 40, line = 20}}
#			},
#		]
#	)


func update_overlays() -> void:
	for overlay in _overlays.get_children():
		overlay.queue_free()

	for error in errors:
		var is_outside_lens: bool = (
			(lines_from > 0 and error.range.start.line < lines_from)
			or (lines_to > 0 and error.range.start.line > lines_to)
		)
		if is_outside_lens:
			continue

		var overlay: Control = ErrorOverlay.instance()
		var region := calculate_error_region(error.range)

		overlay.rect_position = region.position
		overlay.rect_size = region.size

		_overlays.add_child(overlay)
		
		var panel_position := region.position + Vector2(0, _row_height) + rect_global_position
		overlay.connect("mouse_entered", _error_panel, "display", [error.message, panel_position])
		overlay.connect("mouse_exited", _error_panel, "hide")



func calculate_error_region(error_range: Dictionary) -> Rect2:
	var scroll_offset := Vector2(scroll_horizontal, scroll_vertical * _row_height)
	var start := (
		Vector2(
			error_range.start.character * _character_width,
			(error_range.start.line - lines_from - 1) * _row_height
		)
		+ _offset
		- scroll_offset
	)
	start.x = max(_offset.x, start.x)
	start.y = max(0, start.y)

	var size := Vector2(
		error_range.end.character * _character_width - start.x - scroll_offset.x, _row_height
	)
	size.x = min(size.x, rect_size.x - _offset.x - _stylebox.content_margin_right)
	return Rect2(start, size)


func set_errors(value: Array) -> void:
	errors = value
	update_overlays()


func _enhance_syntax_highlighting() -> void:
	add_color_region('"', '"', COLOR_QUOTES)
	add_color_region("'", "'", COLOR_QUOTES)
	add_color_region("#", "\n", COLOR_COMMENTS, true)
	for c in ClassDB.get_class_list():
		add_keyword_color(c, COLOR_CLASS)
		for m in ClassDB.class_get_property_list(c):
			for key in m:
				add_keyword_color(key, COLOR_MEMBER)

	var file := File.new()
	file.open(keyword_data_path, file.READ)
	var keywords: Dictionary = parse_json(file.get_as_text())
	file.close()
	for k in keywords["list"]:
		add_keyword_color(k, COLOR_KEYWORD)


func _calculate_offset() -> Vector2:
	var out := Vector2()
	var line_count := get_line_count()
	var line_numbers_width := 0
	while line_count != 0:
		line_numbers_width += 1
		line_count /= 10
	out.x = _character_width * line_numbers_width + _stylebox.content_margin_left
	out.y = _stylebox.content_margin_top
	return out


func _on_text_changed() -> void:
	if not disallow_line_returns:
		return
	var new_new_lines = text.count("\n")
	var old_new_lines = _original_text.count("\n")
	if new_new_lines != old_new_lines:
		var column = cursor_get_column()
		var line = cursor_get_line()
		text = _original_text
		cursor_set_column(column)
		cursor_set_line(line)
	else:
		_original_text = text


func _set(key: String, value) -> bool:
	if not Engine.is_editor_hint() and key == 'text':
		var _complete_text = value
		_text_before = ""
		_text_after = ""
		_text_middle = PoolStringArray()
		_complete_text = _complete_text.replace("\\r\\n", "\\n")
		if lines_from > 0 or rows_offset > 0:
			var _lines := Array(_complete_text.split("\n"))
			if lines_from > 0:
				var _start = lines_from - 1
				var _end = lines_to - 1 if lines_to > 0 else _lines.size()
				_text_before = PoolStringArray(_lines.slice(0, _start - 1)).join("\n")
				_text_after = PoolStringArray(_lines.slice(_end + 1, _lines.size())).join("\n")
				_lines = _lines.slice(_start, _end)
			if rows_offset > 0:
				for i in _lines.size():
					var line: String = _lines[i]
					var removed = line.substr(0, rows_offset)
					_text_middle.append(removed)
					_lines[i] = line.substr(rows_offset, -1)
			text = PoolStringArray(_lines).join("\n")
		else:
			text = _complete_text
		_original_text = text
	return true


func _get(key: String):
	if key == 'text':
		if Engine.is_editor_hint():
			return text
		text = text.rstrip("\n").lstrip("\n")
		if lines_from == 0 and rows_offset == 0:
			return text
		var _complete_text = _text_before + "\n"
		var _lines = text.split("\n")
		for i in _lines.size():
			if _text_middle.size() > i:
				_complete_text += _text_middle[i]
			_complete_text += _lines[i] + "\n"
		_complete_text += _text_after
		print(_complete_text)
		return _complete_text
