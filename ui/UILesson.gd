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

const AUTOSCROLL_PADDING := 20
const AUTOSCROLL_DURATION := 0.24

@export var test_lesson: Resource

signal lesson_displayed

var _lesson: Lesson
# Resource used to highlight glossary entries in the lesson text.
var _glossary: Glossary
var _visible_index := -1
var _quizzes_done := -1
var _quizz_count := 0
var _integration_test_mode := false

var _base_text_font := preload("res://ui/theme/fonts/font_text.tres") as Font
var _base_text_font_size: float = _base_text_font.get_height()

@onready var _scroll_container: ScrollContainer = $OuterMargin/ScrollContainer
@onready var _scroll_content: Control = $OuterMargin/ScrollContainer/InnerMargin
@onready var _title: Label = $OuterMargin/ScrollContainer/InnerMargin/Content/Title
@onready var _content_blocks: VBoxContainer = $OuterMargin/ScrollContainer/InnerMargin/Content/ContentBlocks
@onready var _content_container: VBoxContainer = $OuterMargin/ScrollContainer/InnerMargin/Content
@onready var _practices_visibility_container: VBoxContainer = $OuterMargin/ScrollContainer/InnerMargin/Content/PracticesContainer
@onready var _practices_container: VBoxContainer = $OuterMargin/ScrollContainer/InnerMargin/Content/PracticesContainer/Practices
@onready var _debounce_timer: Timer = $DebounceTimer
@onready var _glossary_popup := $GlossaryPopup
var _tweener: Tween

@onready var _start_content_width: float = _content_container.size.x


func _ready() -> void:
	Events.font_size_scale_changed.connect(_update_content_container_width)
	_update_content_container_width(UserProfiles.get_profile().font_size_scale)

	_scroll_container.get_v_scroll_bar().value_changed.connect(_on_content_scrolled)
	_debounce_timer.timeout.connect(_emit_read_content)

	
	_glossary = load("res://course/glossary.tres")

	if test_lesson and get_parent() == get_tree().root:
		var lesson := test_lesson as Lesson
		if lesson:
			setup(lesson, null)


	_scroll_container.grab_focus()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_labels()
		_underline_glossary_entries()


