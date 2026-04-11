@tool
# Displays a scene with a GDScript code example. If the scene's root has a
# `run()` function, pressing the run button will call the function.
class_name RunnableCodeExample
extends HBoxContainer

signal scene_instance_set
signal code_updated

const ConsoleArrowAnimationScene := preload("res://ui/components/ConsoleArrowAnimation.tscn")
const CodeExampleVariableUnderlineScene := preload("res://ui/components/CodeExampleVariableUnderline.tscn")

const ERROR_NO_RUN_FUNCTION := "Scene %s doesn't have a run() function. The Run button won't work."
const ERROR_MULTIPLE_RUN_FUNCTION := "Scene %s has both run() and run_coroutine() functions. It must only have one. The Run button won't work."
const HSLIDER_GRABBER_HIGHLIGHT: StyleBoxFlat = preload("res://ui/theme/hslider_grabber_highlight.tres")

@export var _gdscript_text_edit: CodeEdit
@export var _run_button: Button
@export var _step_button: Button
@export var _reset_button: Button
@export var _frame_container: Control
@export var _sliders: VBoxContainer
@export var _buttons_container: HBoxContainer

@export var scene: PackedScene:
	set = set_scene
@export var center_in_frame := true:
	set = set_center_in_frame
@export var run_button_label := "":
	set = set_run_button_label
@export_multiline var gdscript_code := "":
	set = set_code

var _scene_instance: CanvasItem:
	set = _set_scene_instance

var _base_text_font_size := preload("res://ui/theme/fonts/font_text.tres").base_font.msdf_size
var _current_coroutine: CoroutineController = null

@onready var _debugger: RunnableCodeExampleDebugger
@onready var _console_arrow_animation: ConsoleArrowAnimation
@onready var _monitored_variable_highlights := []

@onready var _start_code_example_height := _gdscript_text_edit.size.y


func _ready() -> void:
	Events.font_size_scale_changed.connect(_on_Events_font_size_scale_changed)

	if not Engine.is_editor_hint():
		_update_gdscript_text_edit_width(UserProfiles.get_profile().font_size_scale)

	_run_button.pressed.connect(run)
	_step_button.pressed.connect(step)
	_reset_button.pressed.connect(reset)
	_frame_container.resized.connect(_center_scene_instance)

	CodeEditorEnhancer.enhance(_gdscript_text_edit)
	CodeEditorEnhancer.prevent_editable(_gdscript_text_edit)
	if not (_gdscript_text_edit.syntax_highlighter as CodeHighlighter).has_color_region("[="):
		(_gdscript_text_edit.syntax_highlighter as CodeHighlighter).add_color_region("[=", "]", CodeEditorEnhancer.COLOR_COMMENTS)

	_gdscript_text_edit.visible = not gdscript_code.is_empty()

	# If there's no scene but there's an instance as a child of
	# RunnableCodeExample, we use this as the scene instance.
	#
	# This simplifies the process of creating code examples.
	if not Engine.is_editor_hint() and not scene and get_child_count() > 1:
		var last_child := get_child(get_child_count() - 1)
		assert(last_child != _gdscript_text_edit and last_child != _frame_container)
		remove_child(last_child)
		_set_scene_instance(last_child as CanvasItem)

	# Godot doesn't allow changing Control nodes z-index in the inspector,
	# so a workaround with the VisualServer is needed
	var canvas_item := _buttons_container.get_canvas_item()
	RenderingServer.canvas_item_set_z_index(canvas_item, 10)


func _get_run_count(scene_instance: Node) -> int:
	var has_run := scene_instance.has_method("run")
	var has_run_coroutine := scene_instance.has_method("run_coroutine")
	if has_run and has_run_coroutine:
		return 2
	if has_run or has_run_coroutine:
		return 1
	return 0


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not scene and get_child_count() == 0:
		warnings.push_back("This node needs a scene to display.")
	elif _scene_instance and not _get_run_count(_scene_instance):
		warnings.push_back(ERROR_NO_RUN_FUNCTION % [_scene_instance.scene_file_path])
	elif _scene_instance and _get_run_count(_scene_instance) > 1:
		warnings.push_back(ERROR_MULTIPLE_RUN_FUNCTION % [_scene_instance.scene_file_path])
	return warnings


