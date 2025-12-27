extends Node

const THEME_ROOT := "res://ui/theme/"
const THEME_TYPES: Array[String] = ["Label", "Button", "LineEdit", "TextEdit", "RichTextLabel", "CheckBox", "ItemList"]

const COLOR_TEXT_DEFAULT := Color(0.960784, 0.980392, 0.980392)
const COLOR_TEXT_LOWER_CONTRAST := Color(0.736288, 0.728113, 0.839844)

@onready var _theme: Theme = preload("res://ui/theme/gdscript_app_theme.tres")

var _theme_defaults: Dictionary = {}

func _ready() -> void:
	_cache_theme_defaults()
	
	var current_profile = UserProfiles.get_profile()
	
	# Fix for lines 20-22: Cast the Variant to the target type before passing to functions
	var scale_val: float = current_profile.font_size_scale as float
	var contrast_val: bool = current_profile.lower_contrast as bool
	var dyslexia_val: bool = current_profile.dyslexia_font as bool
	
	scale_all_font_sizes(roundi(scale_val), false)
	set_lower_contrast(contrast_val, false)
	set_dyslexia_font(dyslexia_val, false)

func _cache_theme_defaults() -> void:
	_theme_defaults.clear()
	for type: String in THEME_TYPES:
		_theme_defaults[type] = {
			"size": _theme.get_font_size("font_size", type),
			"font": _theme.get_font("font", type)
		}

func scale_all_font_sizes(size_scale: int, and_save: bool = true) -> void:
	for type: String in THEME_TYPES:
		if not _theme_defaults.has(type): continue
		
		var default_size: int = _theme_defaults[type]["size"] as int
		var new_size: int = default_size + (size_scale * 2)
		_theme.set_font_size("font_size", type, new_size)
	
	if and_save:
		var current_profile = UserProfiles.get_profile()
		current_profile.font_size_scale = size_scale
		current_profile.save()
		if Events.has_signal("font_size_scale_changed"):
			Events.emit_signal("font_size_scale_changed", size_scale)

func set_lower_contrast(lower_contrast: bool, and_save: bool = true) -> void:
	var color := COLOR_TEXT_LOWER_CONTRAST if lower_contrast else COLOR_TEXT_DEFAULT
	
	for type: String in ["Label", "RichTextLabel", "CheckBox"]:
		if _theme.has_color("font_color", type):
			_theme.set_color("font_color", type, color)
	
	if _theme.has_color("default_color", "RichTextLabel"):
		_theme.set_color("default_color", "RichTextLabel", color)

	if and_save:
		var current_profile = UserProfiles.get_profile()
		current_profile.lower_contrast = lower_contrast
		current_profile.save()

func set_dyslexia_font(dyslexia_font: bool, and_save: bool = true) -> void:
	for type: String in THEME_TYPES:
		if not _theme_defaults.has(type): continue
		
		# Explicitly type the Font variable
		var base_font: Font = _theme_defaults[type]["font"] as Font
		
		if dyslexia_font:
			var path := ""
			if base_font is FontVariation:
				var variation := base_font as FontVariation
				if variation.base_font != null:
					path = variation.base_font.resource_path
			elif base_font is FontFile:
				path = (base_font as FontFile).resource_path
			
			var new_font_path := "res://ui/theme/fonts/OpenDyslexic-Regular.otf"
			
			if "SourceCodePro" in path:
				new_font_path = "res://ui/theme/fonts/OpenDyslexicMono-Regular.otf"
			elif "Italic" in path:
				new_font_path = "res://ui/theme/fonts/OpenDyslexic-Italic.otf"
			elif "Bold" in path:
				new_font_path = "res://ui/theme/fonts/OpenDyslexic-Bold.otf"
			
			# Fix for line 88: Cast the loaded resource to Font immediately
			var loaded_font: Font = load(new_font_path) as Font
			_theme.set_font("font", type, loaded_font)
		else:
			# Fix for line 90: base_font is now explicitly typed as : Font
			_theme.set_font("font", type, base_font)

	if and_save:
		var current_profile = UserProfiles.get_profile()
		current_profile.dyslexia_font = dyslexia_font
		current_profile.save()
