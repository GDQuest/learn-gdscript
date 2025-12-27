@tool
class_name RunnableCodeExample
extends HBoxContainer

signal scene_instance_set
signal code_updated

const ConsoleArrowAnimationScene := preload("res://ui/components/ConsoleArrowAnimation.tscn")
const CodeExampleVariableUnderlineScene := preload("res://ui/components/CodeExampleVariableUnderline.tscn")

const ERROR_NO_RUN_FUNCTION := "Scene %s doesn't have a run() function. The Run button won't work."
const HSLIDER_GRABBER_HIGHLIGHT: StyleBoxFlat = preload("res://ui/theme/hslider_grabber_highlight.tres")

# Godot 4 Exports and Setters
@export var scene: PackedScene: set = set_scene
@export_multiline var gdscript_code := "": set = set_code
@export var center_in_frame := true: set = set_center_in_frame
@export var run_button_label := "": set = set_run_button_label

var _scene_instance: CanvasItem: set = _set_scene_instance

@onready var _base_text_font_size: int = (preload("res://ui/theme/fonts/font_text.tres") as Font).get_font_size()

@onready var _gdscript_text_edit: CodeEdit = $GDScriptCode as CodeEdit
@onready var _run_button := $Frame/HBoxContainer/RunButton as Button
@onready var _step_button := $Frame/HBoxContainer/StepButton as Button
@onready var _reset_button := $Frame/HBoxContainer/ResetButton as Button
@onready var _frame_container := $Frame/PanelContainer as Control
@onready var _sliders := $Frame/Sliders as VBoxContainer
@onready var _buttons_container := $Frame/HBoxContainer as HBoxContainer

@onready var _debugger: RunnableCodeExampleDebugger
@onready var _console_arrow_animation: ConsoleArrowAnimation
var _monitored_variable_highlights: Array[Node] = []

# GDScriptFunctionState is REMOVED in Godot 4.
# This variable is kept as a Variant to avoid errors, but Step logic may need a rework.
@onready var _script_function_state: Variant 

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
	_gdscript_text_edit.add_color_region("[=", "]", CodeEditorEnhancer.COLOR_COMMENTS)

	_gdscript_text_edit.visible = not gdscript_code.is_empty()

	if not Engine.is_editor_hint() and not scene and get_child_count() > 2:
		var last_child: Node = get_child(get_child_count() - 1)
		var last_canvas: CanvasItem = last_child as CanvasItem
		if last_canvas and last_canvas != _gdscript_text_edit and last_canvas != _frame_container:
			remove_child(last_child)          
			_set_scene_instance(last_canvas) 

	# VisualServer -> RenderingServer
	var canvas_item := _buttons_container.get_canvas_item()
	RenderingServer.canvas_item_set_z_index(canvas_item, 10)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	if not scene:
		warnings.append("This node needs a scene to display.")
	elif _scene_instance and not _scene_instance.has_method("run"):
		warnings.append(ERROR_NO_RUN_FUNCTION % [_scene_instance.scene_file_path])
	return warnings


func run() -> void:
	if not _script_function_state:
		assert(_scene_instance.has_method("run"), "Node %s does not have a run method" % [get_path()])

		if _scene_instance.has_method("reset") and _debugger:
			_scene_instance.call("reset")

		# In Godot 4, we cannot resume an 'await' manually. 
		# If the code uses 'await', this call will just finish normally.
		var result = _scene_instance.call("run")
		
		if _scene_instance.has_method("wrap_inside_frame"):
			_scene_instance.call("wrap_inside_frame", _frame_container.get_rect())

	_gdscript_text_edit.highlight_current_line = false
	code_updated.emit()
	_clear_animated_arrows()


func step() -> void:
	# Note: Godot 4 does not support native stepping via resumes.
	# This logic is kept for syntax but relies on the tutorial's custom debugger.
	if not _script_function_state:
		assert(_scene_instance.has_method("run"), "Node %s does not have a run method" % [get_path()])

		if _scene_instance.has_method("reset") and _debugger:
			_scene_instance.call("reset")

		var state = _scene_instance.call("run")
		if _scene_instance.has_method("wrap_inside_frame"):
			_scene_instance.call("wrap_inside_frame", _frame_container.get_rect())
		
		# Manual stepping check (Concept only in GD4)
		if state is Signal: # Closest proxy if the function returns a signal to wait on
			_script_function_state = state
	
	code_updated.emit()


