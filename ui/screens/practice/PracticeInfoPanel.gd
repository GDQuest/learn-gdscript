tool
class_name PracticeInfoPanel
extends PanelContainer

signal tests_updated

const QueryResult := Documentation.QueryResult
const TestDisplayScene = preload("PracticeTestDisplay.tscn")

export var title := "Title" setget set_title

onready var title_label := find_node("Title") as Label
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


func reset_tests_status() -> void:
	var check_nodes := _checks.get_contents()
	for node in check_nodes:
		var checkmark := node as PracticeTestDisplay
		if not checkmark:
			continue
		
		checkmark.unmark(true)


func set_tests_pending() -> void:
	var check_nodes := _checks.get_contents()
	for node in check_nodes:
		var checkmark := node as PracticeTestDisplay
		if not checkmark:
			continue
		
		checkmark.mark_as_pending(true)


func set_tests_status(test_result: PracticeTester.TestResult, script_file_name: String) -> void:
	var check_nodes := _checks.get_contents()
	if check_nodes.size() == 0:
		# Ensure asynchrosity even in invalid state.
		yield(get_tree(), "idle_frame")
		emit_signal("tests_updated")
		return
	
	# Update tests one by one with animation.
	for node in check_nodes:
		var checkmark := node as PracticeTestDisplay
		if not checkmark:
			continue
		
		if checkmark.title in test_result.errors:
			var error = test_result.errors[checkmark.title]
			MessageBus.print_error(error, script_file_name)
			
			checkmark.mark_as_failed()
			yield(checkmark, "marking_finished")
			
		elif checkmark.title in test_result.passed_tests:
			checkmark.mark_as_passed()
			yield(checkmark, "marking_finished")
		
		else:
			checkmark.unmark(true)
			yield(checkmark, "marking_finished")
	
	emit_signal("tests_updated")


func set_title(new_title: String) -> void:
	title = new_title
	if not is_inside_tree():
		yield(self, "ready")
	title_label.text = title


func set_documentation(documentation: QueryResult) -> void:
	for child_node in _docs_item_list.get_children():
		_docs_item_list.remove_child(child_node)
		child_node.queue_free()

	var template_label := RichTextLabel.new()
	template_label.fit_content_height = true
	template_label.bbcode_enabled = true
	template_label.add_font_override("normal_font", preload("res://ui/theme/fonts/font_documentation_normal.tres"))
	template_label.add_font_override("bold_font", preload("res://ui/theme/fonts/font_documentation_bold.tres"))
	template_label.add_font_override("italics_font", preload("res://ui/theme/fonts/font_documentation_italics.tres"))
	template_label.add_font_override("mono_font", preload("res://ui/theme/fonts/font_documentation_mono.tres"))

	if documentation.methods:
		var methods_header := template_label.duplicate() as RichTextLabel
		methods_header.bbcode_text = "[b]Method descriptions[/b]"
		_docs_item_list.add_child(methods_header)

		for doc_spec in documentation.methods:
			var docs_item := template_label.duplicate() as RichTextLabel
			docs_item.bbcode_text = (
				"• [code]%s[/code]\n  %s"
				% [doc_spec.to_bbcode(), doc_spec.explanation]
			)
			_docs_item_list.add_child(docs_item)

	if documentation.properties:
		if documentation.methods:
			_docs_item_list.add_child(HSeparator.new())

		var properties_header := template_label.duplicate() as RichTextLabel
		properties_header.bbcode_text += "[b]Property descriptions[/b]"
		_docs_item_list.add_child(properties_header)

		for doc_spec in documentation.properties:
			var docs_item := template_label.duplicate() as RichTextLabel
			docs_item.bbcode_text = (
				"• [code]%s[/code]\n  %s"
				% [doc_spec.to_bbcode(), doc_spec.explanation]
			)
			_docs_item_list.add_child(docs_item)

	docs_container.show()
	yield(get_tree(), "idle_frame")
	_docs_item_list.rect_size.y = 0


func clear_documentation() -> void:
	docs_container.hide()
