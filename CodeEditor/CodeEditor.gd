# Code editor in which the user types GDScript. Supports limiting the code
# displayed and adding overlays.
tool
extends TextEdit

const ErrorOverlay := preload("ErrorOverlay.tscn")

const TAB_WIDTH := 4

const COLOR_CLASS := Color(0.6, 0.6, 1.0)
const COLOR_MEMBER := Color(0.6, 1.0, 0.6)
const COLOR_KEYWORD := Color(1.0, 0.6, 0.6)
const COLOR_QUOTES := Color(1.0, 1.0, 0.6)
const COLOR_COMMENTS := Color("#80ccced3")

export var disallow_line_returns := false

export var show_lines_from := 1
export var show_lines_to := 0
export var edit_lines_from := 1
export var edit_lines_to := 0
export var rows_offset := 0

export(String, FILE, "*.json") var keyword_data_path := "res://slide/widgets/text_edit/keywords.json"

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

var _text_before := ""
var _text_after := ""
var _text_middle := PoolStringArray()
var _original_text := ""

var _temporary_column_number := 0
var _temporary_line_number := 0

var _hscrollbar: HScrollBar
var _vscrollbar: VScrollBar

onready var _error_panel: Control = $ErrorFloatingPanel
# Keeps track of overlays to free them without risking destroying other TextEdit child nodes.
onready var _overlays: Control = $Overlays


func _ready() -> void:
	print(_character_width)
	if Engine.editor_hint:
		return
	_enhance_syntax_highlighting()
	connect("text_changed", self, "_on_text_changed")
	for child in get_children():
		if child is VScrollBar:
			_vscrollbar = child
		elif child is HScrollBar:
			_hscrollbar = child

	_hscrollbar.connect("value_changed", self, "_on_scrollbar_changed")
	_vscrollbar.connect("value_changed", self, "_on_scrollbar_changed")

	_offset = _calculate_offset()


# Draws overlays for each error message received from the language server.
func update_overlays() -> void:
	for overlay in _overlays.get_children():
		overlay.queue_free()

	for error in errors:
		var is_outside_lens: bool = (
			(show_lines_from > 0 and error.range.start.line < show_lines_from)
			or (show_lines_to > 0 and error.range.start.line > show_lines_to)
		)
		if is_outside_lens:
			continue

		var overlay: Control = ErrorOverlay.instance()
		var region := _calculate_error_region(error.range)

		overlay.rect_position = region.position
		overlay.rect_size = region.size

		_overlays.add_child(overlay)

		var panel_position := region.position + Vector2(0, _row_height) + rect_global_position
		overlay.connect("mouse_entered", _error_panel, "display", [error.message, panel_position])
		overlay.connect("mouse_exited", _error_panel, "hide")


func set_errors(value: Array) -> void:
	errors = value
	update_overlays()


func is_editable_area_restricted() -> bool:
	return (
		edit_lines_from > 1
		or (edit_lines_to > edit_lines_from and edit_lines_to < get_line_count())
	)


# Verifies the passed line number is within the range of editable lines.
func is_line_editable(line_number: int) -> bool:
	print(line_number)
	return line_number >= edit_lines_from and line_number <= edit_lines_to


func _store_current_cursor_position():
	_temporary_line_number = cursor_get_line()
	var line = get_line(_temporary_line_number)
	# Tabs are already counted once in the character count, so we multiply
	# them by TAB_WIDTH - 1.
	var tabs = line.count("\t") * (TAB_WIDTH - 1)
	_temporary_column_number = cursor_get_column() + tabs


func _restore_current_cursor_position():
	prints(_temporary_line_number, ":", _temporary_column_number)
	cursor_set_column(_temporary_column_number - 1)
	cursor_set_line(_temporary_line_number)


func _restore_previous_text_version():
	_store_current_cursor_position()
	text = _original_text
	_restore_current_cursor_position()


# Returns the pixel region to place an error overlay as a Rect2.
func _calculate_error_region(error_range: Dictionary) -> Rect2:
	var scroll_offset := Vector2(scroll_horizontal, scroll_vertical * _row_height)
	var start := (
		Vector2(
			error_range.start.character * _character_width,
			(error_range.start.line - show_lines_from - 1) * _row_height
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


func _on_scrollbar_changed(_value):
	update_overlays()


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
	var new_new_lines = text.count("\n")
	var old_new_lines = _original_text.count("\n")
	if new_new_lines != old_new_lines:
		# New line entered
		if disallow_line_returns:
			# Disable new line, and restore previous text and cursor position
			_restore_previous_text_version()
		else:
			if is_editable_area_restricted():
				# Change the edit area to allow for the additional line
				if new_new_lines > old_new_lines:
					edit_lines_to += 1
				else:
					edit_lines_to -= 1
			# Update the text value
			_original_text = text
	else:
		# Anything but a new line
		if not is_editable_area_restricted():
			# Allow all changes
			_original_text = text
			return

		var current_line = 1
		for index in text.length():
			var character: String = text[index]
			var previous_character: String = _original_text[index]
			if character == "\n":
				current_line += 1
			elif character != previous_character:
				# found the change
				if is_line_editable(current_line):
					_original_text = text
				else:
					_restore_previous_text_version()
				return


func _set(key: String, value) -> bool:
	if not Engine.is_editor_hint() and key == "text":
		var complete_text: String = value
		_text_before = ""
		_text_after = ""
		_text_middle = PoolStringArray()

		complete_text = complete_text.replace("\\r\\n", "\\n")
		if show_lines_from > 1 or rows_offset > 0:
			var lines := Array(complete_text.split("\n"))
			if show_lines_from > 1:
				var start := show_lines_from - 1
				var end := show_lines_to - 1 if show_lines_to > 0 else lines.size()
				_text_before = PoolStringArray(lines.slice(0, start - 1)).join("\n")
				_text_after = PoolStringArray(lines.slice(end + 1, lines.size())).join("\n")
				lines = lines.slice(start, end)
			if rows_offset > 0:
				for i in lines.size():
					var line: String = lines[i]
					var removed := line.substr(0, rows_offset)
					_text_middle.append(removed)
					lines[i] = line.substr(rows_offset, -1)
			text = PoolStringArray(lines).join("\n")
		else:
			text = complete_text
		_original_text = text
	return true


func _get(key: String):
	if key == "text":
		if Engine.is_editor_hint():
			return text

		text = text.rstrip("\n").lstrip("\n")
		if show_lines_from == 0 and rows_offset == 0:
			return text

		var complete_text := _text_before + "\n"
		var lines := text.split("\n")
		for i in lines.size():
			if _text_middle.size() > i:
				complete_text += _text_middle[i]
			complete_text += lines[i] + "\n"
		complete_text += _text_after
		return complete_text


# Adds syntax highlighting for quotes, comments, and many keywords and built-in
# symbols.
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
