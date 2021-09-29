tool
extends TextEdit

const ScriptSlice := preload("./collection/ScriptSlice.gd")
const CodeEditorEnhancer := preload("./CodeEditorEnhancer.gd")
const SliceEditorOverlay := preload("./SliceEditorOverlay.gd")
const SliceEditorErrorOverlayMessageScene := preload("./SliceEditorErrorOverlayMessage.tscn")
const SliceEditorErrorOverlayMessage := preload("./SliceEditorErrorOverlayMessage.gd")
const LanguageServerError := preload("./LanguageServerError.gd")

enum SCROLL_DIR {
	HORIZONTAL,
	VERTICAL
}

signal scroll_changed(vector)

var errors_overlay := SliceEditorOverlay.new()
var errors_overlay_message: SliceEditorErrorOverlayMessage = SliceEditorErrorOverlayMessageScene.instance()

var script_slice: ScriptSlice setget set_script_slice, get_script_slice
var errors := [] setget set_errors

func _ready() -> void:
	CodeEditorEnhancer.enhance(self)
	var found = 0
	for child in get_children():
		if found >= 2:
			break
		if child is VScrollBar:
			var vscrollbar: VScrollBar = child
			vscrollbar.connect("value_changed", self, "_on_scrollbar_value_changed", [SCROLL_DIR.VERTICAL])
			found += 1
		elif child is HScrollBar:
			var hscrollbar: HScrollBar = child
			hscrollbar.connect("value_changed", self, "_on_scrollbar_value_changed", [SCROLL_DIR.HORIZONTAL])
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
	update_overlays()


func update_overlays() -> void:
	errors_overlay.clean()

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
		
		squiggly.connect("mouse_entered", errors_overlay_message, "display", [error.message, panel_position])
		squiggly.connect("mouse_exited", errors_overlay_message, "hide")


func set_errors(new_errors: Array) -> void:
	errors = new_errors
	update_overlays()

func set_script_slice(new_script_slice: ScriptSlice) -> void:
	script_slice = new_script_slice
	text = script_slice.current_text


func get_script_slice() -> ScriptSlice:
	return script_slice


func _on_text_changed() -> void:
	script_slice.current_text = text
