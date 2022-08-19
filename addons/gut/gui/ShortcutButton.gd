tool
extends Control


onready var _ctrls = {
	shortcut_label = $Layout/lblShortcut,
	set_button = $Layout/SetButton,
	save_button = $Layout/SaveButton,
	cancel_button = $Layout/CancelButton,
	clear_button = $Layout/ClearButton
}

signal changed
signal start_edit
signal end_edit

const NO_SHORTCUT = '<None>'

var _source_event = InputEventKey.new()
var _pre_edit_event = null
var _key_disp = NO_SHORTCUT

var _modifier_keys = [KEY_ALT, KEY_CONTROL, KEY_META, KEY_SHIFT]

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_unhandled_key_input(false)


func _display_shortcut():
	_ctrls.shortcut_label.text = to_s()


func _is_shift_only_modifier():
	return _source_event.shift and \
		!(_source_event.meta or _source_event.control or _source_event.alt)


func _has_modifier():
	return _source_event.alt or _source_event.control or _source_event.meta or _source_event.shift


func _is_modifier(scancode):
	return _modifier_keys.has(scancode)


func _edit_mode(should):
	set_process_unhandled_key_input(should)
	_ctrls.set_button.visible = !should
	_ctrls.save_button.visible = should
	_ctrls.save_button.disabled = should
	_ctrls.cancel_button.visible = should
	_ctrls.clear_button.visible = !should

	if(should and to_s() == ''):
		_ctrls.shortcut_label.text = 'press buttons'
	else:
		_ctrls.shortcut_label.text = to_s()

	if(should):
		emit_signal("start_edit")
	else:
		emit_signal("end_edit")

# ---------------
# Events
# ---------------
func _unhandled_key_input(event):
	if(event is InputEventKey):
		if(event.pressed):
			_source_event.alt = event.alt or event.scancode == KEY_ALT
			_source_event.control = event.control or event.scancode == KEY_CONTROL
			_source_event.meta = event.meta or event.scancode == KEY_META
			_source_event.shift = event.shift or event.scancode == KEY_SHIFT

			if(_has_modifier() and !_is_modifier(event.scancode)):
				_source_event.scancode = event.scancode
				_key_disp = OS.get_scancode_string(event.scancode)
			else:
#				_source_event.set_scancode = null
				_key_disp = NO_SHORTCUT
			_display_shortcut()
			_ctrls.save_button.disabled = !is_valid()


func _on_SetButton_pressed():
	_pre_edit_event = _source_event.duplicate(true)
	_edit_mode(true)


func _on_SaveButton_pressed():
	_edit_mode(false)
	_pre_edit_event = null
	emit_signal('changed')


func _on_CancelButton_pressed():
	_edit_mode(false)
	_source_event = _pre_edit_event
	_key_disp = OS.get_scancode_string(_source_event.scancode)
	if(_key_disp == ''):
		_key_disp = NO_SHORTCUT
	_display_shortcut()


func _on_ClearButton_pressed():
	clear_shortcut()

# ---------------
# Public
# ---------------
func to_s():
	var modifiers = []
	if(_source_event.alt):
		modifiers.append('alt')
	if(_source_event.control):
		modifiers.append('ctrl')
	if(_source_event.meta):
		modifiers.append('meta')
	if(_source_event.shift):
		modifiers.append('shift')

	if(_source_event.scancode != null):
		modifiers.append(_key_disp)

	var mod_text = ''
	for i in range(modifiers.size()):
		mod_text += modifiers[i]
		if(i != modifiers.size() - 1):
			mod_text += ' + '

	return mod_text


func is_valid():
	return _has_modifier() and _key_disp != NO_SHORTCUT and !_is_shift_only_modifier()


func get_shortcut():
	var to_return = ShortCut.new()
	to_return.shortcut = _source_event
	return to_return


func set_shortcut(sc):
	if(sc == null or sc.shortcut == null):
		clear_shortcut()
	else:
		_source_event = sc.shortcut
		_key_disp = OS.get_scancode_string(_source_event.scancode)
		_display_shortcut()


func clear_shortcut():
	_source_event = InputEventKey.new()
	_key_disp = NO_SHORTCUT
	_display_shortcut()


func disable_set(should):
	_ctrls.set_button.disabled = should

func disable_clear(should):
	_ctrls.clear_button.disabled = should
