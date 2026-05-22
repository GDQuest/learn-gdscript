# Tests the code entered by a student in a given practice using a series of
# functions.
#
# To add a test, write a new method with a name starting with `test_`. The
# method should take no argument and return a String: an optional error message.
#
# If the returned string is empty, the test passed. If the string is not empty,
# the test failed.
#
# You can probe the tested scene and script slice using the `_scene` and
# `_slice` properties below.
@abstract
class_name PracticeTester
extends RefCounted

# Reference to the tested scene. Use it to test the state of nodes in the scene.
var _scene_root_viewport: Node
# Reference to the edited script slice. Use it to look at the user's code.
var _slice: ScriptSlice
var _code_lines := []
var _checker: GDScriptErrorChecker
var _analyzer: GDScriptASTAnalyzer
var _checks: Array[Check]


# We're not using _init() because it doesn't work unless you define it and call the parent's constructor in child classes. It would add boilerplate to every PracticeTester script.
func setup(scene_root: Node, slice: ScriptSlice) -> void:
	_slice = slice
	_scene_root_viewport = scene_root
	_checks = []
	_define(_checks)


@abstract
## All practice testers should define their tests by appending them to the checks array
func _define(checks: Array[Check]) -> void


func get_test_names() -> Array:
	return _checks.map(func (check: Check) -> Dictionary: return {"description": check._description, "tooltip": check._tooltip})


func _update_analyzer() -> void:
	_checker = GDScriptErrorChecker.new()
	_checker.set_source(_slice.current_text)
	var root := _checker.get_root_parse_node()
	_analyzer = GDScriptASTAnalyzer.new(root)


func run_tests() -> TestResult:
	var result := TestResult.new()

	_code_lines.clear()
	_update_analyzer()
	_prepare()

	for check in _checks:
		var error_message: String = check._checker.call()
		if error_message != "":
			result.errors[check._description] = error_message
		else:
			# We pass the test name to display it in the interface.
			result.passed_tests.push_back(check._description)

	_clean_up()

	return result


func _find_test_method_names() -> Dictionary:
	var output := { }

	var methods := []
	for method: Dictionary in get_method_list():
		var method_name: StringName = method.name
		if method_name.begins_with("test_"):
			methods.append(method_name)

	methods.sort()

	for method: StringName in methods:
		output[method] = method.trim_prefix("test_").capitalize()

	return output


# Virtual method.
# Called before running tests.
func _prepare() -> void:
	pass


# Virtual method.
# Called after running tests.
func _clean_up() -> void:
	pass


# Returns true if a line in the input `code` matches one of the `target_lines`.
# Uses String.match to match lines, so you can use ? and * in `target_lines`.
func matches_code_line(target_lines: Array) -> bool:
	if not _code_lines:
		_code_lines = _slice.current_text.split("\n")

	for line: String in _code_lines:
		line = line.replace(" ", "").strip_edges().rstrip(";")
		for match_pattern: String in target_lines:
			if line.match(match_pattern):
				return true
	return false


# Returns true if a line in the input `code` matches one of the `target_lines`.
# Uses RegEx to match lines.
func matches_code_line_regex(regex_patterns: Array) -> bool:
	var regexes = []
	for pattern: String in regex_patterns:
		var regex := RegEx.new()
		regex.compile(pattern)
		regexes.append(regex)

	if not _code_lines:
		_code_lines = _slice.current_text.split("\n")

	for line: String in _code_lines:
		for regex: RegEx in regexes:
			if regex.search(line):
				return true
	return false


class TestResult:
	# List of tests passed successfully in the test suite.
	var passed_tests := []
	var errors := { }


	func is_success() -> bool:
		return errors.is_empty()


class Check:
	var _description := ""
	var _tooltip := ""
	var _checker: Callable
	
	func _init(description: String, tooltip: String, checker: Callable) -> void:
		_description = description
		_tooltip = tooltip
		_checker = checker
