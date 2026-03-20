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

	func _init(regexes: Dictionary) -> void:
		for pattern: String in regexes:
			var replacement: String = regexes[pattern]
			var regex := RegEx.new()
			regex.compile(pattern)
			_regexes[regex] = replacement
		_current_array = _regexes.keys()

	func replace(text: String) -> String:
		for regex: RegEx in _regexes:
			var replacement: String = _regexes[regex]
			text = regex.sub(text, replacement, true)
		return text

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
