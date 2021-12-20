extends ColorRect

var _sample_default_font: DynamicFont

onready var _language_value := (
	$PanelContainer/Column/Margin/Column/Settings/LanguageSetting/Value as OptionButton
)
onready var _font_size_value := (
	$PanelContainer/Column/Margin/Column/Settings/FontSizeSetting/ValueContainer/Value as HSlider
)
onready var _font_size_sample := (
	$PanelContainer/Column/Margin/Column/Settings/FontSizeSetting/ValueContainer/SampleText as Label
)

onready var _apply_button := $PanelContainer/Column/Margin/Column/Buttons/ApplyButton as Button
onready var _cancel_button := $PanelContainer/Column/Margin/Column/Buttons/CancelButton as Button


func _init() -> void:
	# Store the initial state as is, so that we can preview it without being affected.
	_sample_default_font = ResourceLoader.load("res://ui/theme/fonts/font_text.tres", "", true).duplicate()


func _ready() -> void:
	var current_profile = UserProfiles.get_profile()
	_font_size_value.value = clamp(int(current_profile.font_size_scale), _font_size_value.min_value, _font_size_value.max_value)
	
	_font_size_value.connect("value_changed", self, "_on_font_size_changed")
	
	_apply_button.connect("pressed", self, "_on_apply_settings")
	_cancel_button.connect("pressed", self, "hide")


func _on_font_size_changed(value: int) -> void:
	var font_override = _sample_default_font.duplicate() as DynamicFont
	font_override.size += 2 * value
	_font_size_sample.add_font_override("font", font_override)


func _on_apply_settings() -> void:
	var size_scale := int(_font_size_value.value)
	ThemeManager.scale_all_font_sizes(size_scale)