# Called when pressing the Run button. Calls the run() function of the example.
func run() -> void:
	assert(
		_get_run_count(_scene_instance) == 1,
		"Node %s does not have a run method or has both run and run_coroutine" % [get_path()],
	)
	var is_coroutine := _scene_instance.has_method("run_coroutine")
	if _scene_instance.has_method("reset") and _debugger and not _current_coroutine:
		@warning_ignore("unsafe_method_access")
		_scene_instance.reset()

	if not _current_coroutine:
		if is_coroutine:
			_current_coroutine = CoroutineController.new()
			_current_coroutine.finished.connect(_finish_coroutine)
			@warning_ignore("unsafe_method_access")
			_scene_instance.run_coroutine(_current_coroutine)
		else:
			@warning_ignore("unsafe_method_access")
			_scene_instance.run()
		if _scene_instance.has_method("wrap_inside_frame"):
			@warning_ignore("unsafe_method_access")
			_scene_instance.wrap_inside_frame(_frame_container.get_rect())
		if is_coroutine:
			while _current_coroutine:
				_current_coroutine.step_requested.emit()
			if _scene_instance.has_method("wrap_inside_frame"):
				@warning_ignore("unsafe_method_access")
				_scene_instance.wrap_inside_frame(_frame_container.get_rect())
	elif is_coroutine:
		while _current_coroutine:
			_current_coroutine.step_requested.emit()

	_gdscript_text_edit.highlight_current_line = false
	code_updated.emit()
	_clear_animated_arrows()


# Called when pressing the Step button. Available only on examples that contain
# calls to yield().
func step() -> void:
	assert(
		_get_run_count(_scene_instance) == 1,
		"Node %s does not have a run method or has both run and run_coroutine" % [get_path()],
	)
	var is_coroutine := _scene_instance.has_method("run_coroutine")
	if _scene_instance.has_method("reset") and _debugger and not _current_coroutine:
		@warning_ignore("unsafe_method_access")
		_scene_instance.reset()

	if not _current_coroutine:
		if is_coroutine:
			_current_coroutine = CoroutineController.new()
			_current_coroutine.finished.connect(_finish_coroutine)
			@warning_ignore("unsafe_method_access")
			_scene_instance.run_coroutine(_current_coroutine)
		else:
			@warning_ignore("unsafe_method_access")
			_scene_instance.run()
		if _scene_instance.has_method("wrap_inside_frame"):
			@warning_ignore("unsafe_method_access")
			_scene_instance.wrap_inside_frame(_frame_container.get_rect())
	elif is_coroutine:
		if _console_arrow_animation:
			_console_arrow_animation.highlight_rects = []
			_console_arrow_animation.reset_curve()
		_current_coroutine.step_requested.emit()
		if not _current_coroutine:
			_gdscript_text_edit.highlight_current_line = false
	emit_signal("code_updated")


func _finish_coroutine() -> void:
	_current_coroutine = null


func reset() -> void:
	# Finish running script if it's yielded
	if _current_coroutine:
		run()
	if _scene_instance.has_method("reset"):
		_scene_instance.call("reset")
	_center_scene_instance()
	emit_signal("code_updated")


func set_code(new_gdscript_code: String) -> void:
	gdscript_code = new_gdscript_code
	if not _gdscript_text_edit:
		await self.ready
	_gdscript_text_edit.text = new_gdscript_code


func set_scene(new_scene: PackedScene) -> void:
	scene = new_scene
	# Work around an issue where Godot considers the property got overriden in a
	# scene and calls the setter, freeing the _scene_instance.
	if not scene:
		return

	if not is_inside_tree():
		await self.ready

	if _scene_instance and is_instance_valid(_scene_instance):
		_scene_instance.queue_free()

	if scene:
		_set_scene_instance(scene.instantiate() as CanvasItem)


func set_center_in_frame(value: bool) -> void:
	center_in_frame = value
	_center_scene_instance()


func set_run_button_label(new_text: String) -> void:
	run_button_label = new_text
	if not is_inside_tree():
		await self.ready

	if not run_button_label.is_empty():
		_run_button.text = run_button_label