func reset() -> void:
	if _scene_instance and _scene_instance.has_method("reset"):
		_scene_instance.call("reset")
	_center_scene_instance()
	code_updated.emit()


func set_code(new_gdscript_code: String) -> void:
	gdscript_code = new_gdscript_code
	if not is_node_ready():
		await ready
	_gdscript_text_edit.text = new_gdscript_code


func set_scene(new_scene: PackedScene) -> void:
	scene = new_scene
	if not scene:
		return

	if not is_inside_tree():
		await ready

	if _scene_instance and is_instance_valid(_scene_instance):
		_scene_instance.queue_free()

	if scene:
		_set_scene_instance(scene.instantiate())


func set_center_in_frame(value: bool) -> void:
	center_in_frame = value
	_center_scene_instance()


func set_run_button_label(new_text: String) -> void:
	run_button_label = new_text
	if not is_inside_tree():
		await ready

	if not run_button_label.is_empty():
		_run_button.text = run_button_label


func create_slider_for(
	property_name: String, min_value := 0.0, max_value := 100.0, step_val := 1.0, color := Color.BLACK
) -> HSlider:
	if not _scene_instance:
		await scene_instance_set
	
	var box := HBoxContainer.new()
	var label := Label.new()
	var value_label := Label.new()
	var slider := HSlider.new()
	var property_value = _scene_instance.get(property_name)

	_sliders.add_child(box)
	box.add_child(label)
	box.add_child(slider)
	box.add_child(value_label)

	label.text = property_name.capitalize()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.value = property_value
	slider.step = step_val
	slider.custom_minimum_size.x = 100.0
	slider.value_changed.connect(_set_instance_value.bind(property_name, value_label))
	_set_instance_value(property_value, property_name, value_label)

	if color != Color.BLACK:
		var style: StyleBoxFlat = HSLIDER_GRABBER_HIGHLIGHT.duplicate()
		style.bg_color = color
		label.add_theme_color_override("font_color", color)
		value_label.add_theme_color_override("font_color", color)
		slider.add_theme_stylebox_override("grabber_area", style)
		slider.add_theme_stylebox_override("grabber_area_highlight", style)

	return slider


func _set_instance_value(value: Variant, property_name: String, value_label: Label) -> void:
	var f := float(value)
	_scene_instance.set(property_name, f)
	value_label.text = str(f)


func _center_scene_instance() -> void:
	if not center_in_frame or not _scene_instance:
		return
	if _scene_instance is Node2D:
		var n2d := _scene_instance as Node2D
		n2d.position = _frame_container.size / 2


func _set_scene_instance(new_scene_instance: CanvasItem) -> void:
	if new_scene_instance.has_signal("line_highlight_requested"):
		new_scene_instance.connect("line_highlight_requested", _on_highlight_line)
	if new_scene_instance.has_signal("animate_arrow_requested"):
		new_scene_instance.connect("animate_arrow_requested", _on_arrow_animation)

	_scene_instance = new_scene_instance
	scene_instance_set.emit()
	_scene_instance.show_behind_parent = true
	_frame_container.add_child(_scene_instance)
	_center_scene_instance()

	await get_tree().process_frame

	if _scene_instance.has_method("get_code"):
		gdscript_code = _scene_instance.call("get_code", gdscript_code)
		set_code(gdscript_code)

	_reset_button.visible = _scene_instance.has_method("reset")
	_run_button.visible = _scene_instance.has_method("run")
	
	var script: Script = _scene_instance.get_script()
	if script == null:
		_step_button.hide()
	elif script is GDScript:
		var gs := script as GDScript
		_step_button.visible = gs.source_code.find("await") >= 0
	else:
		_step_button.hide()

	var debugger_found: RunnableCodeExampleDebugger = null
	for node in get_parent().get_children():
		if node is RunnableCodeExampleDebugger:
			_debugger = node
			_debugger.setup(self, _scene_instance)
			if _scene_instance.has_signal("code_updated"):
				_scene_instance.code_updated.connect(code_updated.emit)

	_reset_monitored_variable_highlights()


