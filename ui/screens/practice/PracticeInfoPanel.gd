@tool
class_name PracticeInfoPanel
extends PanelContainer

signal tests_updated
signal list_requested

enum Status { NONE, COMPLETED_BEFORE, SOLUTION_USED }

const STATUS_ICON_COMPLETED_BEFORE := preload("res://ui/icons/checkmark_valid.svg")
const STATUS_ICON_SOLUTION_USED := preload("res://ui/icons/checkmark_invalid.svg")

const QueryResult := Documentation.QueryResult
const TestDisplayScene = preload("PracticeTestDisplay.tscn")

var _title: String = "Title"

@export var title: String:
	set(value):
		set_title(value)
	get:
		return _title

var skip_animations := false

var _current_status: int = Status.NONE
var _documentation_results: QueryResult

@onready var title_label := find_child("Title", true, false) as Label
@onready var _status_icon := find_child("StatusIcon", true, false) as TextureRect

@onready var goal_rich_text_label := (find_child("Goal", true, false) as Node).find_child("TextBox", true, false) as RichTextLabel
@onready var hints_container := find_child("Hints", true, false) as Revealer
@onready var _checks := find_child("Checks", true, false) as Revealer
@onready var docs_container := find_child("Documentation", true, false) as Revealer
@onready var _docs_item_list := (docs_container as Node).find_child("DocumentationItems", true, false) as Control

@onready var _list_button := find_child("ListButton", true, false) as Button


func _ready() -> void:
	_list_button.pressed.connect(func(): list_requested.emit())


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_documentation()


func display_tests(info: Array[String]) -> void:
	var check: Node = _checks.get_contents().pop_back()
	while check:
		_checks.remove_child(check)
		check.queue_free()
		check = _checks.get_contents().pop_back()

	for test: String in info:
		var instance: PracticeTestDisplay = TestDisplayScene.instantiate()
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
		await get_tree().process_frame
		emit_signal("tests_updated")
		return

	# Update tests one by one with animation.
	for node in check_nodes:
		var checkmark := node as PracticeTestDisplay
		if not checkmark:
			continue

		if checkmark.title in test_result.errors:
			var error = test_result.errors[checkmark.title]
			MessageBus.print_error(str(error), script_file_name)
			checkmark.mark_as_failed(skip_animations)
		elif checkmark.title in test_result.passed_tests:
			checkmark.mark_as_passed(skip_animations)
		else:
			checkmark.unmark(true)

		if skip_animations:
			await get_tree().process_frame
		else:
			await checkmark.marking_finished

	emit_signal("tests_updated")


func set_title(new_title: String) -> void:
	_title = new_title
	if not is_inside_tree():
		await ready
	title_label.text = _title


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

	var template_label: RichTextLabel = RichTextLabel.new()
	template_label.bbcode_enabled = true
	template_label.add_theme_font_override("normal_font", preload("res://ui/theme/fonts/font_documentation_normal.tres"))
	template_label.add_theme_font_override("bold_font", preload("res://ui/theme/fonts/font_documentation_bold.tres"))
	template_label.add_theme_font_override("italics_font", preload("res://ui/theme/fonts/font_documentation_italics.tres"))
	template_label.add_theme_font_override("mono_font", preload("res://ui/theme/fonts/font_documentation_mono.tres"))

	if _documentation_results.methods:
		var methods_header: RichTextLabel = template_label.duplicate() as RichTextLabel
		methods_header.bbcode_enabled = true
		methods_header.text = "[b]" + tr("Method descriptions") + "[/b]"
		_docs_item_list.add_child(methods_header)

		for doc_spec in _documentation_results.properties:
			var docs_item: RichTextLabel = template_label.duplicate() as RichTextLabel
			docs_item.bbcode_enabled = true
			docs_item.text = "• [code]%s[/code]\n  %s" % [
				doc_spec.to_bbcode(),
				TextUtils.tr_paragraph(doc_spec.explanation),
			]
			_docs_item_list.add_child(docs_item)

	if _documentation_results.properties:
		if _documentation_results.methods:
			_docs_item_list.add_child(HSeparator.new())

		var properties_header: RichTextLabel = template_label.duplicate() as RichTextLabel
		properties_header.bbcode_enabled = true
		properties_header.text = "[b]" + tr("Property descriptions") + "[/b]"
		_docs_item_list.add_child(properties_header)

		for doc_spec in _documentation_results.properties:
			var docs_item: RichTextLabel = template_label.duplicate() as RichTextLabel
			docs_item.bbcode_enabled = true
			docs_item.text = "• [code]%s[/code]\n  %s" % [
				doc_spec.to_bbcode(),
				TextUtils.tr_paragraph(doc_spec.explanation),
			]
			_docs_item_list.add_child(docs_item)

	docs_container.show()
	await get_tree().process_frame
	_docs_item_list.size.y = 0


func set_status_icon(status: int) -> void:
	if not _current_status == Status.NONE:
		return
	_current_status = status

	match status:
		Status.NONE:
			_status_icon.texture = null
			_status_icon.tooltip_text = ""
			_status_icon.hide()

		Status.COMPLETED_BEFORE:
			_status_icon.texture = STATUS_ICON_COMPLETED_BEFORE
			_status_icon.tooltip_text = "You've completed this practice before."
			_status_icon.show()

		Status.SOLUTION_USED:
			_status_icon.texture = STATUS_ICON_SOLUTION_USED
			_status_icon.tooltip_text = "You've used the provided solution.\nThis practice will not count towards your course progress."
			_status_icon.show()
