@tool
extends Control

@export var texture: CompressedTexture2D = null:
	set = set_texture
## Date in ISO 8601 format.
@export var release_date := "":
	set = set_release_date
@export var link := ""
@export var text_scale := 1.0:
	set = set_text_scale

@onready var _release_date_label: Label = $ReleaseDateLabel
@onready var _texture_rect: TextureRect = $TextureRect


func _ready() -> void:
	_release_date_label.pivot_offset = _release_date_label.size / 2


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if texture == null:
		warnings.push_back("CompressedTexture2D is not set.")

	if link == "":
		warnings.push_back("URL to open on click is not set")

	if release_date == "":
		warnings.push_back("Release date is not set.")
	elif release_date.length() != 20 or release_date[10] != "T" or release_date[19] != "Z":
		warnings.push_back("Release date must be in ISO 8601 format: YYYY-MM-DDThh:mm:ssZ")
	return warnings


func _gui_input(event: InputEvent) -> void:
	if link != "" and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		OS.shell_open(link)


func set_texture(value: CompressedTexture2D) -> void:
	texture = value
	if not _texture_rect:
		await self.ready
	_texture_rect.texture = texture


func set_text_scale(value: float) -> void:
	text_scale = value
	if not _release_date_label:
		await self.ready
	_release_date_label.scale = Vector2.ONE * value


func set_release_date(value: String) -> void:
	release_date = value
	if not _release_date_label:
		await self.ready
	var date := parse_date(value)
	_release_date_label.visible = is_release_date_in_the_future(date)
	_release_date_label.text = "Early Access release: %04d/%02d/%02d" % [
		date.year,
		date.month,
		date.day,
	]


func is_release_date_in_the_future(date: Dictionary) -> bool:
	var today := Time.get_datetime_dict_from_system(true)
	return (date.year > today.year or date.month > today.month or date.day > today.day or \
		date.hour > today.hour or date.minute > today.minute or date.second > today.second )


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
