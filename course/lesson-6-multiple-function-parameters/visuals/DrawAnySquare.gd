@tool
extends RunnableCodeExample

func _ready():
	create_slider_for("size", 20.0, 200.0, 10.0)

func _set_instance_value(value: float, property_name: String, value_label: Label) -> void:
	super._set_instance_value(value, property_name, value_label)
	set_run_button_label("draw_square(%s)" % value)
