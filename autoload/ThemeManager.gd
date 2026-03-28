extends Node

const THEME_ROOT := "res://ui/theme/"
const THEME_FONTS_ROOT := "res://ui/theme/fonts/"

const COLOR_TEXT_DEFAULT := Color(0.960784, 0.980392, 0.980392)
const COLOR_TEXT_LOWER_CONTRAST := Color(0.736288, 0.728113, 0.839844)

var _font_defaults := {}
var _font_sizes := {}

@onready var _theme: Theme = preload("res://ui/theme/gdscript_app_theme.tres")


func _ready() -> void:
	_cache_font_defaults()
	
	var current_profile := UserProfiles.get_profile()
	scale_all_font_sizes(current_profile.font_size_scale, false)
	set_lower_contrast(current_profile.lower_contrast, false)
	set_dyslexia_font(current_profile.dyslexia_font, false)


func get_default_font_size() -> int:
	return _font_sizes["Label"]["font_size"]


func _cache_font_defaults() -> void:
	_font_defaults.clear()
	
	var fs := DirAccess.open(THEME_FONTS_ROOT)
	if not fs:
		printerr("Failed to open theme fonts directory at '%s': Error code %d" % [THEME_FONTS_ROOT, DirAccess.get_open_error()])
		return
	
	for file in fs.get_files():
		match file.get_extension():
			"remap":
				file = file.substr(0, file.length() - 6)
			"tres":
				pass
			_:
				continue
		
		var font_resource := ResourceLoader.load(THEME_FONTS_ROOT.path_join(file)) as FontVariation
		if not font_resource:
			continue
		
		_font_defaults[font_resource] = font_resource.base_font.resource_path
	
	for type in _theme.get_font_size_type_list():
		var sizes := {}
		for font_size_name in _theme.get_font_size_list(type):
			sizes[font_size_name] = _theme.get_font_size(font_size_name, type)
		_font_sizes[type] = sizes
	if not _font_sizes.has("Label"):
		_font_sizes["Label"] = {"font_size" = _theme.default_font_size}


func scale_all_font_sizes(size_scale: int, and_save: bool = true) -> void:
	for theme_type in _font_sizes:
		var font_size_set := _font_sizes[theme_type] as Dictionary
		
		for font_size_name in font_size_set:
			var default_size: int = font_size_set[font_size_name]
			_theme.set_font_size(font_size_name, theme_type, default_size + size_scale * 2)
	_theme.default_font_size = get_default_font_size() + size_scale * 2
	
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
	for font_resource: FontVariation in _font_defaults:
		if not font_resource:
			continue

		if dyslexia_font:
			if "SourceCodePro" in font_resource.base_font.resource_path:
				font_resource.base_font = load("res://ui/theme/fonts/OpenDyslexicMono-Regular.otf")
			elif "Regular" in font_resource.base_font.resource_path:
				font_resource.base_font = load("res://ui/theme/fonts/OpenDyslexic-Regular.otf")
			elif "BoldItalic" in font_resource.base_font.resource_path:
				font_resource.base_font = load("res://ui/theme/fonts/OpenDyslexic-Bold-Italic.otf")
			elif "Bold" in font_resource.base_font.resource_path:
				font_resource.base_font = load("res://ui/theme/fonts/OpenDyslexic-Bold.otf")
			elif "Italic" in font_resource.base_font.resource_path:
				font_resource.base_font = load("res://ui/theme/fonts/OpenDyslexic-Italic.otf")
		else:
			font_resource.base_font = load(_font_defaults[font_resource])
	
	var current_profile := UserProfiles.get_profile()
	var current_scale := current_profile.font_size_scale
	for theme_type in _font_sizes:
		var font_size_set := _font_sizes[theme_type] as Dictionary
		
		for font_size_name in font_size_set:
			var default_size: int = font_size_set[font_size_name]
			var scaled_size := default_size + current_scale * 2
			
			_theme.set_font_size(font_size_name, theme_type, scaled_size - scaled_size * (0.25 if dyslexia_font else 0.0))
	var default_theme_size: int = get_default_font_size()
	var scaled_theme_size := default_theme_size + current_scale * 2
	_theme.default_font_size = scaled_theme_size - scaled_theme_size * (0.25 if dyslexia_font else 0.0)
	
	if and_save:
		current_profile.dyslexia_font = dyslexia_font
		current_profile.save()
