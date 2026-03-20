extends Node

const THEME_ROOT := "res://ui/theme/"
const THEME_FONTS_ROOT := "res://ui/theme/fonts/"

const COLOR_TEXT_DEFAULT := Color(0.960784, 0.980392, 0.980392)
const COLOR_TEXT_LOWER_CONTRAST := Color(0.736288, 0.728113, 0.839844)

@onready var _theme = preload("res://ui/theme/gdscript_app_theme.tres")

var _font_defaults := {}


func _ready() -> void:
	_cache_font_defaults()
	
	var current_profile := UserProfiles.get_profile()
	scale_all_font_sizes(current_profile.font_size_scale, false)
	set_lower_contrast(current_profile.lower_contrast, false)
	set_dyslexia_font(current_profile.dyslexia_font, false)


func _cache_font_defaults() -> void:
	_font_defaults.clear()
	
	var fs := DirAccess.open(THEME_FONTS_ROOT)
	if not fs:
		printerr("Failed to open theme fonts directory at '%s': Error code %d" % [THEME_FONTS_ROOT, DirAccess.get_open_error()])
		return
	
	for file in fs.get_files():
		if file.get_extension() != "tres":
			continue
		
		var font_resource := ResourceLoader.load(THEME_FONTS_ROOT.path_join(file)) as FontFile
		if not font_resource:
			continue
		
		_font_defaults[font_resource] = {"size": font_resource.msdf_size, "font": font_resource.resource_path}


func scale_all_font_sizes(size_scale: int, and_save: bool = true) -> void:
	for font_resource in _font_defaults:
		font_resource = font_resource as FontFile
		if not font_resource:
			continue
		
		var default_size = int(_font_defaults[font_resource]["size"])
		# Each scale unit equals 2 points of font size.
		# TODO: godot 3 to 4: handle font sizes
		#font_resource.size = default_size + size_scale * 2
	
	if and_save:
		var current_profile := UserProfiles.get_profile()
		current_profile.font_size_scale = size_scale
		current_profile.save()
		Events.emit_signal("font_size_scale_changed", size_scale)


func set_lower_contrast(lower_contrast: bool, and_save: bool = true) -> void:
	var color := COLOR_TEXT_LOWER_CONTRAST if lower_contrast else COLOR_TEXT_DEFAULT
	_theme.set_color("font_color", "Label", color)
	_theme.set_color("default_color", "RichTextLabel", color)

	if and_save:
		var current_profile := UserProfiles.get_profile()
		current_profile.lower_contrast = lower_contrast
		current_profile.save()


func set_dyslexia_font(dyslexia_font: bool, and_save: bool = true) -> void:
	for font_resource in _font_defaults:
		font_resource = font_resource as FontFile
		if not font_resource:
			continue

		if dyslexia_font:
			font_resource.size -= (font_resource.size * 0.25)
			if "SourceCodePro" in font_resource.font_data.font_path:
				font_resource.font_data = load("res://ui/theme/fonts/OpenDyslexicMono-Regular.otf")
			elif "Regular" in font_resource.font_data.font_path:
				font_resource.font_data = load("res://ui/theme/fonts/OpenDyslexic-Regular.otf")
			elif "Bold" in font_resource.font_data.font_path:
				font_resource.font_data = load("res://ui/theme/fonts/OpenDyslexic-Bold.otf")
			elif "Italic" in font_resource.font_data.font_path:
				font_resource.font_data = load("res://ui/theme/fonts/OpenDyslexic-Italic.otf")
		else:
			font_resource.font_data = load(_font_defaults[font_resource]["font"])
	
	if and_save:
		var current_profile := UserProfiles.get_profile()
		current_profile.dyslexia_font = dyslexia_font
		current_profile.save()
