extends VBoxContainer
tool

class SearchResults:
	const L = TextEdit.SEARCH_RESULT_LINE
	const C = TextEdit.SEARCH_RESULT_COLUMN

	var positions = []
	var te = null
	var _last_term = ''

	func _search_te(text, start_position, flags=0):
		var start_pos = start_position
		if(start_pos[L] < 0 or start_pos[L] > te.get_line_count()):
			start_pos[L] = 0
		if(start_pos[C] < 0):
			start_pos[L] = 0

		var result = te.search(text, flags, start_pos[L], start_pos[C])
		if(result.size() == 2 and result[L] == start_position[L] and
			result[C] == start_position[C] and text == _last_term):
			if(flags == TextEdit.SEARCH_BACKWARDS):
				result[C] -= 1
			else:
				result[C] += 1
			result = _search_te(text, result, flags)
		elif(result.size() == 2):
			te.scroll_vertical = result[L]
			te.select(result[L], result[C], result[L], result[C] + text.length())
			te.cursor_set_column(result[C])
			te.cursor_set_line(result[L])
			te.center_viewport_to_cursor()

		_last_term = text
		te.center_viewport_to_cursor()
		return result

	func _cursor_to_pos():
		var to_return = [0, 0]
		to_return[L] = te.cursor_get_line()
		to_return[C] = te.cursor_get_column()
		return to_return

	func find_next(term):
		return _search_te(term, _cursor_to_pos())

	func find_prev(term):
		var new_pos = _search_te(term, _cursor_to_pos(), TextEdit.SEARCH_BACKWARDS)
		return new_pos

	func get_next_pos():
		pass

	func get_prev_pos():
		pass

	func clear():
		pass

	func find_all(text):
		var c_pos = [0, 0]
		var found = true
		var last_pos = [0, 0]
		positions.clear()

		while(found):
			c_pos = te.search(text, 0, c_pos[L], c_pos[C])

			if(c_pos.size() > 0 and
				(c_pos[L] > last_pos[L] or
					(c_pos[L] == last_pos[L] and c_pos[C] > last_pos[C]))):
				positions.append([c_pos[L], c_pos[C]])
				c_pos[C] += 1
				last_pos = c_pos
			else:
				found = false



onready var _ctrls = {
	output = $Output,

	copy_button = $Toolbar/CopyButton,
	use_colors = $Toolbar/UseColors,
	clear_button = $Toolbar/ClearButton,
	word_wrap = $Toolbar/WordWrap,
	show_search = $Toolbar/ShowSearch,

	search_bar = {
		bar = $Search,
		search_term = $Search/SearchTerm,
	}
}
var _sr = SearchResults.new()

func _test_running_setup():
	_ctrls.use_colors.text = 'use colors'
	_ctrls.show_search.text = 'search'
	_ctrls.word_wrap.text = 'ww'

	set_all_fonts("CourierPrime")
	set_font_size(20)

	load_file('user://.gut_editor.bbcode')


func _ready():
	_sr.te = _ctrls.output
	_ctrls.use_colors.icon = get_icon('RichTextEffect', 'EditorIcons')
	_ctrls.show_search.icon = get_icon('Search', 'EditorIcons')
	_ctrls.word_wrap.icon = get_icon('Loop', 'EditorIcons')

	_setup_colors()
	if(get_parent() == get_tree().root):
		_test_running_setup()


# ------------------
# Private
# ------------------
func _setup_colors():
	_ctrls.output.clear_colors()
	var keywords = [
		['Failed', Color.red],
		['Passed', Color.green],
		['Pending', Color.yellow],
		['Orphans', Color.yellow],
		['WARNING', Color.yellow],
		['ERROR', Color.red]
	]

	for keyword in keywords:
		_ctrls.output.add_keyword_color(keyword[0], keyword[1])

	var f_color = _ctrls.output.get_color("font_color")
	_ctrls.output.add_color_override("font_color_readonly", f_color)
	_ctrls.output.add_color_override("function_color", f_color)
	_ctrls.output.add_color_override("member_variable_color", f_color)
	_ctrls.output.update()


