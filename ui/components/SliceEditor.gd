# A code editor with a few conveniences:
#
# 1. Can show errors in an overlay, when given an array of
#    ScriptErrors
# 2. Dispatches a signal when scroll values change
# 3. If given a ScriptSlice instance, will synchronize the text state and the
#    ScriptSlice.current_text state
#
# NOTE: to position overlay errors correctly, the script relies on
# theme values, which are _not set_ by default. For this script to
# work properly, you _need_ to:
#
# 1. Set a theme
# 2. Make sure this theme has a font set
#
# The theme gets passed to the overlay at build time, so if you
# change the theme at runtime, make sure you also change the overlay's
# theme.
@tool
class_name SliceEditor
extends TextEdit

const ErrorOverlayPopupScene := preload("./popups/ErrorOverlayPopup.tscn")

signal scroll_changed(vector2)

enum SCROLL_DIR { HORIZONTAL, VERTICAL }

const BRACKET_PAIRS := {"(": ")", "[": "]", "{": "}"}

var errors_overlay := SliceEditorOverlay.new()
var errors_overlay_message: ErrorOverlayPopup = ErrorOverlayPopupScene.instantiate()

# Array<ScriptError>
var errors: Array = []:
	set(value):
		set_errors(value)

var _slice_properties: ScriptSlice = null
# Used to know when to add an indent level.
var _current_line := get_caret_line()
var _remove_last_character := false
# Used to automatically close brackets. As soon as you type a bracket, the
# selection gets erased, so we need to cache that info to wrap the selection in
# brackets.
var _last_typed_character := ""
var _last_selected_text := ""
var _last_selection_start := Vector2.ZERO
var _last_selection_end := Vector2.ZERO


func _ready() -> void:
	CodeEditorEnhancer.enhance(self)

	var scroll_offsets := Vector2.ZERO
	var found = 0
	for child in get_children():
		if found >= 2:
			break
		if child is VScrollBar:
			var vscrollbar: VScrollBar = child
			vscrollbar.value_changed.connect(func(v: float) -> void:
				_on_scrollbar_value_changed(v, SCROLL_DIR.VERTICAL)
			)
			scroll_offsets.x = vscrollbar.get_minimum_size().x

			found += 1
		elif child is HScrollBar:
			var hscrollbar: HScrollBar = child
			hscrollbar.value_changed.connect(func(v: float) -> void:
				_on_scrollbar_value_changed(v, SCROLL_DIR.HORIZONTAL)
			)
			scroll_offsets.y = hscrollbar.get_minimum_size().y

			found += 1

	errors_overlay.name = "ErrorsOverlay"
	errors_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	errors_overlay.offset_right = -scroll_offsets.x
	errors_overlay.offset_bottom = -scroll_offsets.y
	add_child(errors_overlay)

	add_child(errors_overlay_message)
	errors_overlay_message.top_level = true
	errors_overlay_message.hide()

	text_changed.connect(_on_text_changed)
	draw.connect(_update_overlays)

func _gui_input(event: InputEvent) -> void:
	# Shortcut uses Enter by default which adds a new line in TextEdit without any means to stop it.
	# So we remove it.
	if event.is_action_pressed("run_code"):
		_remove_last_character = true
	
	# Capture keyboard events if we are the focus owner, otherwise left arrow causes navigation events.
	if event is InputEventKey:
		var key_event := event as InputEventKey
		# In Godot 4, Control has focus checks directly.
		if has_focus():
			get_viewport().set_input_as_handled()

		if key_event.pressed:
			_last_typed_character = char(key_event.unicode) if key_event.unicode != 0 else ""

			_last_selected_text = get_selected_text()
			if not _last_selected_text.is_empty():
				_last_selection_start = Vector2(get_selection_from_line(), get_selection_from_column())
				_last_selection_end = Vector2(get_selection_to_line(), get_selection_to_column())


func setup(slice: ScriptSlice) -> void:
	_slice_properties = slice


func sync_text_with_slice() -> void:
	if not _slice_properties:
		return
	text = _slice_properties.slice_text
	_on_text_changed()


