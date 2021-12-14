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
class_name PracticeTester
extends Reference

# Reference to the tested scene. Use it to test the state of nodes in the scene.
var _scene_root_viewport: Node
# Reference to the edited script slice. Use it to look at the user's code.
var _slice: SliceProperties
var _test_methods := _find_test_method_names()


# We're not using _init() because it doesn't work unless you define it and call the parent's constructor in child classes. It would add boilerplate to every PracticeTester script.
func setup(scene_root: Node, slice: SliceProperties) -> void:
	_slice = slice
	_scene_root_viewport = scene_root


func get_test_names() -> Array:
	return _test_methods.values()


func run_tests() -> TestResult:
	var result := TestResult.new()
	for method in _test_methods:
		var error_message: String = call(method)
		if error_message != "":
			result.error = error_message
			break
		else:
			# We pass the test name to display it in the interface.
			result.passed_tests.push_back(_test_methods[method])
	return result


func _find_test_method_names() -> Dictionary:
	var output := {}
	for method in get_method_list():
		if method.name.begins_with("test_"):
			output[method.name] = method.name.trim_prefix("test_").capitalize()
	return output


class TestResult:
	# List of tests passed successfully in the test suite.
	var passed_tests := []
	var error := ""

	func is_success() -> bool:
		return error == ""
