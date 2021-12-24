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


func set_documentation(documentation: Documentation.QueryResult) -> void:
	for child_node in _docs_item_list.get_children():
		_docs_item_list.remove_child(child_node)
		child_node.queue_free()

	var template_label := RichTextLabel.new()
	template_label.fit_content_height = true
	template_label.bbcode_enabled = true

	if documentation.methods:
		var methods_header := template_label.duplicate()
		methods_header.bbcode_text = "[b]Method descriptions[/b]"
		_docs_item_list.add_child(methods_header)

		for doc_spec in documentation.methods:
			var docs_item := template_label.duplicate()
			docs_item.bbcode_text = (
				"• [code]%s[/code]\n\n%s"
				% [doc_spec.to_bbcode(), doc_spec.explanation]
			)
			_docs_item_list.add_child(docs_item)

	if documentation.properties:
		var properties_header := template_label.duplicate()
		properties_header.bbcode_text += "[b]Property descriptions[/b]"
		_docs_item_list.add_child(properties_header)

		for doc_spec in documentation.properties:
			var docs_item := template_label.duplicate()
			docs_item.bbcode_text = (
				"• [code]%s[/code]\n\n%s"
				% [doc_spec.to_bbcode(), doc_spec.explanation]
			)
			_docs_item_list.add_child(docs_item)

	docs_container.show()
	yield(get_tree(), "idle_frame")
	_docs_item_list.rect_size.y = 0


func clear_documentation() -> void:
	docs_container.hide()
