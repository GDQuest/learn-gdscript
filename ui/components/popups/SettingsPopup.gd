extends Node

enum Framerates { SIXTY_FPS, THIRTY_FPS, NO_LIMIT }

# Maps framerate options selected in the UI to actual framerate values.
const FRAMERATE_MAP := {
	Framerates.SIXTY_FPS: 60,
	Framerates.THIRTY_FPS: 30,
	Framerates.NO_LIMIT: 0,
}

var _sample_default_font: DynamicFont

onready var _panel := $PanelContainer as PanelContainer
onready var _color_rect := $ColorRect as ColorRect
onready var _language_value := $PanelContainer/Column/Margin/Column/Settings/LanguageSetting/Value as OptionButton
onready var _font_size_value := $PanelContainer/Column/Margin/Column/Settings/FontSizeSetting/ValueContainer/Value as HSlider
onready var _font_size_sample := $PanelContainer/Column/Margin/Column/Settings/FontSizeSetting/ValueContainer/SampleText as Label
onready var _scroll_sensitivity_slider := $PanelContainer/Column/Margin/Column/Settings/ScrollSensitivitySetting/Value as HSlider
onready var _framerate_option := $PanelContainer/Column/Margin/Column/Settings/FramerateSetting/Value as OptionButton

onready var _lower_contrast := $PanelContainer/Column/Margin/Column/Settings/LowerContrasSetting/CheckBox as CheckBox

onready var _apply_button := $PanelContainer/Column/Margin/Column/Buttons/ApplyButton as Button
onready var _cancel_button := $PanelContainer/Column/Margin/Column/Buttons/CancelButton as Button


func _init() -> void:
	# Store the initial state as is, so that we can preview it without being affected.
	_sample_default_font = ResourceLoader.load("res://ui/theme/fonts/font_text.tres", "", true).duplicate()


func _ready() -> void:
	_init_languages()
	_init_values()
	
	_font_size_value.connect("value_changed", self, "_on_font_size_changed")
	
	_apply_button.connect("pressed", self, "_on_apply_settings")
	_cancel_button.connect("pressed", self, "hide")
	_panel.connect("visibility_changed", self, "_on_visibility_changed")


func show() -> void:
	_panel.show()
	_color_rect.show()


func hide() -> void:
	_panel.hide()
	_color_rect.hide()


func _init_languages() -> void:
	_language_value.clear()
	
	var available_languages := TranslationManager.get_available_languages()
	for language_data in available_languages:
		var item_index := _language_value.get_item_count()
		
		_language_value.add_item(language_data.name)
		_language_value.set_item_metadata(item_index, language_data.code)


func _init_values() -> void:
	var current_profile = UserProfiles.get_profile()
	
	for i in _language_value.get_item_count():
		var language_code := str(_language_value.get_item_metadata(i))
		if language_code == current_profile.language:
			_language_value.select(i)
			break
	
	_font_size_value.value = clamp(
		int(current_profile.font_size_scale), _font_size_value.min_value, _font_size_value.max_value
	)
	_scroll_sensitivity_slider.value = current_profile.scroll_sensitivity
	_framerate_option.selected = FRAMERATE_MAP.values().find(current_profile.framerate_limit)
	
	_lower_contrast.pressed = current_profile.lower_contrast


func _on_apply_settings() -> void:
	var current_profile = UserProfiles.get_profile()
	
	var size_scale := int(_font_size_value.value)
	ThemeManager.scale_all_font_sizes(size_scale)
	
	ThemeManager.set_lower_contrast(_lower_contrast.pressed)

	current_profile.set_scroll_sensitivity(_scroll_sensitivity_slider.value)
	current_profile.set_framerate_limit(FRAMERATE_MAP[_framerate_option.selected])
	
	var language_code := str(_language_value.get_item_metadata(_language_value.selected))
	TranslationManager.set_language(language_code)


func _on_font_size_changed(value: int) -> void:
	var font_override = _sample_default_font.duplicate() as DynamicFont
	font_override.size += 2 * value
	_font_size_sample.add_font_override("font", font_override)


func _on_visibility_changed() -> void:
	if _panel.visible:
		_font_size_value.grab_focus()
