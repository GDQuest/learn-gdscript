extends Control
tool

var _interface = null
var _utils = load('res://addons/gut/utils.gd').new()
var _hide_passing = true
var _font = null
var _font_size = null
var _root = null
var _max_icon_width = 10
var _editors = null # script_text_editor_controls.gd
var _show_orphans = true
var _output_control = null

const _col_1_bg_color = Color(0, 0, 0, .1)

var 	_icons = {
	red = load('res://addons/gut/images/red.png'),
	green = load('res://addons/gut/images/green.png'),
	yellow = load('res://addons/gut/images/yellow.png'),
}

signal search_for_text(text)

onready var _ctrls = {
	tree = $VBox/Output/Scroll/Tree,
	lbl_overlay = $VBox/Output/OverlayMessage,
	chk_hide_passing = $VBox/Toolbar/HidePassing,
	toolbar = {
		toolbar = $VBox/Toolbar,
		collapse = $VBox/Toolbar/Collapse,
		collapse_all = $VBox/Toolbar/CollapseAll,
		expand = $VBox/Toolbar/Expand,
		expand_all = $VBox/Toolbar/ExpandAll,
		hide_passing = $VBox/Toolbar/HidePassing,
		show_script = $VBox/Toolbar/ShowScript,
		scroll_output = $VBox/Toolbar/ScrollOutput
	}
}

func _test_running_setup():
	_hide_passing = true
	_show_orphans = true
	var _gut_config = load('res://addons/gut/gut_config.gd').new()
	_gut_config.load_panel_options('res://.gut_editor_config.json')
	set_font(
		_gut_config.options.panel_options.font_name,
		_gut_config.options.panel_options.font_size)

	_ctrls.toolbar.hide_passing.text = '[hp]'
	load_json_file('user://.gut_editor.json')


func _set_toolbutton_icon(btn, icon_name, text):
	if(Engine.editor_hint):
		btn.icon = get_icon(icon_name, 'EditorIcons')
	else:
		btn.text = str('[', text, ']')


func _ready():
	var f = $FontSampler.get_font("font")
	var s_size = f.get_string_size("000 of 000 passed")
	_root = _ctrls.tree.create_item()
	_ctrls.tree.set_hide_root(true)
	_ctrls.tree.columns = 2
	_ctrls.tree.set_column_expand(0, true)
	_ctrls.tree.set_column_expand(1, false)
	_ctrls.tree.set_column_min_width(1, s_size.x)

	_set_toolbutton_icon(_ctrls.toolbar.collapse, 'CollapseTree', 'c')
	_set_toolbutton_icon(_ctrls.toolbar.collapse_all, 'CollapseTree', 'c')
	_set_toolbutton_icon(_ctrls.toolbar.expand, 'ExpandTree', 'e')
	_set_toolbutton_icon(_ctrls.toolbar.expand_all, 'ExpandTree', 'e')
	_set_toolbutton_icon(_ctrls.toolbar.show_script, 'Script', 'ss')
	_set_toolbutton_icon(_ctrls.toolbar.scroll_output, 'Font', 'so')

	_ctrls.toolbar.hide_passing.set('custom_icons/checked', get_icon('GuiVisibilityHidden', 'EditorIcons'))
	_ctrls.toolbar.hide_passing.set('custom_icons/unchecked', get_icon('GuiVisibilityVisible', 'EditorIcons'))

	if(get_parent() == get_tree().root):
		_test_running_setup()

	call_deferred('_update_min_width')

func _update_min_width():
	rect_min_size.x = _ctrls.toolbar.toolbar.rect_size.x

func _open_file(path, line_number):
	if(_interface == null):
		print('Too soon, wait a bit and try again.')
		return

	var r = load(path)
	if(line_number != -1):
		_interface.edit_script(r, line_number)
	else:
		_interface.edit_script(r)

	if(_ctrls.toolbar.show_script.pressed):
		_interface.set_main_screen_editor('Script')


func _add_script_tree_item(script_path, script_json):
	var path_info = _get_path_and_inner_class_name_from_test_path(script_path)
	# print('* adding script ', path_info)
	var item_text = script_path
	var parent = _root

	if(path_info.inner_class != ''):
		parent = _find_script_item_with_path(path_info.path)
		item_text = path_info.inner_class
		if(parent == null):
			parent = _add_script_tree_item(path_info.path, {})

	var item = _ctrls.tree.create_item(parent)
	item.set_text(0, item_text)
	var meta = {
		"type":"script",
		"path":path_info.path,
		"inner_class":path_info.inner_class,
		"json":script_json}
	item.set_metadata(0, meta)
	item.set_custom_bg_color(1, _col_1_bg_color)

	return item


func _add_assert_item(text, icon, parent_item):
	# print('        * adding assert')
	var assert_item = _ctrls.tree.create_item(parent_item)
	assert_item.set_icon_max_width(0, _max_icon_width)
	assert_item.set_text(0, text)
	assert_item.set_metadata(0, {"type":"assert"})
	assert_item.set_icon(0, icon)
	assert_item.set_custom_bg_color(1, _col_1_bg_color)

	return assert_item


