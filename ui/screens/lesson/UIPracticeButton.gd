@tool
class_name UIPracticeButton
extends Node

signal screen_entered

var completed_before := false:
	set = set_completed_before
var is_highlighted := false:
	set = set_is_highlighted
var navigation_disabled := false:
	set = set_navigation_disabled

var _practice: BBCodeParser.ParseNode
var _practice_index := 0
var _lesson_number := 0

@onready var _visibility_notifier: VisibleOnScreenEnabler2D = %VisibleOnScreenEnabler2D
@onready var _title_label: Label = %Title
@onready var _next_pill_label: Label = %NextPill
@onready var _description_label: RichTextLabel = %Description
@onready var _completed_before_icon: TextureRect = %CompletedBeforeIcon
@onready var _navigate_button: Button = %NavigateButton
@onready var _no_navigation_label: Label = %NoNavigationLabel


func _ready() -> void:
	_completed_before_icon.visible = completed_before
	_visibility_notifier.screen_entered.connect(screen_entered.emit)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_labels()


func setup(practice: BBCodeParser.ParseNode, practice_index: int, lesson_number: int) -> void:
	assert(lesson_number > 0, "lesson_number must be a positive integer")
	_practice = practice
	_practice_index = practice_index
	_lesson_number = lesson_number

	if not is_inside_tree():
		await self.ready

	var title := BBCodeUtils.get_practice_title(practice)
	_title_label.text = "L%d.P%d %s" % [lesson_number, practice_index + 1, tr(title).capitalize()]

	var description := BBCodeUtils.get_practice_description(practice)
	_description_label.text = TextUtils.paragraph(description)
	_description_label.visible = not description.is_empty()
	_navigate_button.pressed.connect(Events.practice_requested.emit.bind(_practice))


func _update_labels() -> void:
	if not _practice:
		return

	var rtl := TranslationManager.current_translation_is_rtl()

	var title := BBCodeUtils.get_practice_title(_practice)
	_title_label.text = "L%d.P%d %s" % [_lesson_number, _practice_index + 1, tr(title).capitalize()]
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if rtl else HORIZONTAL_ALIGNMENT_LEFT
	var description := BBCodeUtils.get_practice_description(_practice)
	_description_label.text = TextUtils.paragraph(description)
	_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if rtl else HORIZONTAL_ALIGNMENT_LEFT


func set_completed_before(value: bool) -> void:
	completed_before = value
	if not _completed_before_icon:
		await self.ready

	_completed_before_icon.visible = completed_before


func set_is_highlighted(value: bool) -> void:
	is_highlighted = value

	if not is_inside_tree():
		await self.ready

	_next_pill_label.visible = is_highlighted


func set_navigation_disabled(value: bool) -> void:
	navigation_disabled = value

	if not is_inside_tree():
		await self.ready

	_navigate_button.visible = not navigation_disabled
	_no_navigation_label.visible = navigation_disabled
