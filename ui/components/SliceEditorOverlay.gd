class_name SliceEditorOverlay
extends Control

const ErrorRange = ScriptError.ErrorRange

var lines_offset := 0 setget set_lines_offset
var character_offset := 0 setget set_character_offset


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	var mm = event as InputEventMouseMotion
	if mm:
		var point = get_local_mouse_position()
		for overlay in get_children():
			var error_overlay = overlay as ErrorOverlay
			if is_instance_valid(error_overlay) and error_overlay.try_consume_mouse(point):
				return


func set_lines_offset(value: int) -> void:
	lines_offset = value
	update_overlays()


func set_character_offset(value: int) -> void:
	character_offset = value
	update_overlays()


func clean() -> void:
	for overlay in get_children():
		overlay.queue_free()


func update_overlays() -> void:
	var text_edit := get_parent() as TextEdit
	if not text_edit:
		return

	for overlay in get_children():
		var error_overlay = overlay as ErrorOverlay
		if is_instance_valid(error_overlay):
			error_overlay.regions = _get_error_range_regions(error_overlay.error_range, text_edit)
		
		var highlight_overlay = overlay as HighlightOverlay
		if is_instance_valid(highlight_overlay):
			highlight_overlay.regions = _get_line_regions(highlight_overlay.line_index, text_edit)


func add_error(error: ScriptError) -> ErrorOverlay:
	var text_edit := get_parent() as TextEdit
	if not text_edit:
		return null

	var error_overlay := ErrorOverlay.new()
	error_overlay.severity = error.severity
	error_overlay.error_range = error.error_range
	error_overlay.regions = _get_error_range_regions(error.error_range, text_edit)
	add_child(error_overlay)

	return error_overlay


func _get_error_range_regions(error_range: ErrorRange, text_edit: TextEdit) -> Array:
	var start_line := error_range.start.line - lines_offset
	var end_line = error_range.end.line - lines_offset
	var start_char = error_range.start.character - character_offset
	var end_char = error_range.end.character - character_offset
	
	return _get_text_range_regions(start_line, start_char, end_line, end_char, text_edit)


func add_line_highlight(line_index: int) -> void:
	var text_edit := get_parent() as TextEdit
	if not text_edit:
		return

	var highlight_overlay := HighlightOverlay.new()
	highlight_overlay.line_index = line_index
	highlight_overlay.regions = _get_line_regions(line_index, text_edit)
	add_child(highlight_overlay)


func _get_line_regions(line_index: int, text_edit: TextEdit) -> Array:
	var line = text_edit.get_line(line_index)
	var end_character = line.length() - 1 
	
	return _get_text_range_regions(line_index, 0, line_index, end_character, text_edit)


func _get_text_range_regions(
	start_line: int, start_char: int, end_line: int, end_char: int, text_edit: TextEdit
) -> Array:
	var regions := []
	var line_count := text_edit.get_line_count()

	# Iterate through the lines of the error range and find the regions for each character
	# span in the line, accounting for line wrapping.
	var line_index = start_line
	while line_index <= end_line:
		if line_index < 0 or line_index >= line_count:
			line_index += 1
			continue

		var line = text_edit.get_line(line_index)
		var region := Rect2(-1, -1, 0, 0)

		# Starting point of the first line is as reported by the error. For the following
		# lines it's the first character in the line.
		var first_char: int
		if line_index == start_line:
			first_char = start_char
		else:
			first_char = 0

		# Ending point of the last line is as reported by the error. For the preceding
		# lines it's the last character in the line.
		var last_char: int
		if line_index == end_line:
			last_char = end_char
		else:
			last_char = line.length()

		# Iterate through the characters to find those which are visible in the TextEdit.
		# This also handles wrapping, as characters report different vertical offset when
		# that happens.
		var char_index := first_char
		while char_index <= last_char:
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
				# We could've just accumulated the size, but not all the characters report their
				# correct sizes, namely tabs. This works for every case except when such character
				# is the last one in the line. But that's not a big deal, since it's just whitespace.
				region.size.x = (char_rect.position.x - region.position.x) + char_rect.size.x

			char_index += 1

		# In case we somehow didn't fill a single region with characters.
		if not region.position.x == -1:
			regions.append(region)
		line_index += 1

	return regions


