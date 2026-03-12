# Displays a Lesson ressource and a list a button to start each practice in a
# lesson.
#
# When pressing a practice button, emits an event so the navigation can
# transition to the practice screen.
class_name UILesson
extends UINavigatablePage

const ContentBlockScene := preload("screens/lesson/UIContentBlock.tscn")
const QuizInputFieldScene := preload("screens/lesson/quizzes/UIQuizInputField.tscn")
const QuizChoiceScene := preload("screens/lesson/quizzes/UIQuizChoice.tscn")
const PracticeButtonScene := preload("screens/lesson/UIPracticeButton.tscn")
const GDScriptCodeExampleScene := preload("res://course/common/GDScriptCodeExample.tscn")

const AUTOSCROLL_PADDING := 20
const AUTOSCROLL_DURATION := 0.24

export var test_lesson: Resource

signal lesson_displayed

var _lesson: BBCodeParser.ParseNode
# Resource used to highlight glossary entries in the lesson text.
var _glossary: Glossary
var _visible_index := -1
var _quizzes_done := -1  # Start with -1 because we will always autoincrement at least once.
var _quizz_count := 0
var _integration_test_mode := false

var _base_text_font_size := preload("res://ui/theme/fonts/font_text.tres").size

onready var _scroll_container := $OuterMargin/ScrollContainer as ScrollContainer
onready var _scroll_content := $OuterMargin/ScrollContainer/InnerMargin as Control
onready var _title := $OuterMargin/ScrollContainer/InnerMargin/Content/Title as Label
onready var _content_blocks := $OuterMargin/ScrollContainer/InnerMargin/Content/ContentBlocks as VBoxContainer
onready var _content_container := $OuterMargin/ScrollContainer/InnerMargin/Content as VBoxContainer
onready var _practices_visibility_container := $OuterMargin/ScrollContainer/InnerMargin/Content/PracticesContainer as VBoxContainer
onready var _practices_container := $OuterMargin/ScrollContainer/InnerMargin/Content/PracticesContainer/Practices as VBoxContainer
onready var _debounce_timer := $DebounceTimer as Timer
onready var _tweener := $Tween as Tween
onready var _glossary_popup := $GlossaryPopup

onready var _start_content_width := _content_container.rect_size.x


func _ready() -> void:
	Events.connect("font_size_scale_changed", self, "_update_content_container_width")
	_update_content_container_width(UserProfiles.get_profile().font_size_scale)
	_scroll_container.get_v_scrollbar().connect("value_changed", self, "_on_content_scrolled")
	_debounce_timer.connect("timeout", self, "_emit_read_content")
	TranslationManager.connect("translation_changed", self, "_on_translation_changed")

	_glossary = load("res://course/glossary.tres")

#	if test_lesson and get_parent() == get_tree().root:
#		setup(test_lesson, null)
#		for child in _content_blocks.get_children():
#			child.show()
#		_practices_container.show()

	_scroll_container.grab_focus()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_labels()


func setup(lesson: BBCodeParser.ParseNode, course_index: CourseIndex) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_lesson = lesson
	_title.text = tr(BBCodeUtils.get_lesson_title(lesson))
	var user_profile := UserProfiles.get_profile()

	# If this was the last lesson the student interacted with before, we will try to restore
	# their reading position.
	var is_returning := false
	if course_index:
		var last_lesson := user_profile.get_last_started_lesson(course_index.get_course_id())
		is_returning = _lesson.bbcode_path == last_lesson

	var restore_node: Control
	var restore_id := ""
	if course_index:
		# We have 4 possible situations:
		#  - We are returning to the last visited lesson and must set the position to the last content
		# block the user has seen.
		#  - We are opening a lesson for the first time and must remain at the top.
		#  - We are opening a lesson that is completed, at least the reading part, and must remain at
		# the top.
		#  - We are opening a lesson that we were in the middle of, but not the last one; we must set
		# the position to the first unread block.

		if is_returning:
			restore_id = user_profile.get_last_visited_lesson_block(
				course_index.get_course_id(), lesson.bbcode_path
			)

		var reading_done := user_profile.is_lesson_reading_completed(
			course_index.get_course_id(), lesson.bbcode_path
		)
		var reading_started := user_profile.has_lesson_blocks_read(
			course_index.get_course_id(), lesson.bbcode_path
		)
		if restore_id.empty() and not reading_done and reading_started:
			pass
