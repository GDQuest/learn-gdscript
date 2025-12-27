extends Node

enum Framerates { SIXTY_FPS, THIRTY_FPS, NO_LIMIT }

const FRAMERATE_MAP: Dictionary = {
	Framerates.SIXTY_FPS: 60,
	Framerates.THIRTY_FPS: 30,
	Framerates.NO_LIMIT: 0,
}

var _sample_default_font: Font

@onready var _panel := $PanelContainer as PanelContainer
@onready var _color_rect := $ColorRect as ColorRect
@onready var _language_value := $PanelContainer/Column/Margin/Column/ScrollContainer/Settings/LanguageSetting/Value as OptionButton
@onready var _font_size_value := $PanelContainer/Column/Margin/Column/ScrollContainer/Settings/FontSizeSetting/ValueContainer/Value as HSlider
@onready var _font_size_sample := $PanelContainer/Column/Margin/Column/ScrollContainer/Settings/FontSizeSetting/ValueContainer/SampleText as Label
@onready var _scroll_sensitivity_slider := $PanelContainer/Column/Margin/Column/ScrollContainer/Settings/ScrollSensitivitySetting/Value as HSlider
@onready var _framerate_option := $PanelContainer/Column/Margin/Column/ScrollContainer/Settings/FramerateSetting/Value as OptionButton

@onready var _lower_contrast := $PanelContainer/Column/Margin/Column/ScrollContainer/Settings/LowerContrasSetting/CheckBox as CheckBox
@onready var _dyslexia_font := $PanelContainer/Column/Margin/Column/ScrollContainer/Settings/FontSetting/CheckBox as CheckBox

@onready var _apply_button := $PanelContainer/Column/Margin/Column/Buttons/ApplyButton as Button
@onready var _cancel_button := $PanelContainer/Column/Margin/Column/Buttons/CancelButton as Button


func _init() -> void:
	_sample_default_font = ResourceLoader.load(
		"res://ui/theme/fonts/font_text.tres",
		"Font", 
		ResourceLoader.CACHE_MODE_REUSE
	)

func _ready() -> void:
	_init_languages()
	_init_values()
	
	_font_size_value.value_changed.connect(_on_font_size_changed)
	_apply_button.pressed.connect(_on_apply_settings)
	_cancel_button.pressed.connect(hide_popup)
	_panel.visibility_changed.connect(_on_visibility_changed)

func show_popup() -> void:
	_panel.show()
	_color_rect.show()

func hide_popup() -> void:
	_panel.hide()
	_color_rect.hide()

func _init_languages() -> void:
	_language_value.clear()
	var available_languages := TranslationManager.get_available_languages()
	for language_data in available_languages:
		var item_index := _language_value.get_item_count()
		_language_value.add_item(str(language_data.name))
		_language_value.set_item_metadata(item_index, str(language_data.code))

func _init_values() -> void:
	var current_profile = UserProfiles.get_profile() as Profile
	if not current_profile:
		return
	
	for i in range(_language_value.get_item_count()):
		var language_code := str(_language_value.get_item_metadata(i))
		if language_code == current_profile.language:
			_language_value.select(i)
			break
	
		_font_size_value.value = clamp(
		current_profile.font_size_scale as float,
		_font_size_value.min_value,
		_font_size_value.max_value
	)
	_scroll_sensitivity_slider.value = current_profile.scroll_sensitivity
	_framerate_option.selected = FRAMERATE_MAP.values().find(current_profile.framerate_limit)
	
	_lower_contrast.button_pressed = current_profile.lower_contrast
	_dyslexia_font.button_pressed = current_profile.dyslexia_font

func _on_apply_settings() -> void:
	var current_profile = UserProfiles.get_profile() as Profile
	if not current_profile:
		return
	
	var size_scale := int(_font_size_value.value)
	ThemeManager.scale_all_font_sizes(size_scale)
	
	ThemeManager.set_lower_contrast(_lower_contrast.button_pressed)
	ThemeManager.set_dyslexia_font(_dyslexia_font.button_pressed)

	current_profile.call("set_scroll_sensitivity", _scroll_sensitivity_slider.value)
	
	var fr: int = FRAMERATE_MAP.values()[_framerate_option.selected]
	current_profile.call("set_framerate_limit", fr)
	
	var language_code := str(_language_value.get_item_metadata(_language_value.selected))
	TranslationManager.set_language(language_code)
	
	if current_profile.dyslexia_font:
		_font_size_sample.add_theme_font_override("font", load("res://ui/theme/fonts/OpenDyslexic-Regular.otf") as Font)
	else:
		_font_size_sample.remove_theme_font_override("font")

func _on_font_size_changed(value: float) -> void:
	_font_size_sample.add_theme_font_size_override("font_size", int(value))

func _on_visibility_changed() -> void:
	if _panel.visible:
		_font_size_value.grab_focus()
