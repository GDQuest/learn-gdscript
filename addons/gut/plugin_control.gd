# ##############################################################################
#(G)odot (U)nit (T)est class
#
# ##############################################################################
# The MIT License (MIT)
# =====================
#
# Copyright (c) 2020 Tom "Butch" Wesley
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# ##############################################################################
# This is the control that is added via the editor.  It exposes GUT settings
# through the editor and delays the creation of the GUT instance until
# Engine.get_main_loop() works as expected.
# ##############################################################################
tool
extends Control

# ------------------------------------------------------------------------------
# GUT Settings
# ------------------------------------------------------------------------------
export(String, 'AnonymousPro', 'CourierPrime', 'LobsterTwo', 'Default') var _font_name = 'AnonymousPro'
export(int) var _font_size = 20
export(Color) var _font_color = Color(.8, .8, .8, 1)
export(Color) var _background_color = Color(.15, .15, .15, 1)
# Enable/Disable coloring of output.
export(bool) var _color_output = true
# The full/partial name of a script to select upon startup
export(String) var _select_script = ''
# The full/partial name of a test.  All tests that contain the string will be
# run
export(String) var _tests_like = ''
# The full/partial name of an Inner Class to be run.  All Inner Classes that
# contain the string will be run.
export(String) var _inner_class_name = ''
# Start running tests when the scene finishes loading
export var _run_on_load = false
# Maximize the GUT control on startup
export var _should_maximize = false
# Print output to the consol as well
export var _should_print_to_console = true
# Display orphan counts at the end of tests/scripts.
export var _show_orphans = true
# The log level.
export(int, 'Fail/Errors', 'Errors/Warnings/Test Names', 'Everything') var _log_level = 1
# When enabled GUT will yield between tests to give the GUI time to paint.
# Disabling this can make the program appear to hang and can have some
# unwanted consequences with the timing of freeing objects
export var _yield_between_tests = true
# When GUT compares values it first checks the types to prevent runtime errors.
# This behavior can be disabled if desired.  This flag was added early in
# development to prevent any breaking changes and will likely be removed in
# the future.
export var _disable_strict_datatype_checks = false
# The prefix used to find test scripts.
export var _file_prefix = 'test_'
# The suffix used to find test scripts.
export var _file_suffix = '.gd'
# The prefix used to find Inner Test Classes.
export var _inner_class_prefix = 'Test'
# The directory GUT will use to write any temporary files.  This isn't used
# much anymore since there was a change to the double creation implementation.
# This will be removed in a later release.
export(String) var _temp_directory = 'user://gut_temp_directory'
# The path and filename for exported test information.
export(String) var _export_path = ''
# When enabled, any directory added will also include its subdirectories when
# GUT looks for test scripts.
export var _include_subdirectories = false
# Allow user to add test directories via editor.  This is done with strings
# instead of an array because the interface for editing arrays is really
# cumbersome and complicates testing because arrays set through the editor
# apply to ALL instances.  This also allows the user to use the built in
# dialog to pick a directory.
export(String, DIR) var _directory1 = ''
export(String, DIR) var _directory2 = ''
export(String, DIR) var _directory3 = ''
export(String, DIR) var _directory4 = ''
export(String, DIR) var _directory5 = ''
export(String, DIR) var _directory6 = ''
# Must match the types in _utils for double strategy
export(int, 'FULL', 'PARTIAL') var _double_strategy = 1
# Path and filename to the script to run before all tests are run.
export(String, FILE) var _pre_run_script = ''
# Path and filename to the script to run after all tests are run.
export(String, FILE) var _post_run_script = ''
# Path to the file that gut will export results to in the junit xml format
export(String, FILE) var _junit_xml_file = ''
# Flag to include a timestamp in the filename of _junit_xml_file
export(bool) var _junit_xml_timestamp = false
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
# Emitted when all the tests have finished running.
signal tests_finished
# Emitted when GUT is ready to be interacted with, and before any tests are run.
signal gut_ready


# ------------------------------------------------------------------------------
# Private stuff.
# ------------------------------------------------------------------------------
var _gut = null
var _lgr = null
var _cancel_import = false
var _placeholder = null

func _init():
	# This min size has to be what the min size of the GutScene's min size is
	# but it has to be set here and not inferred i think.
	rect_min_size = Vector2(740, 250)

