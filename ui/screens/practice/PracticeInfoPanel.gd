tool
class_name PracticeInfoPanel
extends PanelContainer

signal tests_updated
signal list_requested

enum Status { NONE, COMPLETED_BEFORE, SOLUTION_USED }

const STATUS_ICON_COMPLETED_BEFORE := preload("res://ui/icons/checkmark_valid.svg")
const STATUS_ICON_SOLUTION_USED := preload("res://ui/icons/checkmark_invalid.svg")

const QueryResult := Documentation.QueryResult
const TestDisplayScene = preload("PracticeTestDisplay.tscn")

export var title := "Title" setget set_title

var skip_animations := false

var _current_status: int = Status.NONE
var _documentation_results: QueryResult

onready var title_label := find_node("Title") as Label
onready var _status_icon := find_node("StatusIcon") as TextureRect

onready var goal_rich_text_label := find_node("Goal").find_node("TextBox") as RichTextLabel
onready var hints_container := find_node("Hints") as Revealer
onready var _checks := find_node("Checks") as Revealer
onready var docs_container := find_node("Documentation") as Revealer
onready var _docs_item_list := docs_container.find_node("DocumentationItems") as Control

onready var _list_button := find_node("ListButton") as Button


func _ready() -> void:
	_list_button.connect("pressed", self, "emit_signal", [ "list_requested" ])


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_documentation()


func display_tests(info: Array) -> void:
	var check: Node = _checks.get_contents().pop_back()
	while check:
		_checks.remove_child(check)
		check.queue_free()
		check = _checks.get_contents().pop_back()
	
	for test in info:
		var instance: PracticeTestDisplay = TestDisplayScene.instance()
		instance.title = tr(test)
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
			checkmark.mark_as_failed(skip_animations)
		elif checkmark.title in test_result.passed_tests:
			checkmark.mark_as_passed(skip_animations)
		else:
			checkmark.unmark(true)
		
		if skip_animations:
			yield(get_tree(), "idle_frame")
		else:
			yield(checkmark, "marking_finished")
	
	emit_signal("tests_updated")


func set_title(new_title: String) -> void:
	title = new_title
	if not is_inside_tree():
		yield(self, "ready")
	title_label.text = title


func set_documentation(documentation: QueryResult) -> void:
	_documentation_results = documentation
	_update_documentation()


func clear_documentation() -> void:
	_documentation_results = null
	_update_documentation()


func _update_documentation() -> void:
	for child_node in _docs_item_list.get_children():
		_docs_item_list.remove_child(child_node)
		child_node.queue_free()
	
	if not _documentation_results:
		docs_container.hide()
		return
	
	var template_label := RichTextLabel.new()
	template_label.fit_content_height = true
	template_label.bbcode_enabled = true
	template_label.add_font_override("normal_font", preload("res://ui/theme/fonts/font_documentation_normal.tres"))
	template_label.add_font_override("bold_font", preload("res://ui/theme/fonts/font_documentation_bold.tres"))
	template_label.add_font_override("italics_font", preload("res://ui/theme/fonts/font_documentation_italics.tres"))
	template_label.add_font_override("mono_font", preload("res://ui/theme/fonts/font_documentation_mono.tres"))

	if _documentation_results.methods:
		var methods_header := template_label.duplicate() as RichTextLabel
		methods_header.bbcode_text = "[b]" + tr("Method descriptions") + "[/b]"
		_docs_item_list.add_child(methods_header)

		for doc_spec in _documentation_results.methods:
			var docs_item := template_label.duplicate() as RichTextLabel
			docs_item.bbcode_text = (
				"• [code]%s[/code]\n  %s"
				% [doc_spec.to_bbcode(), tr(doc_spec.explanation)]
			)
			_docs_item_list.add_child(docs_item)

	if _documentation_results.properties:
		if _documentation_results.methods:
			_docs_item_list.add_child(HSeparator.new())

		var properties_header := template_label.duplicate() as RichTextLabel
		properties_header.bbcode_text += "[b]" + tr("Property descriptions") + "[/b]"
		_docs_item_list.add_child(properties_header)

		for doc_spec in _documentation_results.properties:
			var docs_item := template_label.duplicate() as RichTextLabel
			docs_item.bbcode_text = (
				"• [code]%s[/code]\n  %s"
				% [doc_spec.to_bbcode(), tr(doc_spec.explanation)]
			)
			_docs_item_list.add_child(docs_item)
	
	docs_container.show()
	yield(get_tree(), "idle_frame")
	_docs_item_list.rect_size.y = 0


func set_status_icon(status: int) -> void:
	if not _current_status == Status.NONE:
		return
	_current_status = status
	
	match status:
		Status.NONE:
			_status_icon.texture = null
			_status_icon.hint_tooltip = ""
			_status_icon.hide()

		Status.COMPLETED_BEFORE:
			_status_icon.texture = STATUS_ICON_COMPLETED_BEFORE
			_status_icon.hint_tooltip = "You've completed this practice before."
			_status_icon.show()

		Status.SOLUTION_USED:
			_status_icon.texture = STATUS_ICON_SOLUTION_USED
			_status_icon.hint_tooltip = "You've used the provided solution.\nThis practice will not count towards your course progress."
			_status_icon.show()
