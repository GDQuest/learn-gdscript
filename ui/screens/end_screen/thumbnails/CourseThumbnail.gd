tool
extends Control

export var texture: StreamTexture = null setget set_texture
## Date in ISO 8601 format.
export var release_date := "" setget set_release_date
export var link := ""
export var text_scale := 1.0 setget set_text_scale

onready var _release_date_label: Label = $ReleaseDateLabel
onready var _texture_rect: TextureRect = $TextureRect

func _ready() -> void:
	_release_date_label.rect_pivot_offset = _release_date_label.rect_size / 2

func _get_configuration_warning() -> String:
	if texture == null:
		return "StreamTexture is not set."
	
	if link == "":
		return "URL to open on click is not set"
	
	if release_date == "":
		return "Release date is not set."
	elif release_date.length() != 20 or release_date[10] != "T" or release_date[19] != "Z":
		return "Release date must be in ISO 8601 format: YYYY-MM-DDThh:mm:ssZ"
	return ""


func _gui_input(event: InputEvent) -> void:
	if link != "" and event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		OS.shell_open(link)


func set_texture(value: StreamTexture) -> void:
	texture = value
	if not _texture_rect:
		yield(self, "ready")
	_texture_rect.texture = texture


func set_text_scale(value: float) -> void:
	text_scale = value
	if not _release_date_label:
		yield(self, "ready")
	_release_date_label.rect_scale = Vector2.ONE * value


func set_release_date(value: String) -> void:
	release_date = value
	if not _release_date_label:
		yield(self, "ready")
	var date := parse_date(value)
	_release_date_label.visible = is_release_date_in_the_future(date)
	_release_date_label.text = "Early Access release: %04d/%02d/%02d" % [
		date.year,
		date.month,
		date.day,
	]


func is_release_date_in_the_future(date: Dictionary) -> bool:
	var today := OS.get_datetime(true)
	return (date.year > today.year or date.month > today.month or date.day > today.day or \
		date.hour > today.hour or date.minute > today.minute or date.second > today.second)


## Parses a date in ISO 8601 format.
func parse_date(iso_date: String) -> Dictionary:
	var date := iso_date.split("T")[0].split("-")
	var time := iso_date.split("T")[1].trim_suffix("Z").split(":")

	return {
		year = date[0].to_int(),
		month = date[1].to_int(),
		day = date[2].to_int(),
		hour = time[0].to_int(),
		minute = time[1].to_int(),
		second = time[2].to_int(),
	}
