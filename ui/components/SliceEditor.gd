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
tool
class_name SliceEditor
extends TextEdit

const ErrorOverlayPopupScene := preload("./popups/ErrorOverlayPopup.tscn")

enum SCROLL_DIR { HORIZONTAL, VERTICAL }

signal scroll_changed(vector2)

var errors_overlay := SliceEditorOverlay.new()
var errors_overlay_message: ErrorOverlayPopup = ErrorOverlayPopupScene.instance()

# Array<ScriptError>
var errors := [] setget set_errors

var _slice_properties: SliceProperties
# Used to know when to add an indent level.
var _current_line := cursor_get_line()
var _remove_last_character := false


func _ready() -> void:
	CodeEditorEnhancer.enhance(self)

	var scroll_offsets := Vector2.ZERO
	var found = 0
	for child in get_children():
		if found >= 2:
			break
		if child is VScrollBar:
			var vscrollbar: VScrollBar = child
			vscrollbar.connect(
				"value_changed", self, "_on_scrollbar_value_changed", [SCROLL_DIR.VERTICAL]
			)
			scroll_offsets.x = vscrollbar.get_minimum_size().x

			found += 1
		elif child is HScrollBar:
			var hscrollbar: HScrollBar = child
			hscrollbar.connect(
				"value_changed", self, "_on_scrollbar_value_changed", [SCROLL_DIR.HORIZONTAL]
			)
			scroll_offsets.y = hscrollbar.get_minimum_size().y

			found += 1

	errors_overlay.name = "ErrorsOverlay"
	errors_overlay.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	errors_overlay.margin_right = -scroll_offsets.x
	errors_overlay.margin_bottom = -scroll_offsets.y
	add_child(errors_overlay)

	add_child(errors_overlay_message)
	errors_overlay_message.set_as_toplevel(true)
	errors_overlay_message.hide()

	connect("text_changed", self, "_on_text_changed")
	connect("draw", self, "_update_overlays")


func _gui_input(event: InputEvent) -> void:
	# Shortcut uses Enter by default which adds a new line in TextEdit without any means to stop it.
	# So we remove it.
	if event.is_action_pressed("run_code"):
		_remove_last_character = true
	
	# Capture keyboard events if we are the focus owner, otherwise left arrow causes navigation events.
	if event is InputEventKey and get_focus_owner() == self:
		get_tree().set_input_as_handled()


func setup(slice_properties: SliceProperties) -> void:
	_slice_properties = slice_properties


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


func highlight_line(line_index: int, at_char: int = 0) -> void:
	if line_index < 0 or line_index >= get_line_count():
		return
	if at_char < 0:
		at_char = 0

	cursor_set_line(line_index, false)
	cursor_set_column(at_char)
	center_viewport_to_cursor()

	errors_overlay.add_line_highlight(line_index)


func _on_text_changed() -> void:
	if _remove_last_character:
		var column := cursor_get_column()
		undo()
		_remove_last_character = false
		cursor_set_column(column)
		return

	if _slice_properties != null:
		_slice_properties.current_text = text

	# The underlying text was changed, the old errors are no longer valid then.
	errors_overlay.clean()
	errors_overlay_message.hide()

	# Insert extra indents when entering new code block
	var previous_line := _current_line
	_current_line = cursor_get_line()
	if _current_line > previous_line and not text.ends_with("\t") and text.rstrip("\t").ends_with(":\n"):
		var column := cursor_get_column()
		text += "\t"
		cursor_set_line(_current_line)
		cursor_set_column(column + 1)


func _on_scrollbar_value_changed(value: float, direction: int) -> void:
	var vec2 = Vector2(0, value) if direction == SCROLL_DIR.VERTICAL else Vector2(value, 0)
	emit_signal("scroll_changed", vec2)


# Recreates the overlays at the correct position after the underlying data has
# changed. Only call this when there is something new to display. Call
# _update_overlays() if you only want to update the visuals of existing overlays.
func _reset_overlays() -> void:
	errors_overlay.clean()
	errors_overlay_message.hide()

	var slice_properties := _slice_properties
	if slice_properties == null:
		return

	var show_lines_from = slice_properties.start_offset
	var show_lines_to = slice_properties.end_offset

	errors_overlay.lines_offset = slice_properties.start_offset
	errors_overlay.character_offset = slice_properties.leading_spaces

	for index in errors.size():
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

		error_node.connect(
			"region_entered",
			errors_overlay_message,
			"show_message",
			[error.code, error.message, error_node]
		)
		error_node.connect("region_exited", errors_overlay_message, "hide_message", [error_node])


# Updates the position of existing overlays to align with the text edit after it updates.
# As such, it is called on the `draw` signal. This method should be fast enough to do that.
# But if it is not, more precise connections must be made to specific signals to update
# less often.
func _update_overlays() -> void:
	errors_overlay.update_overlays()
