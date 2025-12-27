@tool
extends Control

@export var texture: Texture2D = null: 
	set = set_texture

## Date in ISO 8601 format.
@export var release_date: String = "": 
	set = set_release_date

@export var link: String = ""

@export var text_scale: float = 1.0: 
	set = set_text_scale

@onready var _release_date_label: Label = $ReleaseDateLabel
@onready var _texture_rect: TextureRect = $TextureRect

func _ready() -> void:
	# rect_pivot_offset -> pivot_offset
	# rect_size -> size
	_release_date_label.pivot_offset = _release_date_label.size / 2

# Godot 4: plural name, returns PackedStringArray
func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	
	if texture == null:
		warnings.append("Texture2D is not set.")
	
	if link == "":
		warnings.append("URL to open on click is not set")
	
	if release_date == "":
		warnings.append("Release date is not set.")
	elif release_date.length() != 20 or release_date[10] != "T" or release_date[19] != "Z":
		warnings.append("Release date must be in ISO 8601 format: YYYY-MM-DDThh:mm:ssZ")
		
	return warnings


func _gui_input(event: InputEvent) -> void:
	# 1. Cast the event to the specific type we need
	var mouse_event := event as InputEventMouseButton
	
	# 2. Check if the cast succeeded AND the other conditions
	if mouse_event and link != "" and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		OS.shell_open(link)


func set_texture(value: Texture2D) -> void:
	texture = value
	if not is_node_ready():
		await ready
	if _texture_rect:
		_texture_rect.texture = texture


func set_text_scale(value: float) -> void:
	text_scale = value
	if not is_node_ready():
		await ready
	if _release_date_label:
		# rect_scale -> scale
		_release_date_label.scale = Vector2.ONE * value


func set_release_date(value: String) -> void:
	release_date = value
	if not is_node_ready():
		await ready
	
	if _release_date_label:
		var date := parse_date(value)
		_release_date_label.visible = is_release_date_in_the_future(date)
		_release_date_label.text = "Early Access release: %04d/%02d/%02d" % [
			date.year,
			date.month,
			date.day,
		]


func is_release_date_in_the_future(date_dict: Dictionary) -> bool:
	# OS.get_datetime is deprecated. Use Time singleton.
	# The most reliable way to compare dates is using Unix timestamps (Epoch).
	var target_time := Time.get_unix_time_from_datetime_dict(date_dict)
	var current_time := Time.get_unix_time_from_system()
	return target_time > current_time


## Parses a date in ISO 8601 format.
func parse_date(iso_date: String) -> Dictionary:
	# Safety check for empty strings in tool mode
	if iso_date.length() < 20:
		return {year=0, month=0, day=0, hour=0, minute=0, second=0}
		
	var parts := iso_date.split("T")
	var date_parts := parts[0].split("-")
	var time_parts := parts[1].trim_suffix("Z").split(":")

	return {
		"year": int(date_parts[0]),
		"month": int(date_parts[1]),
		"day": int(date_parts[2]),
		"hour": int(time_parts[0]),
		"minute": int(time_parts[1]),
		"second": int(time_parts[2]),
	}