func _ready():
	# Must call this deferred so that there is enough time for
	# Engine.get_main_loop() is populated and the psuedo singleton utils.gd
	# can be setup correctly.
	if(Engine.editor_hint):
		_placeholder = load('res://addons/gut/GutScene.tscn').instance()
		call_deferred('add_child', _placeholder)
		_placeholder.rect_size = rect_size
	else:
		call_deferred('_setup_gut')

	connect('resized', self,  '_on_resized')

func _on_resized():
	if(_placeholder != null):
		_placeholder.rect_size = rect_size


# Templates can be missing if tests are exported and the export config for the
# project does not include '*.txt' files.  This check and related flags make
# sure GUT does not blow up and that the error is not lost in all the import
# output that is generated as well as ensuring that no tests are run.
#
# Assumption:  This is only a concern when running from the scene since you
# cannot run GUT from the command line in an exported game.
func _check_for_templates():
	var f = File.new()
	if(!f.file_exists('res://addons/gut/double_templates/function_template.txt')):
		_lgr.error('Templates are missing.  Make sure you are exporting "*.txt" or "addons/gut/double_templates/*.txt".')
		_run_on_load = false
		_cancel_import = true
		return false
	return true

func _setup_gut():
	var _utils = load('res://addons/gut/utils.gd').get_instance()

	_lgr = _utils.get_logger()
	_gut = load('res://addons/gut/gut.gd').new()
	_gut.connect('tests_finished', self, '_on_tests_finished')

	if(!_check_for_templates()):
		return

	_gut._select_script = _select_script
	_gut._tests_like = _tests_like
	_gut._inner_class_name = _inner_class_name

	_gut._file_prefix = _file_prefix
	_gut._inner_class_prefix = _inner_class_prefix
	_gut._temp_directory = _temp_directory

	_gut.set_should_maximize(_should_maximize)
	_gut.set_yield_between_tests(_yield_between_tests)
	_gut.disable_strict_datatype_checks(_disable_strict_datatype_checks)
	_gut.set_export_path(_export_path)
	_gut.set_include_subdirectories(_include_subdirectories)
	_gut.set_double_strategy(_double_strategy)
	_gut.set_pre_run_script(_pre_run_script)
	_gut.set_post_run_script(_post_run_script)
	_gut.set_color_output(_color_output)
	_gut.show_orphans(_show_orphans)
	_gut.set_junit_xml_file(_junit_xml_file)
	_gut.set_junit_xml_timestamp(_junit_xml_timestamp)

	get_parent().add_child(_gut)

	if(!_utils.is_version_ok()):
		return

	_gut.set_log_level(_log_level)

	_gut.add_directory(_directory1)
	_gut.add_directory(_directory2)
	_gut.add_directory(_directory3)
	_gut.add_directory(_directory4)
	_gut.add_directory(_directory5)
	_gut.add_directory(_directory6)

	_gut.get_logger().disable_printer('console', !_should_print_to_console)
	# When file logging enabled then the log will contain terminal escape
	# strings.  So when running the scene this is disabled.  Also if enabled
	# this may cause duplicate entries into the logs.
	_gut.get_logger().disable_printer('terminal', true)

	_gut.get_gui().set_font_size(_font_size)
	_gut.get_gui().set_font(_font_name)
	_gut.get_gui().set_default_font_color(_font_color)
	_gut.get_gui().set_background_color(_background_color)
	_gut.get_gui().rect_size =  rect_size
	emit_signal('gut_ready')

	if(_run_on_load):
		# Run the test scripts.  If one has been selected then only run that one
		# otherwise all tests will be run.
		var run_rest_of_scripts = _select_script == null
		_gut.test_scripts(run_rest_of_scripts)

func _is_ready_to_go(action):
	if(_gut == null):
		push_error(str('GUT is not ready for ', action, ' yet.  Perform actions on GUT in/after the gut_ready signal.'))
	return _gut != null

func _on_tests_finished():
	emit_signal('tests_finished')

func get_gut():
	return _gut

func export_if_tests_found():
	if(_is_ready_to_go('export_if_tests_found')):
		_gut.export_if_tests_found()

func import_tests_if_none_found():
	if(_is_ready_to_go('import_tests_if_none_found') and !_cancel_import):
		_gut.import_tests_if_none_found()
