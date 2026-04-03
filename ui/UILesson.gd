# Displays a Lesson ressource and a list a button to start each practice in a
# lesson.
#
# When pressing a practice button, emits an event so the navigation can
# transition to the practice screen.
class_name UILesson
extends UINavigatablePage

const DEFAULT_COURSE_INDEX := "res://course/CourseLearnGDScriptIndex.gd"

const ContentBlockScene := preload("screens/lesson/UIContentBlock.tscn")
const QuizInputFieldScene := preload("screens/lesson/quizzes/UIQuizInputField.tscn")
const QuizChoiceScene := preload("screens/lesson/quizzes/UIQuizChoice.tscn")
const PracticeButtonScene := preload("screens/lesson/UIPracticeButton.tscn")
const GDScriptCodeExampleScene := preload("res://course/common/GDScriptCodeExample.tscn")
const GlossaryPopup := preload("res://ui/components/GlossaryPopup.gd")

const AUTOSCROLL_PADDING := 20
const AUTOSCROLL_DURATION := 0.24

@export var test_lesson: String
@export var _scroll_container: ScrollContainer
@export var _scroll_content: Control
@export var _title: Label
@export var _content_blocks: VBoxContainer
@export var _content_container: VBoxContainer
@export var _practices_visibility_container: VBoxContainer
@export var _practices_container: VBoxContainer
@export var _debounce_timer: Timer
@export var _glossary_popup: GlossaryPopup

signal lesson_displayed

var _lesson: BBCodeParser.ParseNode
# Resource used to highlight glossary entries in the lesson text.
var _glossary: Glossary
var _visible_index := -1
var _quizzes_done := -1 # Start with -1 because we will always autoincrement at least once.
var _quizz_count := 0
var _integration_test_mode := false

var _base_text_font_size := preload("res://ui/theme/fonts/font_text.tres").base_font.msdf_size
var _scene_tween: Tween

@onready var _start_content_width := _content_container.size.x


func _ready() -> void:
	super._ready()

	Events.font_size_scale_changed.connect(_update_content_container_width)
	_update_content_container_width(UserProfiles.get_profile().font_size_scale)
	_scroll_container.get_v_scroll_bar().value_changed.connect(_on_content_scrolled)
	_debounce_timer.timeout.connect(_emit_read_content)
	TranslationManager.translation_changed.connect(_on_translation_changed)

	_glossary = load("res://course/glossary.tres")

	if test_lesson and get_parent() == get_tree().root:
		var _lesson_node := NavigationManager.get_navigation_resource(test_lesson)
		var _course_index: CourseIndex = load(DEFAULT_COURSE_INDEX).new()
		setup(_lesson_node, _course_index)
		for child in _content_blocks.get_children():
			child.show()
		_practices_container.show()

	_scroll_container.grab_focus()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_labels()


