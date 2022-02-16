extends ColorRect

enum Framerates { SIXTY_FPS, THIRTY_FPS, NO_LIMIT }

# Maps framerate options selected in the UI to actual framerate values.
const FRAMERATE_MAP := {
	Framerates.SIXTY_FPS: 60,
	Framerates.THIRTY_FPS: 30,
	Framerates.NO_LIMIT: 0,
}

var _sample_default_font: DynamicFont

onready var _language_value := $PanelContainer/Column/Margin/Column/Settings/LanguageSetting/Value as OptionButton
onready var _font_size_value := $PanelContainer/Column/Margin/Column/Settings/FontSizeSetting/ValueContainer/Value as HSlider
onready var _font_size_sample := $PanelContainer/Column/Margin/Column/Settings/FontSizeSetting/ValueContainer/SampleText as Label
onready var _scroll_sensitivity_slider := $PanelContainer/Column/Margin/Column/Settings/ScrollSensitivitySetting/Value as HSlider
onready var _framerate_option := $PanelContainer/Column/Margin/Column/Settings/FramerateSetting/Value as OptionButton

onready var _apply_button := $PanelContainer/Column/Margin/Column/Buttons/ApplyButton as Button
onready var _cancel_button := $PanelContainer/Column/Margin/Column/Buttons/CancelButton as Button


func _init() -> void:
	# Store the initial state as is, so that we can preview it without being affected.
	_sample_default_font = ResourceLoader.load("res://ui/theme/fonts/font_text.tres", "", true).duplicate()


func _ready() -> void:
	var current_profile = UserProfiles.get_profile()
	_font_size_value.value = clamp(
		int(current_profile.font_size_scale), _font_size_value.min_value, _font_size_value.max_value
	)
	_scroll_sensitivity_slider.value = current_profile.scroll_sensitivity
	_framerate_option.selected = FRAMERATE_MAP.values().find(current_profile.framerate_limit)

	_font_size_value.connect("value_changed", self, "_on_font_size_changed")
	_scroll_sensitivity_slider.connect(
		"value_changed", self, "_on_scroll_sensitivity_slider_value_changed"
	)
	_framerate_option.connect("item_selected", self, "_on_framerate_option_item_selected")

	_apply_button.connect("pressed", self, "_on_apply_settings")
	_cancel_button.connect("pressed", self, "hide")
	connect("visibility_changed", self, "_on_visibility_changed")


func _on_font_size_changed(value: int) -> void:
	var font_override = _sample_default_font.duplicate() as DynamicFont
	font_override.size += 2 * value
	_font_size_sample.add_font_override("font", font_override)


func _on_apply_settings() -> void:
	var size_scale := int(_font_size_value.value)
	ThemeManager.scale_all_font_sizes(size_scale)


func _on_scroll_sensitivity_slider_value_changed(value: float) -> void:
	UserProfiles.get_profile().set_scroll_sensitivity(value)


func _on_framerate_option_item_selected(index: int) -> void:
	UserProfiles.get_profile().set_framerate_limit(FRAMERATE_MAP[index])


func _on_visibility_changed() -> void:
	if visible:
		_font_size_value.grab_focus()