func create_slider_for(
		property_name: StringName,
		min_value := 0.0,
		max_value := 100.0,
		slider_step := 1.0,
		color := Color.BLACK,
) -> HSlider:
	if not _scene_instance:
		await self.scene_instance_set
	var box := HBoxContainer.new()
	var label := Label.new()
	var value_label := Label.new()
	var slider := HSlider.new()
	var property_value: float = _scene_instance.get(property_name)

	_sliders.add_child(box)
	box.add_child(label)
	box.add_child(slider)
	box.add_child(value_label)

	label.text = property_name.capitalize()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.value = property_value
	slider.step = slider_step
	slider.custom_minimum_size.x = 100.0
	slider.value_changed.connect(_set_instance_value.bind(property_name, value_label))
	_set_instance_value(property_value, property_name, value_label)

	if color != Color.BLACK:
		var hslider_grabber_highlight: StyleBoxFlat = HSLIDER_GRABBER_HIGHLIGHT.duplicate()
		hslider_grabber_highlight.bg_color = color

		label.add_theme_color_override("font_color", color)
		value_label.add_theme_color_override("font_color", color)
		slider.add_theme_stylebox_override("grabber_area", hslider_grabber_highlight)
		slider.add_theme_stylebox_override("grabber_area_highlight", hslider_grabber_highlight)

	return slider


# Using this proxy function is required as the value emitted by the signal
# will always be the first argument.
func _set_instance_value(value: float, property_name: String, value_label: Label) -> void:
	_scene_instance.set(property_name, value)
	value_label.text = str(value)


func _center_scene_instance() -> void:
	if not center_in_frame or not _scene_instance:
		return
	if _scene_instance is Node2D:
		(_scene_instance as Node2D).position = _frame_container.size / 2


func _set_scene_instance(new_scene_instance: CanvasItem) -> void:
	if new_scene_instance.has_signal("line_highlight_requested"):
		new_scene_instance.connect("line_highlight_requested", _on_highlight_line)
	if new_scene_instance.has_signal("animate_arrow_requested"):
		new_scene_instance.connect("animate_arrow_requested", _on_arrow_animation)

	_scene_instance = new_scene_instance
	emit_signal("scene_instance_set")
	_scene_instance.show_behind_parent = true
	_frame_container.add_child(_scene_instance)
	_center_scene_instance()

	# Skip a frame to allow all nodes to be ready.
	# Avoids overwriting text via yield(node, "ready").
	await get_tree().process_frame

	if _scene_instance.has_method("get_code"):
		@warning_ignore("unsafe_method_access")
		gdscript_code = _scene_instance.get_code(gdscript_code)
		set_code(gdscript_code)

	_reset_button.visible = _scene_instance.has_method("reset")
	_run_button.visible = _get_run_count(_scene_instance) == 1
	var script: RefCounted = _scene_instance.get_script()
	if script == null:
		_step_button.hide()
	else:
		_step_button.visible = _scene_instance.has_method("run_coroutine")

	if not _run_button.visible:
		printerr(ERROR_NO_RUN_FUNCTION % [_scene_instance.scene_file_path])

	# Setting up our fake debugger when it's there to allow executing the code line-by-line
	_debugger = null
	for node in get_parent().get_children():
		if node is RunnableCodeExampleDebugger:
			_debugger = node
			_debugger.setup(self, _scene_instance)
			if _scene_instance.has_signal("code_updated"):
				_scene_instance.connect("code_updated", code_updated.emit)

	_reset_monitored_variable_highlights()


