extends ColorRect

const _sample_default_font: DynamicFont = preload("res://ui/theme/fonts/font_text.tres")

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


func _ready():
	_font_size_value.connect("value_changed", self, "_on_font_size_changed")
	
	_apply_button.connect("pressed", self, "_on_apply_settings")
	_cancel_button.connect("pressed", self, "hide")


func _on_font_size_changed(value: int) -> void:
	var font_override = _sample_default_font.duplicate() as DynamicFont
	font_override.size += 2 * value
	_font_size_sample.add_font_override("font", font_override)


func _on_apply_settings() -> void:
	pass
