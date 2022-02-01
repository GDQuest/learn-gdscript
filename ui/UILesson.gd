# Displays a Lesson ressource and a list a button to start each practice in a
# lesson.
#
# When pressing a practice button, emits an event so the navigation can
# transition to the practice screen.
class_name UILesson
extends Control

const ContentBlockScene := preload("screens/lesson/UIContentBlock.tscn")
const QuizInputFieldScene := preload("screens/lesson/quizzes/UIQuizInputField.tscn")
const QuizChoiceScene := preload("screens/lesson/quizzes/UIQuizChoice.tscn")
const PracticeButtonScene := preload("screens/lesson/UIPracticeButton.tscn")

const AUTOSCROLL_PADDING := 20
const AUTOSCROLL_DURATION := 0.24

export var test_lesson: Resource

var _lesson: Lesson
var _visible_index := -1
var _quizzes_done := -1 # Start with -1 because we will always autoincrement at least once.
var _quizz_count := 0

var _base_text_font_size := preload("res://ui/theme/fonts/font_text.tres").size

onready var _scroll_container := $OuterMargin/ScrollContainer as ScrollContainer
onready var _scroll_content := $OuterMargin/ScrollContainer/InnerMargin as Control
onready var _title := $OuterMargin/ScrollContainer/InnerMargin/Content/Title as Label
onready var _content_blocks := $OuterMargin/ScrollContainer/InnerMargin/Content/ContentBlocks as VBoxContainer
onready var _content_container := $OuterMargin/ScrollContainer/InnerMargin/Content as VBoxContainer
onready var _practices_visibility_container := (
	$OuterMargin/ScrollContainer/InnerMargin/Content/PracticesContainer as VBoxContainer
)
onready var _practices_container := (
	$OuterMargin/ScrollContainer/InnerMargin/Content/PracticesContainer/Practices as VBoxContainer
)
onready var _debounce_timer := $DebounceTimer as Timer
onready var _tweener := $Tween as Tween

onready var _start_content_width := _content_container.rect_size.x


func _ready() -> void:
	Events.connect("font_size_scale_changed", self, "_update_content_container_width")
	_update_content_container_width(UserProfiles.get_profile().font_size_scale)
	_scroll_container.get_v_scrollbar().connect("value_changed", self, "_on_content_scrolled")
	_debounce_timer.connect("timeout", self, "_emit_read_content")

	if test_lesson and get_parent() == get_tree().root:
		setup(test_lesson, null)
		for child in _content_blocks.get_children():
			child.show()
		_practices_container.show()

	_scroll_container.grab_focus()


func setup(lesson: Lesson, course: Course) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_lesson = lesson
	_title.text = lesson.title
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
			restore_id = user_profile.get_last_visited_lesson_block(course.resource_path, lesson.resource_path)

		var reading_done := user_profile.is_lesson_reading_completed(course.resource_path, lesson.resource_path)
		var reading_started := user_profile.has_lesson_blocks_read(course.resource_path, lesson.resource_path)
		if restore_id.empty() and not reading_done and reading_started:
			for block in lesson.content_blocks:
				var block_id := ""
				if block is Quiz:
					block_id = block.quiz_id
				else:
					block_id = block.content_id

				if user_profile.is_lesson_block_read(course.resource_path, lesson.resource_path, block_id):
					continue

				restore_id = block_id
				break

	for block in lesson.content_blocks:
		if block is ContentBlock:
			var instance: UIContentBlock = ContentBlockScene.instance()
			instance.name = block.content_id.get_file().get_basename()
			_content_blocks.add_child(instance)
			instance.setup(block)
			instance.hide()

			if restore_id == block.content_id:
				restore_node = instance

		elif block is Quiz:
			var scene = QuizInputFieldScene if block is QuizInputField else QuizChoiceScene
			var instance = scene.instance()
			instance.name = block.quiz_id.get_file().get_basename()
			_content_blocks.add_child(instance)
			instance.setup(block)
			instance.hide()

			var completed_before := false
			if course:
				completed_before = user_profile.is_lesson_quiz_completed(course.resource_path, lesson.resource_path, block.quiz_id)
				if completed_before:
					_quizzes_done += 1
			instance.completed_before = completed_before

			instance.connect("quiz_passed", Events, "emit_signal", ["quiz_completed", block])
			instance.connect("quiz_passed", self, "_reveal_up_to_next_quiz")
			instance.connect("quiz_skipped", self, "_reveal_up_to_next_quiz")

			if restore_id == block.quiz_id:
				restore_node = instance

	var highlighted_next := false
	for practice in lesson.practices:
		var button: UIPracticeButton = PracticeButtonScene.instance()
		button.setup(practice)
		if course:
			button.completed_before = user_profile.is_lesson_practice_completed(course.resource_path, lesson.resource_path, practice.practice_id)
			if not highlighted_next and not button.completed_before:
				highlighted_next = true
				button.is_highlighted = true
		_practices_container.add_child(button)
	_practices_visibility_container.hide()

	_quizz_count = lesson.get_quizzes_count()
	_reveal_up_to_next_quiz()

	# Wait until the lesson is considered loaded by the system, and then update the size of
	# the scroll container and its content.
	yield(Events, "lesson_started")
	if restore_node and restore_node.is_visible_in_tree():
		var scroll_offset = abs(_scroll_content.rect_global_position.y - _content_blocks.rect_global_position.y)
		var scroll_target = restore_node.rect_position.y + scroll_offset - AUTOSCROLL_PADDING
		_tweener.stop_all()
		_tweener.interpolate_method(
			_scroll_container,
			"set_v_scroll", # So it plays nice with our smooth scroller
			_scroll_container.scroll_vertical,
			scroll_target,
			AUTOSCROLL_DURATION,
			Tween.TRANS_QUAD,
			Tween.EASE_IN_OUT
		)
		_tweener.start()

	# Call this immediately to update for the blocks that are already visible.
	_emit_read_content()


func get_screen_resource() -> Lesson:
	return _lesson


func _reveal_up_to_next_quiz() -> void:
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
	var scroll_offset = abs(_scroll_content.rect_global_position.y - _content_blocks.rect_global_position.y)
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

		var content_offset := control_node.rect_position.y
		if content_offset > scroll_distance:
			break
		content_index += 1

	if content_blocks.size() > 0:
		var last_block = content_blocks.pop_back()
		Events.emit_signal("lesson_reading_block", last_block, content_blocks)


func _update_content_container_width(new_font_scale: int) -> void:
	var font_size_multiplier := float(_base_text_font_size + new_font_scale * 2) / _base_text_font_size
	_content_container.rect_min_size.x = _start_content_width * font_size_multiplier
