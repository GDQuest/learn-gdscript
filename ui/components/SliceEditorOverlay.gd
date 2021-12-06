class_name SliceEditorOverlay
extends Control

const LanguageServerRange = LanguageServerError.ErrorRange


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	var mm = event as InputEventMouseMotion
	if mm:
		var point = get_local_mouse_position()
		for overlay in get_children():
			overlay = overlay as ErrorOverlay
			if not overlay or not is_instance_valid(overlay):
				continue
			
			if overlay.try_consume_mouse(point):
				return


func clean() -> void:
	for overlay in get_children():
		overlay.queue_free()


func add_error(error: LanguageServerError) -> ErrorOverlay:
	var text_edit := get_parent() as TextEdit
	if not text_edit:
		return null

	var error_overlay := ErrorOverlay.new()
	error_overlay.regions = _get_error_range_regions(error.error_range, text_edit)
	add_child(error_overlay)
	
	return error_overlay


func _get_error_range_regions(error_range: LanguageServerRange, text_edit: TextEdit) -> Array:
	var regions := []

	# Iterate through the lines of the error range and find the regions for each character
	# span in the line, accounting for line wrapping.
	var line_index := error_range.start.line
	while line_index <= error_range.end.line:
		var line = text_edit.get_line(line_index)
		var region := Rect2(-1, -1, 0, 0)

		# Starting point of the first line is as reported by the LSP. For the following
		# lines it's the first character in the line.
		var char_start : int
		if line_index == error_range.start.line:
			char_start = error_range.start.character
		else:
			char_start = 0

		# Ending point of the last line is as reported by the LSP. For the preceding
		# lines it's the last character in the line.
		var char_end : int
		if line_index == error_range.end.line:
			char_end = error_range.end.character
		else:
			char_end = line.length()

		# Iterate through the characters to find those which are visible in the TextEdit.
		# This also handles wrapping, as characters report different vertical offset when
		# that happens.
		var char_index := char_start
		while char_index <= char_end:
			var char_rect = text_edit.get_rect_at_line_column(line_index, char_index)
			if char_rect.position.x == -1 or char_rect.position.y == -1:
				char_index += 1
				continue

			# If region is empty (first in line), fill it with the first character's data.
			if region.position.x == -1:
				region.position = char_rect.position
				region.size = char_rect.size
			# If the region is on a different vertical offset than the next character, then
			# we hit a wrapping point; store the region and create a new one.
			elif not region.position.y == char_rect.position.y:
				regions.append(region)
				region = Rect2(char_rect.position, char_rect.size)
			# If nothing else, just extend the region horizontal with the size of the next
			# character.
			else:
				region.size.x += char_rect.size.x

			char_index += 1

		# In case we somehow didn't fill a single region with characters.
		if not region.position.x == -1:
			regions.append(region)
		line_index += 1

	return regions


class ErrorOverlay extends Control:
	signal region_entered(panel_position)
	signal region_exited

	var regions := [] setget set_regions
	var panel_position: Vector2

	var _lines := []
	var _hovered_region := -1


	func _init() -> void:
		name = "ErrorOverlay"
		rect_min_size = Vector2(0, 0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE


	func _ready() -> void:
		set_anchors_and_margins_preset(Control.PRESET_WIDE)


	func try_consume_mouse(point: Vector2) -> bool:
		var region_has_point := -1
		var i := 0
		for region_rect in regions:
			if region_rect.has_point(point):
				region_has_point = i
				break

			i += 1

		if _hovered_region == region_has_point:
			return false

		if _hovered_region == -1 and not region_has_point == -1:
			var panel_position = _lines[i].position
			emit_signal("region_entered", panel_position)
		elif not _hovered_region == -1 and region_has_point == -1:
			emit_signal("region_exited")
		else:
			emit_signal("region_exited")

			var panel_position = _lines[i].position
			emit_signal("region_entered", panel_position)

		_hovered_region = region_has_point
		return true


	func set_regions(error_regions: Array) -> void:
		for squiggly in _lines:
			squiggly = squiggly as SquigglyLine
			if not squiggly or not is_instance_valid(squiggly):
				continue
			remove_child(squiggly)
			squiggly.queue_free()

		_lines = []
		regions = []

		for error_region in error_regions:
			var squiggly := SquigglyLine.new()
			squiggly.position =	Vector2(error_region.position.x, error_region.end.y)
			squiggly.wave_width = error_region.size.x

			add_child(squiggly)
			_lines.append(squiggly)
			regions.append(error_region)


class SquigglyLine extends Line2D:
	const WAVE_STEP_WIDTH := 18.0
	const WAVE_HEIGHT := 4.0
	const LINE_THICKNESS := 2.0
	const VERTEX_COUNT := 16

	const COLOR_ERROR := Color("#d81946")
	const COLOR_WARNING := Color("#ffe478")

	var wave_width := 64.0 setget set_wave_width


	func update_drawing() -> void:
		points.empty()
		for i in VERTEX_COUNT * wave_width / WAVE_STEP_WIDTH:
			add_point(Vector2(
				WAVE_STEP_WIDTH * i / VERTEX_COUNT,
				WAVE_HEIGHT / 2.0 * sin(TAU * i / VERTEX_COUNT)
			))


	func set_wave_width(value: float) -> void:
		wave_width = value
		update_drawing()
