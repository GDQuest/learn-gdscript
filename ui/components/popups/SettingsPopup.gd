extends Node

enum Framerates {
	SIXTY_FPS,
	THIRTY_FPS,
	NO_LIMIT,
}

# Maps framerate options selected in the UI to actual framerate values.
const FRAMERATE_MAP := {
	Framerates.SIXTY_FPS: 60,
	Framerates.THIRTY_FPS: 30,
	Framerates.NO_LIMIT: 0,
}

@onready var _panel: PanelContainer = %PanelContainer
@onready var _color_rect: ColorRect = %ColorRect
@onready var _translation_info_button: Button = %TranslationInfoButton
@onready var _translation_info_popup: CanvasLayer = %TranslationInfoPopup
@onready var _language_value: OptionButton = %LanguageValue
@onready var _translation_status: Label = %TranslationStatus
@onready var _font_size_value: HSlider = %FontSizeValue
@onready var _font_size_sample: Label = %SampleText
@onready var _scroll_sensitivity_slider: HSlider = %ScrollSensitivityValue
@onready var _framerate_settings_section: Control = %FramerateSetting
@onready var _framerate_option: OptionButton = %FramerateValue
@onready var _lower_contrast: CheckBox = %LowerContrastCheckBox
@onready var _dyslexia_font: CheckBox = %DyslexiaFontCheckBox
@onready var _apply_button: Button = %ApplyButton
@onready var _cancel_button: Button = %CancelButton

var _sample_default_font: FontVariation


func _init() -> void:
	# Store the initial state as is, so that we can preview it without being affected.
	_sample_default_font = ResourceLoader \
			.load("res://ui/theme/fonts/font_text.tres", "", ResourceLoader.CACHE_MODE_IGNORE) \
			.duplicate()


func _ready() -> void:
	# TODO: Remove whenever https://github.com/godotengine/godot/issues/117875 is fixed
	if OS.has_feature("web"):
		_framerate_settings_section.hide()

	_init_languages()
	_init_values()

	_translation_info_button.pressed.connect(_translation_info_popup.show)
	_font_size_value.value_changed.connect(_on_font_size_changed)

	_apply_button.pressed.connect(_on_apply_settings)
	_cancel_button.pressed.connect(hide)
	_panel.visibility_changed.connect(_on_visibility_changed)


func show() -> void:
	_panel.show()
	_color_rect.show()


func hide() -> void:
	_panel.hide()
	_color_rect.hide()


func _init_languages() -> void:
	_language_value.clear()

	var available_languages := TranslationManager.get_available_languages()
	for language_data: Dictionary in available_languages:
		var item_index := _language_value.get_item_count()
		var language_name: String = language_data.name
		_language_value.add_item(language_name)
		_language_value.set_item_metadata(item_index, language_data.code)
	_language_value.item_selected.connect(_on_language_selected)


func _init_values() -> void:
	var current_profile = UserProfiles.get_profile()

	for i in _language_value.get_item_count():
		var language_code := str(_language_value.get_item_metadata(i))
		if language_code == current_profile.language:
			_language_value.select(i)
			break
	_update_translation_status()

	_font_size_value.value = clamp(
		current_profile.font_size_scale,
		_font_size_value.min_value,
		_font_size_value.max_value,
	)
	_scroll_sensitivity_slider.value = current_profile.scroll_sensitivity
	_framerate_option.selected = FRAMERATE_MAP.values().find(current_profile.framerate_limit)

	_lower_contrast.button_pressed = current_profile.lower_contrast
	_dyslexia_font.button_pressed = current_profile.dyslexia_font


func _on_apply_settings() -> void:
	var current_profile = UserProfiles.get_profile()

	var size_scale := int(_font_size_value.value)
	var dyslexia_font := _dyslexia_font.button_pressed
	if (
		size_scale != current_profile.font_size_scale
		or dyslexia_font != current_profile.dyslexia_font
	):
		ThemeManager.apply_font_settings(size_scale, dyslexia_font)
		current_profile.font_size_scale = size_scale
		current_profile.dyslexia_font = dyslexia_font
		current_profile.save()
		Events.font_size_scale_changed.emit(size_scale)

	if _lower_contrast.button_pressed != current_profile.lower_contrast:
		ThemeManager.set_lower_contrast(_lower_contrast.button_pressed)

	current_profile.set_scroll_sensitivity(_scroll_sensitivity_slider.value)
	current_profile.set_framerate_limit(FRAMERATE_MAP[_framerate_option.selected] as int)

	var language_code := str(_language_value.get_item_metadata(_language_value.selected))
	if language_code != TranslationManager.current_language:
		TranslationManager.set_language(language_code)

	var current_font := _font_size_sample.get_theme_font("font") as FontVariation
	if current_profile.dyslexia_font:
		current_font.base_font = load("res://ui/assets/fonts/OpenDyslexic-Regular.otf")
	_font_size_sample.add_theme_font_override("font", current_font)


func _on_language_selected(_index: int) -> void:
	_update_translation_status()


func _update_translation_status() -> void:
	var language_code := str(_language_value.get_item_metadata(_language_value.selected))
	if language_code.is_empty() or language_code == TranslationManager.DEFAULT_LOCALE:
		_translation_status.hide()
		return

	var summary := TranslationManager.get_translation_summary(language_code)
	_translation_status.text = tr(
		"{percentage}% of text translated. {completed}/{total} lessons fully translated."
	).format(
		{
			"percentage": floori(summary.completeness * 100.0),
			"completed": summary.fully_translated_lessons,
			"total": summary.total_lessons,
		}
	)
	_translation_status.show()


func _on_font_size_changed(value: int) -> void:
	var current_profile = UserProfiles.get_profile()
	var font_override := _sample_default_font.duplicate() as FontVariation
	var font_size := ThemeManager.get_default_font_size()
	if current_profile.dyslexia_font:
		font_override.base_font = load("res://ui/assets/fonts/OpenDyslexic-Regular.otf")
	_font_size_sample.add_theme_font_override("font", font_override)
	_font_size_sample.add_theme_font_size_override("font_size", font_size + value * 2)


func _on_visibility_changed() -> void:
	if _panel.visible:
		_font_size_value.grab_focus()
