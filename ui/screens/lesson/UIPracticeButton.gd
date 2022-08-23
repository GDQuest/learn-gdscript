class_name UIPracticeButton
extends Node

var completed_before := false setget set_completed_before
var is_highlighted := false setget set_is_highlighted
var navigation_disabled := false setget set_navigation_disabled

var _practice: Practice

onready var _title_label := $Margin/Row/Column/Row/Title as Label
onready var _next_pill_label := $Margin/Row/Column/Row/NextPill as Label
onready var _description_label := $Margin/Row/Column/Description as RichTextLabel
onready var _completed_before_icon := $Margin/Row/Column/Row/CompletedBeforeIcon as TextureRect
onready var _navigate_button := $Margin/Row/NavigateButton as Button
onready var _no_navigation_label := $Margin/Row/NoNavigationLabel as Label


func _ready() -> void:
	_completed_before_icon.visible = completed_before


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_labels()


func setup(practice: Practice, practice_index: int) -> void:
	_practice = practice
	
	if not is_inside_tree():
		yield(self, "ready")

	_title_label.text = "%d. %s" % [practice_index + 1, tr(_practice.title).capitalize()]
	_description_label.bbcode_text = tr(_practice.description)
	_description_label.visible = not _practice.description.empty()
	_navigate_button.connect("pressed", Events, "emit_signal", ["practice_requested", _practice])


func _update_labels() -> void:
	if not _practice:
		return
	
	_title_label.text = tr(_practice.title).capitalize()
	_description_label.bbcode_text = tr(_practice.description)


func set_completed_before(value: bool) -> void:
	completed_before = value
	if not _completed_before_icon:
		yield(self, "ready")

	_completed_before_icon.visible = completed_before


func set_is_highlighted(value: bool) -> void:
	is_highlighted = value

	if not is_inside_tree():
		yield(self, "ready")
	
	_next_pill_label.visible = is_highlighted


func set_navigation_disabled(value: bool) -> void:
	navigation_disabled = value
	
	if not is_inside_tree():
		yield(self, "ready")
	
	_navigate_button.visible = not navigation_disabled
	_no_navigation_label.visible = navigation_disabled
	