#			for block in lesson.content_blocks:
#				var block_id := ""
#				if block is Quiz:
#					block_id = block.quiz_id
#				else:
#					block_id = block.content_id
#
#				if user_profile.is_lesson_block_read(
#					course_index.get_course_id(), lesson.bbcode_path, block_id
#				):
#					continue
#
#				restore_id = block_id
#				break

	var content_block_count := BBCodeUtils.get_lesson_block_count(lesson)

	for i in content_block_count:
		var type = BBCodeUtils.get_lesson_block_type(lesson, i)
		if type == BBCodeParserData.Tag.STRING:
			var instance: UIContentBlock = ContentBlockScene.instance()
			var block_id: String = "_generated_content_block_plain_%s" % i
			instance.name = block_id
			_content_blocks.add_child(instance)
			var content: String = lesson.children[i]
			instance.setup(content, lesson, i)
			instance.hide()
						
			if restore_id == block_id:
				restore_node = instance
			
			
		else:
			var child_node: BBCodeParser.ParseNode = lesson.children[i]
			match BBCodeUtils.get_node_type(child_node):
				BBCodeParserData.Tag.QUIZ_CHOICE, BBCodeParserData.Tag.QUIZ_INPUT:
					var scene := (
						QuizChoiceScene if child_node.tag == BBCodeParserData.Tag.QUIZ_CHOICE
						else QuizInputFieldScene
					)
					var instance := scene.instance()
					var quiz_id := BBCodeUtils.get_quiz_id(child_node)
					instance.name = quiz_id
					_content_blocks.add_child(instance)
					instance.setup(child_node)
					instance.hide()
					
					var completed_before := false
					if course_index:
						completed_before = user_profile.is_lesson_quiz_completed(
							course_index.get_course_id(), lesson.bbcode_path, quiz_id
						)
						if completed_before:
							_quizzes_done += 1
					instance.completed_before = completed_before
					
					instance.connect("quiz_passed", Events, "emit_signal", ["quiz_completed", child_node])
					instance.connect("quiz_passed", self, "_reveal_up_to_next_quiz")
					instance.connect("quiz_skipped", self, "_reveal_up_to_next_quiz")
					
					if restore_id == quiz_id:
						restore_node = instance
			
				BBCodeParserData.Tag.CODEBLOCK:
					var instance: UIContentBlock = ContentBlockScene.instance()
					var block_id := BBCodeUtils.get_codeblock_id(child_node)
					instance.name = block_id
					instance.text = BBCodeUtils.get_codeblock_code(child_node)
					_content_blocks.add_child(instance)
					instance.hide()
					
					if restore_id == block_id:
						restore_node = instance
				
				_:
					if (
						child_node.tag in BBCodeParserData.CONTENT_PRODUCING_TAGS and
						not child_node.tag == BBCodeParserData.Tag.PRACTICE and
						not child_node.tag == BBCodeParserData.Tag.TITLE and
						not child_node.tag == BBCodeParserData.Tag.PRACTICE and
						not child_node.tag == BBCodeParserData.Tag.SEPARATOR
					):
						var instance: UIContentBlock = ContentBlockScene.instance()
						var block_id := BBCodeUtils.get_lesson_block_id(child_node)
						instance.name = block_id
						_content_blocks.add_child(instance)
						instance.setup(child_node, lesson, i)
						instance.hide()
						
						if restore_id == block_id:
							restore_node = instance

	var highlighted_next := false
	var practice_count := BBCodeUtils.get_lesson_practice_count(lesson)
	for i in practice_count:
		var practice := BBCodeUtils.get_lesson_practice(lesson, i)
		var practice_id := BBCodeUtils.get_practice_id(practice)
		var button: UIPracticeButton = PracticeButtonScene.instance()
		button.setup(practice, i)
		if course_index:
			button.completed_before = user_profile.is_lesson_practice_completed(
				course_index.get_course_id(), lesson.bbcode_path, practice_id
			)
			if not highlighted_next and not button.completed_before:
				highlighted_next = true
				button.is_highlighted = true
		_practices_container.add_child(button)
	_practices_visibility_container.hide()

	_quizz_count = BBCodeUtils.get_lesson_quiz_count(lesson)
	_reveal_up_to_next_quiz()

	if _integration_test_mode:
		yield(get_tree(), "idle_frame")
		emit_signal("lesson_displayed")
		return

	# Wait until the lesson is considered loaded by the system, and then update the size of
	# the scroll container and its content.
	yield(Events, "lesson_started")
	if restore_node and restore_node.is_visible_in_tree():
		var scroll_offset = abs(
			_scroll_content.rect_global_position.y - _content_blocks.rect_global_position.y
		)
		var scroll_target = restore_node.rect_position.y + scroll_offset - AUTOSCROLL_PADDING
		_tweener.stop_all()
		_tweener.interpolate_method(
			_scroll_container,
			"set_v_scroll",  # So it plays nice with our smooth scroller
			_scroll_container.scroll_vertical,
			scroll_target,
			AUTOSCROLL_DURATION,
			Tween.TRANS_QUAD,
			Tween.EASE_IN_OUT
		)
		_tweener.start()

	_underline_glossary_entries()

	# Call this immediately to update for the blocks that are already visible.
	_emit_read_content()