class ErrorOverlay:
	extends Control
	enum Severity { ERROR = 1, WARNING, INFO, HINT }

	const COLOR_ERROR := Color("#E83482")
	const COLOR_WARNING := Color("#D2C84F")
	const COLOR_INFO := Color("#79F2D6")

	signal region_entered(reference_position)
	signal region_exited

	var severity := 0
	var error_range := ErrorRange.new()
	var regions := [] setget set_regions

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
			var reference_position = _lines[i].rect_global_position
			emit_signal("region_entered", reference_position)
		elif not _hovered_region == -1 and region_has_point == -1:
			emit_signal("region_exited")
		else:
			emit_signal("region_exited")

			var reference_position = _lines[i].rect_global_position
			emit_signal("region_entered", reference_position)

		_hovered_region = region_has_point
		return true

	func set_regions(error_regions: Array) -> void:
		for underline in _lines:
			underline = underline as ErrorUnderline
			if not underline or not is_instance_valid(underline):
				continue
			remove_child(underline)
			underline.queue_free()

		_lines = []
		regions = []

		for error_region in error_regions:
			var underline := ErrorUnderline.new()

			match severity:
				Severity.ERROR:
					underline.line_type = ErrorUnderline.LineType.JAGGED
					underline.line_color = COLOR_ERROR
				Severity.WARNING:
					underline.line_type = ErrorUnderline.LineType.SQUIGGLY
					underline.line_color = COLOR_WARNING
				_:
					underline.line_type = ErrorUnderline.LineType.DASHED
					underline.line_color = COLOR_INFO

			underline.rect_position = Vector2(error_region.position.x, error_region.end.y)
			underline.line_length = error_region.size.x

			add_child(underline)
			_lines.append(underline)
			regions.append(error_region)


class ErrorUnderline:
	extends Control
	enum LineType { SQUIGGLY, JAGGED, DASHED }

	const LINE_THICKNESS := 2.0

	const SQUIGGLY_HEIGHT := 3.0
	const SQUIGGLY_STEP_WIDTH := 20.0
	const SQUIGGLY_VERTEX_COUNT := 16

	const JAGGED_HEIGHT := 5.0
	const JAGGED_STEP_WIDTH := 12.0

	const DASHED_STEP_WIDTH := 14.0
	const DASHED_GAP := 8.0

	var line_length := 64.0 setget set_line_length
	var line_type := -1 setget set_line_type
	var line_color := Color.white setget set_line_color

	var _points: PoolVector2Array

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if line_type == LineType.DASHED:
			# draw_multiline doesn't support thickness, so we have to do this manually.
			var i := 0
			while i < _points.size() - 1:
				draw_line(_points[i], _points[i + 1], line_color, LINE_THICKNESS, true)
				i += 2
		else:
			draw_polyline(_points, line_color, LINE_THICKNESS, true)

	func update_points() -> void:
		_points = PoolVector2Array()

		match line_type:
			LineType.SQUIGGLY:
				for i in SQUIGGLY_VERTEX_COUNT * line_length / SQUIGGLY_STEP_WIDTH:
					_points.append(
						Vector2(
							SQUIGGLY_STEP_WIDTH * i / SQUIGGLY_VERTEX_COUNT,
							SQUIGGLY_HEIGHT / 2.0 * sin(TAU * i / SQUIGGLY_VERTEX_COUNT)
						)
					)

			LineType.JAGGED:
				for i in line_length / JAGGED_STEP_WIDTH:
					_points.append(Vector2(JAGGED_STEP_WIDTH * i, 0.0))
					_points.append(
						Vector2(
							JAGGED_STEP_WIDTH * i + JAGGED_STEP_WIDTH / 4.0, -JAGGED_HEIGHT / 2.0
						)
					)
					_points.append(
						Vector2(
							JAGGED_STEP_WIDTH * i + JAGGED_STEP_WIDTH * 3.0 / 4.0,
							JAGGED_HEIGHT / 2.0
						)
					)

			LineType.DASHED:
				for i in line_length / (DASHED_STEP_WIDTH + DASHED_GAP):
					_points.append(Vector2((DASHED_STEP_WIDTH + DASHED_GAP) * i, 0.0))

					var end_x = (DASHED_STEP_WIDTH + DASHED_GAP) * (i + 1) - DASHED_GAP
					if end_x > line_length:
						end_x = line_length
					_points.append(Vector2(end_x, 0.0))

			_:
				_points.append(Vector2(0.0, 0.0))
				_points.append(Vector2(line_length, 0.0))

	func set_line_length(value: float) -> void:
		line_length = value
		update_points()
		update()

	func set_line_type(value: int) -> void:
		line_type = value
		update_points()
		update()

	func set_line_color(value: Color) -> void:
		line_color = value
		update()


class HighlightOverlay:
	extends Control
	
	const DEFAULT_ALPHA := 0.16
	const DISSOLVE_DURATION := 1.5
	
	var line_index := -1
	var regions := [] setget set_regions

	var _current_alpha := 0.0
	var _tweener: Tween

	func _init() -> void:
		name = "HighlightOverlay"
		rect_min_size = Vector2(0, 0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		_current_alpha = DEFAULT_ALPHA
		_tweener = Tween.new()
		add_child(_tweener)

	func _ready() -> void:
		set_anchors_and_margins_preset(Control.PRESET_WIDE)
		
		_tweener.connect("tween_all_completed", self, "queue_free")
		
		_tweener.interpolate_method(self, "_dissolve_step", DEFAULT_ALPHA, 0.0, DISSOLVE_DURATION)
		_tweener.start()
	
	
	func _draw() -> void:
		for region in regions:
			draw_rect(region, Color(1, 1, 1, _current_alpha), true)
	
	
	func _dissolve_step(value: float) -> void:
		_current_alpha = value
		update()
	
	
	func set_regions(hl_regions: Array) -> void:
		regions = hl_regions
		update()