func _reset_monitored_variable_highlights():
	if not _debugger:
		return

	# After changing font size, must wait a frame to create monitored variables
	await get_tree().process_frame

	for monitored_variable: Node in _monitored_variable_highlights:
		monitored_variable.queue_free()
	_monitored_variable_highlights.clear()

	if not _gdscript_text_edit.visible:
		return

	var h_scroll_bar: HScrollBar = null
	for current_child in _gdscript_text_edit.get_children():
		if current_child is HScrollBar:
			h_scroll_bar = current_child
			break
	if h_scroll_bar != null:
		h_scroll_bar.scrolling.connect(_on_HScrollBar_scrolling)

	# Create widgets that underline a variable and display a variable's value
	# when hovering with the mouse.
	var monitored_variables := _debugger.monitored_variables
	var offset := Vector2i(_gdscript_text_edit.position.x as int, 0)

	for variable_name: StringName in monitored_variables:
		var last_line := 0
		var last_column := -1 # Search offset to not repeat same result

		while last_line >= 0:
			var result := _gdscript_text_edit.search(variable_name, 0, last_line, last_column + 1)

			var is_result_in_line_before := false
			var is_result_in_column_before := false

			if result != Vector2i(-1, -1):
				is_result_in_line_before = result.y < last_line
				is_result_in_column_before = (
					result.x < last_column
					and result.y <= last_line
				)

			if result == Vector2i(-1, -1):
				last_line = -1
			elif is_result_in_line_before or is_result_in_column_before:
				last_line = -1
			else:
				last_line = result.y
				last_column = result.x

				var rect = _gdscript_text_edit.get_rect_at_line_column(last_line, last_column + 1)
				rect.position += offset
				rect.size.x = (rect.size.x * variable_name.length()) + 4

				var monitored_variable: CodeExampleVariableUnderline = CodeExampleVariableUnderlineScene.instantiate()
				add_child(monitored_variable)
				monitored_variable.highlight_rect = rect
				monitored_variable.highlight_line = last_line
				monitored_variable.highlight_column = last_column
				monitored_variable.variable_name = variable_name
				monitored_variable.setup(self, _scene_instance)
				_monitored_variable_highlights.append(monitored_variable)


func _on_HScrollBar_scrolling() -> void:
	# When scrolling horizontally, we need to recalculate the rectangle area in the code editor
	# for each monitored variable. The monitored variable draws an underline that spans the
	# variable it's highlighting, but when scrolling, this region changes, so we need to
	# recalculate and update the highlight_rect for each monitored variable.
	var offset := Vector2(_gdscript_text_edit.position.x, 0.0)

	for monitored_variable: CodeExampleVariableUnderline in _monitored_variable_highlights:
		var rect = _gdscript_text_edit.get_rect_at_line_column(
			monitored_variable.highlight_line,
			monitored_variable.highlight_column,
		)
		rect.position += offset
		rect.size.x = (rect.size.x * monitored_variable.variable_name.length()) + 4
		monitored_variable.highlight_rect = rect


func _on_highlight_line(line_number: int) -> void:
	# wait to see if script was interrupted
	await get_tree().process_frame

	if not _current_coroutine:
		return

	_gdscript_text_edit.highlight_current_line = true
	_gdscript_text_edit.set_caret_line(line_number)


func _on_arrow_animation(chars1: Array, chars2: Array) -> void:
	# wait to see if script was interrupted
	await get_tree().process_frame

	if not _current_coroutine:
		return

	if not _console_arrow_animation:
		_console_arrow_animation = ConsoleArrowAnimationScene.instantiate()
		add_child(_console_arrow_animation)

	var current_line := _gdscript_text_edit.get_caret_line()

	var offset := Vector2i.ZERO
	offset.x = floori(_gdscript_text_edit.position.x + 2)

	var rect1 := _gdscript_text_edit.get_rect_at_line_column(current_line, chars1[0] as int)
	var rect2 := _gdscript_text_edit.get_rect_at_line_column(current_line, chars2[0] as int)

	rect1.position += offset
	rect2.position += offset

	rect1.size.x = (rect1.size.x * chars1[1]) + 4
	rect2.size.x = (rect2.size.x * chars2[1]) + 4

	var rects := [rect1, rect2]

	_console_arrow_animation.highlight_rects = rects
	_console_arrow_animation.initial_point = rect1.position + Vector2i(floori(rect1.size.x / 2.0), -5)
	_console_arrow_animation.end_point = rect2.position + Vector2i(floori(rect2.size.x / 2.0), -5)
	_console_arrow_animation.draw_curve()


func _update_gdscript_text_edit_width(new_font_scale: int) -> void:
	var font_size_multiplier := (
		float(_base_text_font_size + new_font_scale * 2)
		/ _base_text_font_size
	)
	_gdscript_text_edit.custom_minimum_size.y = _start_code_example_height * font_size_multiplier


func _clear_animated_arrows() -> void:
	if _console_arrow_animation:
		_console_arrow_animation.highlight_rects = []
		_console_arrow_animation.reset_curve()


func _on_Events_font_size_scale_changed(new_font_scale: int) -> void:
	_clear_animated_arrows()
	_reset_monitored_variable_highlights()
	_update_gdscript_text_edit_width(new_font_scale)
