tool
class_name PracticeInfoPanel
extends PanelContainer

const TestDisplayScene = preload("PracticeTestDisplay.tscn")

export var title := "Title" setget set_title

onready var title_label := find_node("Title") as Label
onready var progress_bar := find_node("ProgressBar") as ProgressBar
onready var goal_rich_text_label := find_node("Goal").find_node("TextBox") as RichTextLabel
onready var hints_container := find_node("Hints") as Revealer
onready var docs_container := find_node("Documentation") as Revealer
onready var _docs_item_list := docs_container.find_node("DocumentationItems") as Control

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


func set_documentation(doc_array: Array) -> void:
	for child_node in _docs_item_list.get_children():
		_docs_item_list.remove_child(child_node)
		child_node.queue_free()
	
	var methods_header := RichTextLabel.new()
	methods_header.fit_content_height = true
	methods_header.bbcode_enabled = true
	methods_header.bbcode_text = "[b]Method descriptions[/b]"
	_docs_item_list.add_child(methods_header)
	
	for doc_spec in doc_array:
		var docs_item := RichTextLabel.new()
		docs_item.fit_content_height = true
		docs_item.bbcode_enabled = true
		docs_item.bbcode_text = "• [code]%s[/code]\n\n%s" % [doc_spec.to_bbcode(), doc_spec.explanation.strip_edges()]
		_docs_item_list.add_child(docs_item)

	docs_container.show()
	yield(get_tree(), "idle_frame")
	_docs_item_list.rect_size.y = 0


func clear_documentation() -> void:
	docs_container.hide()