func _set_font(font_name, custom_name):
	var rtl = _ctrls.output
	if(font_name == null):
		rtl.set('custom_fonts/' + custom_name, null)
	else:
		var dyn_font = DynamicFont.new()
		var font_data = DynamicFontData.new()
		font_data.font_path = 'res://addons/gut/fonts/' + font_name + '.ttf'
		font_data.antialiased = true
		dyn_font.font_data = font_data
		rtl.set('custom_fonts/' + custom_name, dyn_font)


# ------------------
# Events
# ------------------
func _on_CopyButton_pressed():
	copy_to_clipboard()


func _on_UseColors_pressed():
	_ctrls.output.syntax_highlighting = _ctrls.use_colors.pressed


func _on_ClearButton_pressed():
	clear()


func _on_ShowSearch_pressed():
	show_search(_ctrls.show_search.pressed)


func _on_SearchTerm_focus_entered():
	_ctrls.search_bar.search_term.call_deferred('select_all')

func _on_SearchNext_pressed():
	_sr.find_next(_ctrls.search_bar.search_term.text)


func _on_SearchPrev_pressed():
	_sr.find_prev(_ctrls.search_bar.search_term.text)


func _on_SearchTerm_text_changed(new_text):
	if(new_text == ''):
		_ctrls.output.deselect()
	else:
		_sr.find_next(new_text)


func _on_SearchTerm_text_entered(new_text):
	if(Input.is_physical_key_pressed(KEY_SHIFT)):
		_sr.find_prev(new_text)
	else:
		_sr.find_next(new_text)


func _on_SearchTerm_gui_input(event):
	if(event is InputEventKey and !event.pressed and event.scancode == KEY_ESCAPE):
		show_search(false)

func _on_WordWrap_pressed():
	_ctrls.output.wrap_enabled = _ctrls.word_wrap.pressed
	_ctrls.output.update()

# ------------------
# Public
# ------------------
func show_search(should):
	_ctrls.search_bar.bar.visible = should
	if(should):
		_ctrls.search_bar.search_term.grab_focus()
		_ctrls.search_bar.search_term.select_all()
	_ctrls.show_search.pressed = should


func search(text, start_pos, highlight=true):
	return _sr.find_next(text)


func copy_to_clipboard():
	var selected = _ctrls.output.get_selection_text()
	if(selected != ''):
		OS.clipboard = selected
	else:
		OS.clipboard = _ctrls.output.text


func clear():
	_ctrls.output.text = ''


func set_all_fonts(base_name):
	if(base_name == 'Default'):
		_set_font(null, 'font')
#		_set_font(null, 'normal_font')
#		_set_font(null, 'bold_font')
#		_set_font(null, 'italics_font')
#		_set_font(null, 'bold_italics_font')
	else:
		_set_font(base_name + '-Regular', 'font')
#		_set_font(base_name + '-Regular', 'normal_font')
#		_set_font(base_name + '-Bold', 'bold_font')
#		_set_font(base_name + '-Italic', 'italics_font')
#		_set_font(base_name + '-BoldItalic', 'bold_italics_font')


func set_font_size(new_size):
	var rtl = _ctrls.output
	if(rtl.get('custom_fonts/font') != null):
		rtl.get('custom_fonts/font').size = new_size
#		rtl.get('custom_fonts/bold_italics_font').size = new_size
#		rtl.get('custom_fonts/bold_font').size = new_size
#		rtl.get('custom_fonts/italics_font').size = new_size
#		rtl.get('custom_fonts/normal_font').size = new_size


func set_use_colors(value):
	pass


func get_use_colors():
	return false;


func get_rich_text_edit():
	return _ctrls.output


func load_file(path):
	var f = File.new()
	var result = f.open(path, f.READ)
	if(result != OK):
		return

	var t = f.get_as_text()
	f.close()
	_ctrls.output.text = t
	_ctrls.output.scroll_vertical = _ctrls.output.get_line_count()
	_ctrls.output.set_deferred('scroll_vertical', _ctrls.output.get_line_count())


func add_text(text):
	if(is_inside_tree()):
		_ctrls.output.text += text


func scroll_to_line(line):
	_ctrls.output.scroll_vertical = line
	_ctrls.output.cursor_set_line(line)