# Receives an array of `ScriptError`s
func set_errors(new_errors: Array) -> void:
	if OS.is_debug_build():
		for err in errors:
			assert(err is ScriptError, "Error %s isn't a valid ScriptError" % [err])
	errors = new_errors
	_reset_overlays()


func line_highlight_requested(line_index: int, at_char: int = 0) -> void:
	if line_index < 0 or line_index >= get_line_count():
		return
	if at_char < 0:
		at_char = 0

	set_caret_line(line_index)
	set_caret_column(at_char)
	center_viewport_to_caret()

	errors_overlay.add_line_highlight(line_index)

func _on_text_changed() -> void:
	if _remove_last_character:
		var column := get_caret_column()
		undo()
		_remove_last_character = false
		set_caret_column(column)
		return

	if _slice_properties != null:
		_slice_properties.current_text = text

	# The underlying text was changed, the old errors are no longer valid then.
	errors_overlay.clean()
	errors_overlay_message.hide()

	# Insert extra indents when entering new code block
	var previous_line := _current_line
	_current_line = get_caret_line()
	if _current_line > previous_line and not text.ends_with("\t") and text.rstrip("\t").ends_with(":\n"):
		var column := get_caret_column()
		text += "\t"
		set_caret_line(_current_line)
		set_caret_column(column + 1)
	
	# Automatically close brackets.
	if _last_typed_character in BRACKET_PAIRS:
		var closing_bracket: String = BRACKET_PAIRS[_last_typed_character]

		if _last_selected_text:
			undo()
			set_caret_line(int(_last_selection_start.x))
			set_caret_column(int(_last_selection_start.y))

			insert_text_at_caret(_last_typed_character)

			set_caret_line(int(_last_selection_end.x))
			set_caret_column(int(_last_selection_end.y) + 1)

		insert_text_at_caret(closing_bracket)

		if _last_selected_text.is_empty():
			set_caret_column(get_caret_column() - 1)

		_last_selected_text = ""
		_last_typed_character = ""

	# Pass over a closing bracket if writing a matching character
	elif _last_typed_character in BRACKET_PAIRS.values():
		var line: int = get_caret_line()
		var column: int = get_caret_column()
		select(line, column, line, column + 1)
		var character: String = get_selected_text()
		deselect()
		if character == _last_typed_character:
			# We simulate pressing backspace to remove the last typed character.
			var event := InputEventKey.new()
			event.keycode = KEY_BACKSPACE
			event.pressed = true
			Input.parse_input_event(event)
			set_caret_column(get_caret_column() + 1)


func _on_scrollbar_value_changed(value: float, direction: int) -> void:
	var vec2 = Vector2(0, value) if direction == SCROLL_DIR.VERTICAL else Vector2(value, 0)
	scroll_changed.emit(vec2)



# Recreates the overlays at the correct position after the underlying data has
# changed. Only call this when there is something new to display. Call
# _update_overlays() if you only want to update the visuals of existing overlays.
func _reset_overlays() -> void:
	errors_overlay.clean()
	errors_overlay_message.hide()

	var slice_properties := _slice_properties
	if slice_properties == null:
		return

	var show_lines_from = slice_properties.get_start_offset()
	var show_lines_to = slice_properties.get_end_offset()

	errors_overlay.lines_offset = slice_properties.get_start_offset()
	errors_overlay.character_offset = slice_properties.leading_spaces

	for index in range(errors.size()):
		var error: ScriptError = errors[index]

		var is_outside_lens: bool = (
			(show_lines_from > 0 and error.error_range.start.line < show_lines_from)
			or (show_lines_to > 0 and error.error_range.start.line > show_lines_to)
		)
		if is_outside_lens:
			continue

		var error_node := errors_overlay.add_error(error)
		if not error_node:
			continue

		error_node.region_entered.connect(func(reference_position: Vector2) -> void:
			errors_overlay_message.show_message(reference_position, error.code, error.message, error_node)
		)
		error_node.region_exited.connect(func() -> void:
			errors_overlay_message.hide_message(error_node)
		)

# Updates the position of existing overlays to align with the text edit after it updates.
# As such, it is called on the `draw` signal. This method should be fast enough to do that.
# But if it is not, more precise connections must be made to specific signals to update
# less often.
func _update_overlays() -> void:
	errors_overlay.update_overlays()
