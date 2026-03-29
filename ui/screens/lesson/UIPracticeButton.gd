@tool
class_name UIPracticeButton
extends Node

var completed_before := false:
	set = set_completed_before
var is_highlighted := false:
	set = set_is_highlighted
var navigation_disabled := false:
	set = set_navigation_disabled

var _practice: BBCodeParser.ParseNode

@export var _title_label: Label
@export var _next_pill_label: Label
@export var _description_label: RichTextLabel
@export var _completed_before_icon: TextureRect
@export var _navigate_button: Button
@export var _no_navigation_label: Label


func _ready() -> void:
	_completed_before_icon.visible = completed_before


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_labels()


func setup(practice: BBCodeParser.ParseNode, practice_index: int) -> void:
	_practice = practice

	if not is_inside_tree():
		await self.ready

	var title := BBCodeUtils.get_practice_title(practice)
	_title_label.text = "%d. %s" % [practice_index + 1, tr(title).capitalize()]

	var description := BBCodeUtils.get_practice_description(practice)
	_description_label.text = TextUtils.tr_paragraph(description)
	_description_label.visible = not description.is_empty()
	_navigate_button.pressed.connect(Events.practice_requested.emit.bind(_practice))


func _update_labels() -> void:
	if not _practice:
		return

	var title := BBCodeUtils.get_practice_title(_practice)
	_title_label.text = tr(title).capitalize()
	var description := BBCodeUtils.get_practice_description(_practice)
	_description_label.text = TextUtils.tr_paragraph(description)


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
