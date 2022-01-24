tool
extends RunnableCodeExample

func _ready():
	create_slider_for("computer_speed", 0.1, 1.0, 0.1)

func _set_instance_value(value: float, property_name: String, value_label: Label) -> void:
	._set_instance_value(value, property_name, value_label)
	_gdscript_text_edit.text = gdscript_code.replace(property_name, "%s [=%s]"%[property_name, value])