func _reset_monitored_variable_highlights() -> void:
	if not _debugger:
		return

	await get_tree().process_frame

	for monitored_variable in _monitored_variable_highlights:
		if is_instance_valid(monitored_variable):
			monitored_variable.queue_free()
	_monitored_variable_highlights.clear()

	if not _gdscript_text_edit.visible:
		return

	var h_scroll_bar: HScrollBar = _gdscript_text_edit.get_h_scroll_bar()
	if h_scroll_bar != null:
		if not h_scroll_bar.scrolling.is_connected(_on_HScrollBar_scrolling):
			h_scroll_bar.scrolling.connect(_on_HScrollBar_scrolling)

	var monitored_variables := _debugger.monitored_variables
	var offset := Vector2(_gdscript_text_edit.position.x, 0.0)

	for variable_name in monitored_variables:
		var last_line := 0
		var last_column := -1 

		while last_line >= 0:
			# TextEdit.search returns Vector2i(column, line) in Godot 4
			var result: Vector2i = _gdscript_text_edit.search(variable_name, 0, last_line, last_column + 1)

			if result.x == -1:
				last_line = -1
			else:
				last_line = result.y
				last_column = result.x

				var rect_i: Rect2i = _gdscript_text_edit.get_rect_at_line_column(last_line, last_column)
				var rect: Rect2 = Rect2(rect_i) # convert to float rect
				rect.position += offset
				rect.size.x = (rect.size.x * variable_name.length()) + 4

				var monitored_variable = CodeExampleVariableUnderlineScene.instantiate()
				add_child(monitored_variable)
				monitored_variable.highlight_rect = rect
				monitored_variable.highlight_line = last_line
				monitored_variable.highlight_column = last_column
				monitored_variable.variable_name = variable_name
				monitored_variable.setup(self, _scene_instance)
				_monitored_variable_highlights.append(monitored_variable)


func _on_HScrollBar_scrolling() -> void:
	var offset := Vector2(_gdscript_text_edit.position.x, 0.0)
	for monitored_variable in _monitored_variable_highlights:
		var rect_i: Rect2i = _gdscript_text_edit.get_rect_at_line_column(
			monitored_variable.highlight_line,
			monitored_variable.highlight_column
		)
		var rect: Rect2 = Rect2(rect_i)
		rect.position += offset
		rect.size.x = (rect.size.x * monitored_variable.variable_name.length()) + 4
		monitored_variable.highlight_rect = rect


func _on_highlight_line(line_number: int) -> void:
	await get_tree().process_frame
	_gdscript_text_edit.set_caret_line(line_number) # cursor_set_line -> set_caret_line


func _on_arrow_animation(chars1: Array, chars2: Array) -> void:
	await get_tree().process_frame

	if not _console_arrow_animation:
		_console_arrow_animation = ConsoleArrowAnimationScene.instantiate()
		add_child(_console_arrow_animation)

	var current_line := _gdscript_text_edit.get_caret_line()
	var offset := Vector2(_gdscript_text_edit.position.x + 2, 0)

	var c1_col := int(chars1[0])
	var c2_col := int(chars2[0])
	var c1_len := int(chars1[1])
	var c2_len := int(chars2[1])

	var rect1_i: Rect2i = _gdscript_text_edit.get_rect_at_line_column(current_line, c1_col)
	var rect2_i: Rect2i = _gdscript_text_edit.get_rect_at_line_column(current_line, c2_col)

	var rect1: Rect2 = Rect2(rect1_i)
	var rect2: Rect2 = Rect2(rect2_i)

	rect1.position += offset
	rect2.position += offset
	rect1.size.x = (rect1.size.x * float(c1_len)) + 4.0
	rect2.size.x = (rect2.size.x * float(c2_len)) + 4.0

	_console_arrow_animation.highlight_rects = [rect1, rect2]
	_console_arrow_animation.initial_point = rect1.position + Vector2(rect1.size.x / 2.0, -5.0)
	_console_arrow_animation.end_point     = rect2.position + Vector2(rect2.size.x / 2.0, -5.0)
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