func _add_test_tree_item(test_name, test_json, script_item):
	# print('    * adding test ', test_name)
	var no_orphans_to_show = !_show_orphans or (_show_orphans and test_json.orphans == 0)
	if(_hide_passing and test_json['status'] == 'pass' and no_orphans_to_show):
		return

	var item = _ctrls.tree.create_item(script_item)
	var status = test_json['status']
	var meta = {"type":"test", "json":test_json}

	item.set_text(0, test_name)
	item.set_text(1, status)
	item.set_text_align(1, TreeItem.ALIGN_RIGHT)
	item.set_custom_bg_color(1, _col_1_bg_color)

	item.set_metadata(0, meta)
	item.set_icon_max_width(0, _max_icon_width)

	var orphan_text = 'orphans'
	if(test_json.orphans == 1):
		orphan_text = 'orphan'
	orphan_text = str(test_json.orphans, ' ', orphan_text)


	if(status == 'pass' and no_orphans_to_show):
		item.set_icon(0, _icons.green)
	elif(status == 'pass' and !no_orphans_to_show):
		item.set_icon(0, _icons.yellow)
		item.set_text(1, orphan_text)
	elif(status == 'fail'):
		item.set_icon(0, _icons.red)
	else:
		item.set_icon(0, _icons.yellow)

	if(!_hide_passing):
		for passing in test_json.passing:
			_add_assert_item('pass: ' + passing, _icons.green, item)

	for failure in test_json.failing:
		_add_assert_item("fail:  " + failure.replace("\n", ''), _icons.red, item)

	for pending in test_json.pending:
		_add_assert_item("pending:  " + pending.replace("\n", ''), _icons.yellow, item)

	if(status != 'pass' and !no_orphans_to_show):
		_add_assert_item(orphan_text, _icons.yellow, item)

	return item


func _load_result_tree(j):
	var scripts = j['test_scripts']['scripts']
	var script_keys = scripts.keys()
	# if we made it here, the json is valid and we did something, otherwise the
	# 'nothing to see here' should be visible.
	clear_centered_text()

	var _last_script_item = null
	for key in script_keys:
		var tests = scripts[key]['tests']
		var test_keys = tests.keys()
		var s_item = _add_script_tree_item(key, scripts[key])
		var bad_count = 0

		for test_key in test_keys:
			var t_item = _add_test_tree_item(test_key, tests[test_key], s_item)
			if(tests[test_key].status != 'pass'):
				bad_count += 1
			elif(t_item != null):
				t_item.collapsed = true

		# get_children returns the first child or null.  its a dumb name.
		if(s_item.get_children() == null):
			# var m = s_item.get_metadata(0)
			# print('!! Deleting ', m.path, ' ', m.inner_class)
			s_item.free()
		else:
			var total_text = str(test_keys.size(), ' passed')
			s_item.set_text_align(1, s_item.ALIGN_LEFT)
			if(bad_count == 0):
				s_item.collapsed = true
			else:
				total_text = str(test_keys.size() - bad_count, ' of ', test_keys.size(), ' passed')
			s_item.set_text(1, total_text)

	_free_childless_scripts()
	_show_all_passed()


func _free_childless_scripts():
	var item = _root.get_children()
	while(item != null):
		var next_item = item.get_next()
		if(item.get_children() == null):
			item.free()
		item = next_item


func _find_script_item_with_path(path):
	var item = _root.get_children()
	var to_return = null

	while(item != null and to_return == null):
		if(item.get_metadata(0).path == path):
			to_return = item
		else:
			item = item.get_next()

	return to_return


func _get_line_number_from_assert_msg(msg):
	var line = -1
	if(msg.find('at line') > 0):
		line = int(msg.split("at line")[-1].split(" ")[-1])
	return line


func _get_path_and_inner_class_name_from_test_path(path):
	var to_return = {
		path = '',
		inner_class = ''
	}

	to_return.path = path
	if !path.ends_with('.gd'):
		var loc = path.find('.gd')
		to_return.inner_class = path.split('.')[-1]
		to_return.path = path.substr(0, loc + 3)
	return to_return


func _handle_tree_item_select(item, force_scroll):
	var item_type = item.get_metadata(0).type

	var path = '';
	var line = -1;
	var method_name = ''
	var inner_class = ''

	if(item_type == 'test'):
		var s_item = item.get_parent()
		path = s_item.get_metadata(0)['path']
		inner_class = s_item.get_metadata(0)['inner_class']
		line = -1
		method_name = item.get_text(0)
	elif(item_type == 'assert'):
		var s_item = item.get_parent().get_parent()
		path = s_item.get_metadata(0)['path']
		inner_class = s_item.get_metadata(0)['inner_class']

		line = _get_line_number_from_assert_msg(item.get_text(0))
		method_name = item.get_parent().get_text(0)
	elif(item_type == 'script'):
		path = item.get_metadata(0)['path']
		if(item.get_parent() != _root):
			inner_class = item.get_text(0)
		line = -1
		method_name = ''
	else:
		return

	var path_info = _get_path_and_inner_class_name_from_test_path(path)
	if(force_scroll or _ctrls.toolbar.show_script.pressed):
		_goto_code(path, line, method_name, inner_class)
	if(force_scroll or _ctrls.toolbar.scroll_output.pressed):
		_goto_output(path, method_name, inner_class)