func setup(lesson: BBCodeParser.ParseNode, course_index: CourseIndex) -> void:
	if not is_inside_tree():
		await self.ready

	_lesson = lesson
	_title.text = tr(BBCodeUtils.get_lesson_title(lesson))
	var user_profile := UserProfiles.get_profile()

	var content_block_count := BBCodeUtils.get_lesson_block_count(lesson)
	for i in content_block_count:
		var type = BBCodeUtils.get_lesson_block_type(lesson, i)
		if type == BBCodeParserData.Tag.STRING:
			var instance: UIContentBlock = ContentBlockScene.instantiate()
			_content_blocks.add_child(instance)
			var content: String = lesson.children[i]
			var instance_name: String = BBCodeUtils._to_snake_case(content.substr(0, 30 if content.length() > 30 else content.length()))
			instance.name = instance_name
			instance.setup(content, lesson, i)
			instance.hide()
		else:
			var child_node: BBCodeParser.ParseNode = lesson.children[i]
			var node_type := child_node.tag
			match node_type:
				BBCodeParserData.Tag.QUIZ_CHOICE, BBCodeParserData.Tag.QUIZ_INPUT:
					var scene := (
						QuizChoiceScene if node_type == BBCodeParserData.Tag.QUIZ_CHOICE
						else QuizInputFieldScene
					)
					var instance: UIBaseQuiz = scene.instantiate()
					var quiz_id := BBCodeUtils.get_quiz_id(child_node)
					instance.name = quiz_id
					_content_blocks.add_child(instance)
					instance.setup(child_node)
					instance.hide()

					var completed_before := false
					if course_index:
						completed_before = user_profile.is_lesson_quiz_completed(
							course_index.get_course_id(),
							lesson.bbcode_path,
							quiz_id,
						)
						if completed_before:
							_quizzes_done += 1
					instance.completed_before = completed_before

					instance.quiz_passed.connect(Events.quiz_completed.emit.bind(child_node))
					instance.quiz_passed.connect(_reveal_up_to_next_quiz)
					instance.quiz_skipped.connect(_reveal_up_to_next_quiz)

				BBCodeParserData.Tag.CODEBLOCK:
					var instance: UIContentBlock = ContentBlockScene.instantiate()
					instance.name = BBCodeUtils.get_codeblock_id(child_node)
					instance.text = BBCodeUtils.get_codeblock_code(child_node)
					_content_blocks.add_child(instance)
					instance.hide()
				BBCodeParserData.Tag.PRACTICE, BBCodeParserData.Tag.TITLE, BBCodeParserData.Tag.SEPARATOR:
					# handled separately or used to enhance other tags. no processing
					pass
				_:
					if child_node.tag in BBCodeParserData.CONTENT_PRODUCING_TAGS:
						var instance: UIContentBlock = ContentBlockScene.instantiate()
						instance.name = "_generated_%s_%s" % [BBCodeParserData.Tag.keys()[child_node.tag], i]
						_content_blocks.add_child(instance)
						instance.setup(child_node, lesson, i)
						instance.hide()

	var highlighted_next := false
	var practice_count := BBCodeUtils.get_lesson_practice_count(lesson)
	for i in practice_count:
		var practice := BBCodeUtils.get_lesson_practice(lesson, i)
		var practice_id := BBCodeUtils.get_practice_id(practice)
		var button: UIPracticeButton = PracticeButtonScene.instantiate()
		button.setup(practice, i)
		if course_index:
			button.completed_before = user_profile.is_lesson_practice_completed(
				course_index.get_course_id(),
				lesson.bbcode_path,
				practice_id,
			)
			if not highlighted_next and not button.completed_before:
				highlighted_next = true
				button.is_highlighted = true
		_practices_container.add_child(button)
	_practices_visibility_container.hide()

	_quizz_count = BBCodeUtils.get_lesson_quiz_count(lesson)
	_reveal_up_to_next_quiz()

	if _integration_test_mode:
		await get_tree().process_frame
		emit_signal("lesson_displayed")
		return

	# Wait until the lesson is considered loaded by the system, and then update the size of
	# the scroll container and its content.
	await Events.lesson_started

	_underline_glossary_entries()

	# Call this immediately to update for the blocks that are already visible.
	_emit_read_content()


func _underline_glossary_entries() -> void:
	# Underline glossary entries
	for rtl: RichTextLabel in get_tree().get_nodes_in_group("rich_text_label"):
		rtl.text = _glossary.replace_matching_terms(rtl.text)
		if not rtl.meta_clicked.is_connected(_open_glossary_popup):
			rtl.meta_clicked.connect(_open_glossary_popup)


func _update_labels() -> void:
	if not _lesson:
		return

	var title := BBCodeUtils.get_lesson_title(_lesson)
	_title.text = tr(title)


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
		lesson_displayed.emit()
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
		_scroll_content.global_position.y - _content_blocks.global_position.y,
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

		var content_offset := control_node.position.y
		if content_offset > scroll_distance:
			break
		content_index += 1

	if content_blocks.size() > 0:
		var last_block = content_blocks.pop_back()
		Events.lesson_reading_block.emit(last_block, content_index, content_blocks)


func _update_content_container_width(new_font_scale: int) -> void:
	var font_size_multiplier := (
		float(_base_text_font_size + new_font_scale * 2)
		/ _base_text_font_size
	)
	_content_container.custom_minimum_size.x = _start_content_width * font_size_multiplier


func _on_translation_changed() -> void:
	_glossary.setup()
	_underline_glossary_entries()


func _open_glossary_popup(meta: String) -> void:
	var entry: Glossary.Entry = _glossary.get_match(meta)
	if entry == null:
		return
	_glossary_popup.setup(entry.term, entry.explanation)
	_glossary_popup.align_with_mouse.call_deferred(get_global_mouse_position())
	_glossary_popup.appear()
