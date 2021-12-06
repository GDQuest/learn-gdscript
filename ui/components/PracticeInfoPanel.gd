tool
class_name PracticeInfoPanel
extends PanelContainer

const TestDisplayScene = preload("PracticeTestDisplay.tscn")

export var title := "Title" setget set_title

onready var title_label := find_node("Title") as Label
onready var progress_bar := find_node("ProgressBar") as ProgressBar
onready var goal_rich_text_label := find_node("Goal").find_node("TextBox") as RichTextLabel
onready var hints_container := find_node("Hints") as Revealer

onready var _checks := find_node("Checks") as Revealer


func display_tests(info: Array) -> void:
	for test in info:
		var instance: PracticeTestDisplay = TestDisplayScene.instance()
		instance.title = test
		_checks.add_child(instance)


func update_tests_display(test_result: PracticeTester.TestResult) -> void:
	for node in _checks.get_contents():
		var checkmark := node as PracticeTestDisplay
		if checkmark.title in test_result.passed_tests:
			checkmark.mark_as_passed()
		else:
			checkmark.mark_as_failed()


func set_title(new_title: String) -> void:
	title = new_title
	if not is_inside_tree():
		yield(self, "ready")
	title_label.text = title
