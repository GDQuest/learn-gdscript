tool
extends ColorRect

# regex pattern used to convert end_datetime_iso to _end_datetime
const REGEX_PATTERN_DATETIME := "(?<year>\\d{4})-(?<month>\\d{2})-(?<day>\\d{2})T(?<hour>\\d{2}):(?<minute>\\d{2})"

export var title := "" setget set_title
# String displayed on the label after "Only until"
export var only_until_string := "" setget set_only_until_string
# Datetime string in ISO format to end the sale. After this date, the banner will not show anymore.
export var end_datetime_iso := "2020-01-01T00:00"
# Web page to open when clicking the button
export var sale_url := ""

var _end_datetime := {year = 2022, month = 12, day = 1, hour = 0, minute = 0}
var _datetime_regex := RegEx.new()

onready var title_label := $PanelContainer/Layout/Margin/Column/Title as Label
onready var time_left_label := $PanelContainer/Layout/Margin/Column/TimeLeftLabel as Label
onready var go_button := $PanelContainer/Layout/Margin/Column/GoButton as Button
onready var close_button := $PanelContainer/Control/CloseButton as Button


func _ready() -> void:
	set_title(title)
	set_only_until_string(only_until_string)
	go_button.connect("pressed", self, "_open_sale_url")
	close_button.connect("pressed", self, "hide")
	if get_tree().current_scene != self:
		hide()

	_datetime_regex.compile(REGEX_PATTERN_DATETIME)
	var re_match := _datetime_regex.search(end_datetime_iso)
	assert(
		re_match.get_group_count() == 5,
		"Invalid datetime string. It should have the form 'yyyy-mm-ddThh:mm'"
	)
	var keys := _end_datetime.keys()
	for i in keys.size():
		_end_datetime[keys[i]] = re_match.get_string(i + 1).to_int()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		hide()


func _get_configuration_warning() -> String:
	if not (sale_url.begins_with("http") or sale_url.begins_with("//")):
		return "Missing sale URL. Clicking the button will not open any page."
	if not title:
		return "Missing title! The popup will look off."
	if not only_until_string:
		return "Missing end date! The popup will look off."
	return ""


func set_title(new_title: String) -> void:
	title = new_title
	if title_label:
		title_label.text = new_title


func set_only_until_string(new_date: String) -> void:
	only_until_string = new_date
	if time_left_label:
		time_left_label.text = "Only until " + new_date


func is_sale_over() -> bool:
	var datetime := OS.get_datetime(true)

	if datetime.year > _end_datetime.year:
		return true
	if datetime.year < _end_datetime.year:
		return false
	if datetime.month > _end_datetime.month:
		return true
	if datetime.month == _end_datetime.month and datetime.day > _end_datetime.day:
		return true
	if datetime.day < _end_datetime.day:
		return false
	if datetime.hour > _end_datetime.hour:
		return true
	if datetime.hour == _end_datetime.hour and datetime.minute > _end_datetime.minute:
		return true

	return false


func _open_sale_url() -> void:
	OS.shell_open(sale_url)
