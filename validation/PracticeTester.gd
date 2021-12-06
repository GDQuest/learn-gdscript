# Tests the code entered by a student in a given practice using a series of
# functions.
#
# To add a test, write a new method with a name starting with `test_`. The
# method should take no argument and return a String.
class_name PracticeTester
extends Reference

signal passed_all_tests
signal failed_tests(validation_result)

var _test_methods := _find_test_method_names()


func get_test_names() -> Array:
	return _test_methods.values()


func run_tests() -> void:
	var result := TestResult.new()
	for method in _test_methods:
		var error_message: String = call(method)
		if error_message != "":
			emit_signal("failed_tests", result)
			return
		else:
			# We pass the test name to display it in the interface.
			result.passed_tests.append(_test_methods[method])
	emit_signal("passed_all_tests")


func _find_test_method_names() -> Dictionary:
	var output := {}
	for method in get_method_list():
		if method.name.begins_with("test_"):
			output[method] = method.name.trim_prefix("test_").capitalize()
	return output


class TestResult:
	# List of tests passed successfully in the test suite.
	var passed_tests := PoolStringArray()
	var error := ""
