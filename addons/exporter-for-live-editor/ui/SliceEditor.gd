# A code editor with a few conveniences:
#
# 1. Can show errors in an overlay, when given an array of
#    LanguageServerErrors
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
extends TextEdit

const ScriptSlice := preload("../collections/ScriptSlice.gd")
const CodeEditorEnhancer := preload("../utils/CodeEditorEnhancer.gd")
const SliceEditorOverlay := preload("./SliceEditorOverlay.gd")
const SliceEditorErrorOverlayMessageScene := preload("./SliceEditorErrorOverlayMessage.tscn")
const SliceEditorErrorOverlayMessage := preload("./SliceEditorErrorOverlayMessage.gd")
const LanguageServerError := preload("../lsp/LanguageServerError.gd")

enum SCROLL_DIR { HORIZONTAL, VERTICAL }

signal scroll_changed(vector2)

var errors_overlay := SliceEditorOverlay.new()
var errors_overlay_message: SliceEditorErrorOverlayMessage = SliceEditorErrorOverlayMessageScene.instance()

var script_slice: ScriptSlice setget set_script_slice, get_script_slice
# Array<LanguageServerError>
var errors := [] setget set_errors


func _ready() -> void:
	CodeEditorEnhancer.enhance(self)
	var found = 0
	for child in get_children():
		if found >= 2:
			break
		if child is VScrollBar:
			var vscrollbar: VScrollBar = child
			vscrollbar.connect(
				"value_changed", self, "_on_scrollbar_value_changed", [SCROLL_DIR.VERTICAL]
			)
			found += 1
		elif child is HScrollBar:
			var hscrollbar: HScrollBar = child
			hscrollbar.connect(
				"value_changed", self, "_on_scrollbar_value_changed", [SCROLL_DIR.HORIZONTAL]
			)
			found += 1
	errors_overlay.theme = theme
	add_child(errors_overlay)
	add_child(errors_overlay_message)
	connect("text_changed", self, "_on_text_changed")


func _get_configuration_warning() -> String:
	if not theme:
		return "Without a theme set, slice editor will misbehave"
	if not theme.default_font:
		return "Theme is required to have a default font set"
	return ""


func _on_scrollbar_value_changed(value: float, direction: int) -> void:
	var vec2 = Vector2(0, value) if direction == SCROLL_DIR.VERTICAL else Vector2(value, 0)
	emit_signal("scroll_changed", vec2)
	_update_overlays()


func sync_text_with_slice() -> void:
	if not script_slice:
		return
	text = script_slice.current_text

# Creates and positions error overlays at the right position.
# Call after:
#
# 1. Changing errors
# 2. Scroll/Resize
func _update_overlays() -> void:
	errors_overlay.clean()

	if script_slice == null:
		return

	var show_lines_from = script_slice.start_offset
	var show_lines_to = script_slice.end_offset
	var scroll_offset := errors_overlay.calculate_scroll_offset(self)
	var offset = errors_overlay.calculate_offset(self)

	for index in errors.size():
		var error: LanguageServerError = errors[index]

		var is_outside_lens: bool = (
			(show_lines_from > 0 and error.error_range.start.line < show_lines_from)
			or (show_lines_to > 0 and error.error_range.start.line > show_lines_to)
		)
		if is_outside_lens:
			continue

		var squiggly := errors_overlay.add_error(error, offset, scroll_offset)

		var panel_position := squiggly.panel_position

		squiggly.connect(
			"mouse_entered", errors_overlay_message, "display", [error.message, panel_position]
		)
		squiggly.connect("mouse_exited", errors_overlay_message, "hide")


# Receives an array of `LanguageServerError`s
func set_errors(new_errors: Array) -> void:
	if OS.is_debug_build():
		for err in errors:
			assert(err is LanguageServerError, "Error %s isn't a valid LanguageServerError" % [err])
	errors = new_errors
	_update_overlays()


func set_script_slice(new_script_slice: ScriptSlice) -> void:
	script_slice = new_script_slice
	text = ""


func get_script_slice() -> ScriptSlice:
	return script_slice


func _on_text_changed() -> void:
	if script_slice != null:
		script_slice.current_text = text