# starts at beginning of text edit and searches for each search term, moving
# through the text as it goes; ensuring that, when done, it found the first
# occurance of the last srting that happend after the first occurance of
# each string before it.  (Generic way of searching for a method name in an
# inner class that may have be a duplicate of a method name in a different
# inner class)
func _get_line_number_for_seq_search(search_strings, te):
#	var te = _editors.get_current_text_edit()
	var result = null
	var to_return = -1
	var start_line = 0
	var start_col = 0
	var s_flags = 0

	var i = 0
	var string_found = true
	while(i < search_strings.size() and string_found):
		result = te.search(search_strings[i], s_flags, start_line, start_col)
		if(result.size() > 0):
			start_line = result[TextEdit.SEARCH_RESULT_LINE]
			start_col = result[TextEdit.SEARCH_RESULT_COLUMN]
			to_return = start_line
		else:
			string_found = false
		i += 1

	return to_return


func _goto_code(path, line, method_name='', inner_class =''):
	if(_interface == null):
		print('going to ', [path, line, method_name, inner_class])
		return

	_open_file(path, line)
	if(line == -1):
		var search_strings = []
		if(inner_class != ''):
			search_strings.append(inner_class)

		if(method_name != ''):
			search_strings.append(method_name)

		line = _get_line_number_for_seq_search(search_strings, _editors.get_current_text_edit())
		if(line != -1):
			_interface.get_script_editor().goto_line(line)


func _goto_output(path, method_name, inner_class):
	if(_output_control == null):
		return

	var search_strings = [path]

	if(inner_class != ''):
		search_strings.append(inner_class)

	if(method_name != ''):
		search_strings.append(method_name)

	var line = _get_line_number_for_seq_search(search_strings, _output_control.get_rich_text_edit())
	if(line != -1):
		_output_control.scroll_to_line(line)


func _show_all_passed():
	if(_root.get_children() == null):
		add_centered_text('Everything passed!')


func _set_collapsed_on_all(item, value):
	if(item == _root):
		var node = _root.get_children()
		while(node != null):
			node.call_recursive('set_collapsed', value)
			node = node.get_next()
	else:
		item.call_recursive('set_collapsed', value)

# --------------
# Events
# --------------
func _on_Tree_item_selected():
	# do not force scroll
	var item = _ctrls.tree.get_selected()
	_handle_tree_item_select(item, false)
	# it just looks better if the left is always selected.
	if(item.is_selected(1)):
		item.deselect(1)
		item.select(0)


func _on_Tree_item_activated():
	# force scroll
	print('double clicked')
	_handle_tree_item_select(_ctrls.tree.get_selected(), true)

func _on_Collapse_pressed():
	collapse_selected()


func _on_Expand_pressed():
	expand_selected()


func _on_CollapseAll_pressed():
	collapse_all()


func _on_ExpandAll_pressed():
	expand_all()


func _on_Hide_Passing_pressed():
	_hide_passing = _ctrls.toolbar.hide_passing.pressed

# --------------
# Public
# --------------
func load_json_file(path):
	var text = _utils.get_file_as_text(path)
	if(text != ''):
		var result = JSON.parse(text)
		if(result.error != OK):
			add_centered_text(str(path, " has invalid json in it \n",
				'Error ', result.error, "@", result.error_line, "\n",
				result.error_string))
			return

		load_json_results(result.result)
	else:
		add_centered_text(str(path, ' was empty or does not exist.'))


func load_json_results(j):
	clear()
	add_centered_text('Nothing Here')
	_load_result_tree(j)


func add_centered_text(t):
	_ctrls.lbl_overlay.text = t


func clear_centered_text():
	_ctrls.lbl_overlay.text = ''


func clear():
	_ctrls.tree.clear()
	_root = _ctrls.tree.create_item()
	clear_centered_text()


func set_interface(which):
	_interface = which


func set_script_text_editors(value):
	_editors = value


func collapse_all():
	_set_collapsed_on_all(_root, true)


func expand_all():
	_set_collapsed_on_all(_root, false)


func collapse_selected():
	var item = _ctrls.tree.get_selected()
	if(item != null):
		_set_collapsed_on_all(item, true)

func expand_selected():
	var item = _ctrls.tree.get_selected()
	if(item != null):
		_set_collapsed_on_all(item, false)


func set_show_orphans(should):
	_show_orphans = should


func set_font(font_name, size):
	pass
#	var dyn_font = DynamicFont.new()
#	var font_data = DynamicFontData.new()
#	font_data.font_path = 'res://addons/gut/fonts/' + font_name + '-Regular.ttf'
#	font_data.antialiased = true
#	dyn_font.font_data = font_data
#
#	_font = dyn_font
#	_font.size = size
#	_font_size = size


func set_output_control(value):
	_output_control = value
