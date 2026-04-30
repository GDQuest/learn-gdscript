# Displays a Lesson ressource and a list a button to start each practice in a
# lesson.
#
# When pressing a practice button, emits an event so the navigation can
# transition to the practice screen.
class_name UILesson
extends UINavigatablePage

const QuizInputFieldScene := preload("screens/lesson/quizzes/UIQuizInputField.tscn")
const QuizChoiceScene := preload("screens/lesson/quizzes/UIQuizChoice.tscn")
const PracticeButtonScene := preload("screens/lesson/UIPracticeButton.tscn")
const RevealerScene := preload("res://ui/components/Revealer.tscn")

const GlossaryPopup := preload("res://ui/components/GlossaryPopup.gd")

const AUTOSCROLL_PADDING := 20
const AUTOSCROLL_DURATION := 0.24
const HEADER_FONT := "res://ui/theme/fonts/font_lesson_heading.tres"

const COLOR_NOTE := Color(0.14902, 0.776471, 0.968627)

@export var test_lesson: String
@export var _scroll_container: ScrollContainer
@export var _title: Label
@export var _content_blocks: VBoxContainer
@export var _content_container: VBoxContainer
@export var _practices_visibility_container: VBoxContainer
@export var _practices_container: VBoxContainer
@export var _debounce_timer: Timer
@export var _glossary_popup: GlossaryPopup

signal lesson_displayed

var _lesson: BBCodeParser.ParseNode
var _course_index: CourseIndex
var _visible_index := -1
var _quizzes_done := -1 # Start with -1 because we will always autoincrement at least once.
var _quizz_count := 0
var _integration_test_mode := false
var _previous_paragraph: RichTextLabel

var _build_commands := {
	BBCodeParserData.Tag.TITLE: _make_title,
	BBCodeParserData.Tag.PARAGRAPH: _make_paragraph,
	BBCodeParserData.Tag.NOTE: _make_note,
	BBCodeParserData.Tag.QUIZ_CHOICE: _make_quiz,
	BBCodeParserData.Tag.QUIZ_INPUT: _make_quiz,
	BBCodeParserData.Tag.SEPARATOR: _make_separator,
	BBCodeParserData.Tag.VISUAL: _make_visual,
}

var _base_text_font_size: int = preload("res://ui/theme/fonts/font_text.tres").base_font.msdf_size

@onready var _start_content_width := _content_container.size.x


func _ready() -> void:
	super._ready()

	Events.font_size_scale_changed.connect(_update_content_container_width)
	_update_content_container_width(UserProfiles.get_profile().font_size_scale)
	_scroll_container.get_v_scroll_bar().value_changed.connect(_on_content_scrolled)

	if test_lesson and get_parent() == get_tree().root:
		var _lesson_node := NavigationManager.get_navigation_resource(test_lesson)
		var test_course_index: CourseIndex = CourseIndexPaths.get_course_index_instance()
		var lesson_number := test_course_index.get_lesson_number(_lesson_node.bbcode_path)
		setup(_lesson_node, test_course_index, lesson_number)
		for child: Control in _content_blocks.get_children():
			child.show()
		_practices_container.show()

	_scroll_container.grab_focus()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_labels()


func setup(lesson: BBCodeParser.ParseNode, course_index: CourseIndex, lesson_number: int) -> void:
	if not is_inside_tree():
		await self.ready

	_lesson = lesson
	_course_index = course_index
	_title.text = tr(BBCodeUtils.get_lesson_title(lesson))
	var user_profile := UserProfiles.get_profile()

	for child_node: BBCodeParser.ParseNode in lesson.children:
		var node_type := child_node.tag
		if _build_commands.has(node_type):
			var new_instance: CanvasItem = (_build_commands[node_type] as Callable).call(child_node, course_index, lesson, user_profile)
			if new_instance and new_instance.get_parent() != _content_blocks:
				_content_blocks.add_child(new_instance)
				new_instance.hide()

	var highlighted_next := false
	var practice_count := BBCodeUtils.get_lesson_practice_count(lesson)
	for i in practice_count:
		var practice := BBCodeUtils.get_lesson_practice(lesson, i)
		var practice_id := BBCodeUtils.get_practice_id(practice)
		var button: UIPracticeButton = PracticeButtonScene.instantiate()
		button.setup(practice, i, lesson_number)
		if i == 0:
			button.visibility_notifier.screen_entered.connect(_on_practice_first_visible)
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
		lesson_displayed.emit()
		return

	# Wait until the lesson is considered loaded by the system, and then update the size of
	# the scroll container and its content.
	await Events.lesson_started


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
		for child: Control in _content_blocks.get_children():
			child.show()
		_practices_visibility_container.show()
		_quizzes_done = _quizz_count
		lesson_displayed.emit()
		return

	_quizzes_done += 1

	var child_count := _content_blocks.get_child_count()
	while _visible_index < child_count - 1:
		_visible_index += 1

		var child: Control = _content_blocks.get_child(_visible_index)
		child.show()

		if child is UIBaseQuiz and not (child as UIBaseQuiz).completed_before:
			break

	if _visible_index >= child_count - 1 and _quizzes_done >= _quizz_count:
		_practices_visibility_container.show()


func _on_content_scrolled(_value: float) -> void:
	_debounce_timer.start()