func setup(lesson: Lesson, course: Course) -> void:
	if not is_inside_tree():
		await ready

	_lesson = lesson
	_title.text = tr(_lesson.title)
	var user_profile := UserProfiles.get_profile()

	# If this was the last lesson the student interacted with before, we will try to restore
	# their reading position.
	var is_returning := false
	if course:
		var last_lesson := user_profile.get_last_started_lesson(course.resource_path)
		is_returning = _lesson.resource_path == last_lesson

	var restore_node: Control
	var restore_id := ""
	if course:
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
				course.resource_path, lesson.resource_path
			)

		var reading_done := user_profile.is_lesson_reading_completed(
			course.resource_path, lesson.resource_path
		)
		var reading_started := user_profile.has_lesson_blocks_read(
			course.resource_path, lesson.resource_path
		)
		if restore_id.is_empty() and not reading_done and reading_started:
			for block in lesson.content_blocks:
				var block_id := ""
				if block is Quiz:
					block_id = block.quiz_id
				else:
					block_id = block.content_id

				if user_profile.is_lesson_block_read(
					course.resource_path, lesson.resource_path, block_id
				):
					continue

				restore_id = block_id
				break

	for block in lesson.content_blocks:
		if block is ContentBlock:
			var content_block: ContentBlock = block

			var instance := ContentBlockScene.instantiate() as UIContentBlock
			instance.name = content_block.content_id.get_file().get_basename()
			_content_blocks.add_child(instance)
			instance.setup(content_block)
			instance.hide()

			if restore_id == block.content_id:
				restore_node = instance

		elif block is Quiz:
			var quiz: Quiz = block

			var scene: PackedScene = QuizInputFieldScene if quiz is QuizInputField else QuizChoiceScene
			var instance := scene.instantiate() as UIBaseQuiz
			instance.name = quiz.quiz_id.get_file().get_basename()
			_content_blocks.add_child(instance)
			instance.setup(quiz)
			instance.hide()

			var completed_before := false
			if course:
				completed_before = user_profile.is_lesson_quiz_completed(
					course.resource_path, lesson.resource_path, block.quiz_id
				)
				if completed_before:
					_quizzes_done += 1
			instance.completed_before = completed_before

			instance.quiz_passed.connect(
				Callable(self, "_on_quiz_passed").bind(quiz)
			)
			instance.quiz_passed.connect(Callable(self, "_reveal_up_to_next_quiz"))
			instance.quiz_skipped.connect(Callable(self, "_reveal_up_to_next_quiz"))

			if restore_id == block.quiz_id:
				restore_node = instance

	var highlighted_next := false
	var practice_index := 0
	for practice in lesson.practices:
		var button := PracticeButtonScene.instantiate() as UIPracticeButton
		button.setup(practice, practice_index)
		if course:
			button.completed_before = user_profile.is_lesson_practice_completed(
				course.resource_path, lesson.resource_path, practice.practice_id
			)
			if not highlighted_next and not button.completed_before:
				highlighted_next = true
				button.is_highlighted = true
		_practices_container.add_child(button)
		practice_index += 1
	_practices_visibility_container.hide()

	_quizz_count = lesson.get_quizzes_count()
	_reveal_up_to_next_quiz()

	if _integration_test_mode:
		await get_tree().process_frame
		emit_signal("lesson_displayed")
		return

	# Wait until the lesson is considered loaded by the system, and then update the size of
	# the scroll container and its content.
	await Events.lesson_started
	if restore_node and restore_node.is_visible_in_tree():
		var scroll_offset: float = abs(
		_scroll_content.global_position.y - _content_blocks.global_position.y
		)
		var scroll_target: float = restore_node.position.y + float(scroll_offset) - float(AUTOSCROLL_PADDING)


		if _tweener:
			_tweener.kill()

		_tweener = create_tween()
		_tweener.set_trans(Tween.TRANS_QUAD)
		_tweener.set_ease(Tween.EASE_IN_OUT)
		_tweener.tween_property(_scroll_container, "scroll_vertical", scroll_target, AUTOSCROLL_DURATION)

	_underline_glossary_entries()

	# Call this immediately to update for the blocks that are already visible.
	_emit_read_content()


func _underline_glossary_entries() -> void:
	_glossary.setup()
	# Underline glossary entries
	for n in get_tree().get_nodes_in_group("rich_text_label"):
		var rtl := n as RichTextLabel
		if rtl == null:
			continue
		rtl.bbcode_text = _glossary.replace_matching_terms(rtl.bbcode_text)

		var cb := Callable(self, "_open_glossary_popup")
		if not rtl.is_connected("meta_clicked", cb):
			rtl.connect("meta_clicked", cb)


func _update_labels() -> void:
	if not _lesson:
		return

	_title.text = tr(_lesson.title)


func get_screen_resource() -> Lesson:
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
		_scroll_content.global_position.y - _content_blocks.global_position.y
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

		if content_index < _lesson.content_blocks.size():
			content_blocks.append(_lesson.content_blocks[content_index])

		var content_offset: float = control_node.position.y
		if content_offset > scroll_distance:
			break
		content_index += 1

	if content_blocks.size() > 0:
		var last_block = content_blocks.pop_back()
		Events.emit_signal("lesson_reading_block", last_block, content_blocks)


func _update_content_container_width(new_font_scale: int) -> void:
	var font_size_multiplier := (
		float(_base_text_font_size + new_font_scale * 2)
		/ _base_text_font_size
	)
	_content_container.custom_minimum_size.x = _start_content_width * font_size_multiplier


func _on_translation_changed() -> void:
	_underline_glossary_entries()


func _open_glossary_popup(meta: String) -> void:
	var entry: Glossary.Entry = _glossary.get_match(meta)
	if entry == null:
		return
	_glossary_popup.setup(entry.term, entry.explanation)
	_glossary_popup.call_deferred("align_with_mouse", get_global_mouse_position())
	_glossary_popup.appear()
