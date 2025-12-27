# Utility class that provides utility to quickly create regex objects and
# replace text with multiple regular expressions.
class_name RegExpGroup
extends RefCounted

static func compile(pattern: String) -> RegEx:
	var regex := RegEx.new()
	regex.compile(pattern)
	return regex

static func collection(patterns: Dictionary) -> RegExCollection:
	return RegExCollection.new(patterns)


class RegExCollection:
	var _regexes := {}
	var _current_index := 0
	var _current_array := []

	func _init(regex_data: Dictionary) -> void:
		for pattern: String in regex_data:
			var replacement: String = regex_data[pattern]
			var regex := RegEx.new()
			var error := regex.compile(pattern)
			if error != OK:
				push_error("RegExpGroup: Failed to compile pattern: ", pattern)
			_regexes[regex] = replacement
		
		_current_array.clear()
		for r: RegEx in _regexes.keys():
			_current_array.append(r)

	func _iterator_is_valid() -> bool:
		return _current_index < _current_array.size()

	func _iter_init(_arg) -> bool:
		_current_index = 0
		_current_array = _regexes.keys()
		return _iterator_is_valid()

	func _iter_next(_arg) -> bool:
		_current_index += 1
		return _iterator_is_valid()

	func _iter_get(_arg):
		return current()

	func size() -> int:
		return _regexes.size()

	func keys() -> Array:
		return _regexes.keys()

	func values() -> Array:
		return _regexes.values()

	func current() -> RegEx:
		return _current_array[_current_index]

	func currentReplacement() -> String:
		return _regexes[current()]
