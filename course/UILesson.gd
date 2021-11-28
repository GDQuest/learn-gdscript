class_name UILesson
extends Control

const ContentBlockScene := preload("UIContentBlock.tscn")
const PracticeButtonScene := preload("UIPracticeButton.tscn")

onready var _title := $Title as Label
onready var _content_blocks := $ContentBlocks as VBoxContainer
onready var _practices := $Practices as VBoxContainer


func _ready() -> void:
	setup(preload("res://course/lesson-66929/lesson.tres"))


func setup(lesson: Resource) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_title.text = lesson.title

	for block in lesson.content_blocks:
		var instance: UIContentBlock = ContentBlockScene.instance()
		instance.setup(block)
		_content_blocks.add_child(instance)

	for practice in lesson.practices:
		var instance = PracticeButtonScene.instance()
		instance.setup(practice)
		_practices.add_child(instance)