func _update_content_container_width(new_font_scale: int) -> void:
	var font_size_multiplier := (
		float(_base_text_font_size + new_font_scale * 2)
		/ _base_text_font_size
	)
	_content_container.custom_minimum_size.x = _start_content_width * font_size_multiplier


func _open_glossary_popup(meta: String) -> void:
	var entry: Glossary.Entry = TextUtils.get_glossary().get_match(meta)
	if entry == null:
		return
	_glossary_popup.setup(entry.term, entry.explanation)
	_glossary_popup.align_with_mouse.call_deferred(get_global_mouse_position())
	_glossary_popup.appear.call_deferred()


func _make_paragraph(node: BBCodeParser.ParseNode, _target_course_index: CourseIndex, _target_lesson: BBCodeParser.ParseNode, _user_profile: Profile) -> CanvasItem:
	var instance: RichTextLabel = _previous_paragraph
	if not _previous_paragraph:
		instance = RichTextLabel.new()
		instance.fit_content = true
		instance.scroll_active = false
		instance.bbcode_enabled = true
		instance.selection_enabled = true
		instance.meta_clicked.connect(_open_glossary_popup)
		_previous_paragraph = instance
	
	var text_content := BBCodeUtils.get_paragraph_text(node)
	instance.text += TextUtils.bbcode_add_code_color(TextUtils.tr_paragraph(text_content))
	
	return instance


func _make_note(node: BBCodeParser.ParseNode, _target_course_index: CourseIndex, _target_lesson: BBCodeParser.ParseNode, _user_profile: Profile) -> CanvasItem:
	var revealer := RevealerScene.instantiate() as Revealer
	revealer.title_panel = preload("res://ui/theme/styles/revealer_notes_title.tres")
	revealer.title_panel_expanded = preload("res://ui/theme/styles/revealer_notes_title_expanded.tres")
	revealer.content_panel = preload("res://ui/theme/styles/revealer_notes_panel.tres")

	revealer.title_font_color = COLOR_NOTE
	var title := BBCodeUtils.get_note_title(node)
	revealer.title = tr("Learn More") if title.is_empty() else tr(title)

	_content_blocks.add_child(revealer)
	revealer.add_child(_make_paragraph(node, _course_index, _lesson, _user_profile))
	_previous_paragraph = null
	return revealer


func _make_title(node: BBCodeParser.ParseNode, _target_course_index: CourseIndex, _target_lesson: BBCodeParser.ParseNode, _user_profile: Profile) -> CanvasItem:
	var instance: RichTextLabel = _previous_paragraph
	if _previous_paragraph == null:
		instance = RichTextLabel.new()
	var text_content := BBCodeUtils.get_paragraph_text(node)
	instance.text += "\n\n[font size=28 name='%s']%s[/font]\n\n" % [HEADER_FONT, TextUtils.tr_paragraph(text_content)]
	return instance


func _make_quiz(node: BBCodeParser.ParseNode, course_index: CourseIndex, lesson: BBCodeParser.ParseNode, user_profile: Profile) -> CanvasItem:
	var scene := (
		QuizChoiceScene if node.tag == BBCodeParserData.Tag.QUIZ_CHOICE
		else QuizInputFieldScene
	)
	var instance: UIBaseQuiz = scene.instantiate()
	var quiz_id := BBCodeUtils.get_quiz_id(node)
	instance.setup(node)

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

	instance.quiz_passed.connect(Events.quiz_completed.emit.bind(node))
	instance.quiz_passed.connect(_reveal_up_to_next_quiz)
	instance.quiz_skipped.connect(_reveal_up_to_next_quiz)
	_previous_paragraph = null
	return instance


func _make_separator(_node: BBCodeParser.ParseNode, _target_course_index: CourseIndex, _target_lesson: BBCodeParser.ParseNode, _user_profile: Profile) -> CanvasItem:
	if _previous_paragraph:
		_previous_paragraph.text += "\n[hr]\n"
		return _previous_paragraph
	else:
		var instance := HSeparator.new()
		return instance


func _make_visual(node: BBCodeParser.ParseNode, _target_course_index: CourseIndex, _target_lesson: BBCodeParser.ParseNode, _user_profile: Profile) -> CanvasItem:
	var instance: CanvasItem = null
	var path := BBCodeUtils.get_visual_path(node)
	if path.is_empty():
		return null

	# If the path isn't absolute, we try to load the file from the current directory
	if path.is_relative_path():
		path = (node.bbcode_path as String).get_base_dir().path_join(path)
	var resource := load(path)
	if not resource:
		printerr(
			(
				"ContentBlock visual element is not a valid resource. From path: "
				+ path
			),
		)
		return

	if resource is Texture2D:
		var texture_rect := TextureRect.new()
		instance = texture_rect
		texture_rect.texture = resource
	elif resource is PackedScene:
		instance = (resource as PackedScene).instantiate()
	else:
		printerr(
			(
				"ContentBlock visual element is not a Texture2D or a PackedScene. Loaded type: "
				+ resource.get_class() + " From path: "
				+ path
			),
		)
		return null
	_previous_paragraph = null
	return instance


func _on_practice_first_visible() -> void:
	Events.lesson_read.emit(_lesson)
