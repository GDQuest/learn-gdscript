# Test script to load and parse the BBCode lesson file and display it in UILesson
extends Node

onready var ui_lesson: UILesson = get_node("UILesson")

var _parser := LessonBBCodeParser.new()


func _ready() -> void:
	var result := _parser.parse_file("res://tests/test_bbcode_lesson/lesson.bbcode")

	if result.errors:
		print("Parse errors:")
		for error in result.errors:
			print(error.format())

	if result.warnings:
		print("Parse warnings:")
		for warning in result.warnings:
			print(warning.format())

	print("Found %d content blocks" % result.lesson.content_blocks.size())
	print("Practices: %d" % result.lesson.practices.size())
	ui_lesson.setup(result.lesson, null)