func _underline_glossary_entries() -> void:
	_glossary.setup()
	# Underline glossary entries
	for rtl in get_tree().get_nodes_in_group("rich_text_label"):
		rtl.bbcode_text = _glossary.replace_matching_terms(rtl.bbcode_text)
		if not rtl.is_connected("meta_clicked", self, "_open_glossary_popup"):
			rtl.connect("meta_clicked", self, "_open_glossary_popup")


func _update_labels() -> void:
	if not _lesson:
		return

	_title.text = tr(_lesson.title)


func get_screen_resource() -> BBCodeParser.ParseNode:
	return _lesson


func enable_integration_test_mode() -> void:
	_integration_test_mode = true


func _reveal_up_to_next_quiz() -> void:
	if _integration_test_mode:
		# In integration test mode, skip quiz checks and reveal all content immediately
		_visible_index = _content_blocks.get_child_count() - 1
		for child in _content_blocks.get_children():
			child.show()
		_practices_visibility_container.show()
		_quizzes_done = _quizz_count
		emit_signal("lesson_displayed")
		return

	_quizzes_done += 1

	var child_count := _content_blocks.get_child_count()
	while _visible_index < child_count - 1:
		_visible_index += 1

		var child = _content_blocks.get_child(_visible_index)
		child.show()

		if child is UIBaseQuiz and not child.completed_before:
			break

	if _visible_index >= child_count - 1 and _quizzes_done >= _quizz_count:
		_practices_visibility_container.show()


func _on_content_scrolled(_value: float) -> void:
	_debounce_timer.start()


func _emit_read_content() -> void:
	var scroll_offset = abs(
		_scroll_content.rect_global_position.y - _content_blocks.rect_global_position.y
	)
	var scroll_distance = _scroll_container.scroll_vertical - scroll_offset - AUTOSCROLL_PADDING

	var content_index := 0
	var content_blocks := []

	for child_node in _content_blocks.get_children():
		var control_node := child_node as Control
		if not control_node:
			continue

		# We reached the end of visible blocks.
		if not control_node.visible:
			break

		var content_block_count := BBCodeUtils.get_lesson_block_count(_lesson)
		if content_index < content_block_count:
			content_blocks.append(_lesson.children[content_index])

		var content_offset := control_node.rect_position.y
		if content_offset > scroll_distance:
			break
		content_index += 1

	if content_blocks.size() > 0:
		var last_block = content_blocks.pop_back()
		Events.emit_signal("lesson_reading_block", last_block, content_index, content_blocks)


func _update_content_container_width(new_font_scale: int) -> void:
	var font_size_multiplier := (
		float(_base_text_font_size + new_font_scale * 2)
		/ _base_text_font_size
	)
	_content_container.rect_min_size.x = _start_content_width * font_size_multiplier


func _on_translation_changed() -> void:
	_underline_glossary_entries()


func _open_glossary_popup(meta: String) -> void:
	var entry: Glossary.Entry = _glossary.get_match(meta)
	if entry == null:
		return
	_glossary_popup.setup(entry.term, entry.explanation)
	_glossary_popup.call_deferred("align_with_mouse", get_global_mouse_position())
	_glossary_popup.appear()
