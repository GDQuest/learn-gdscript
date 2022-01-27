extends ColorRect

signal accepted

onready var _popup_container := $PanelContainer as Control
onready var _incomplete_summary := $PanelContainer/Layout/Margin/Column/IncompleteSummary as Label
onready var _move_on_button := $PanelContainer/Layout/Margin/Column/Buttons/MoveOnButton as Button
onready var _stay_button := $PanelContainer/Layout/Margin/Column/Buttons/StayButton as Button


func _ready() -> void:
	set_as_toplevel(true)
	
	_move_on_button.connect("pressed", self, "_on_button_pressed")
	_stay_button.connect("pressed", self, "hide")


func set_incomplete(incomplete: bool) -> void:
	_incomplete_summary.visible = incomplete


func popup_centered() -> void:
	_popup_container.rect_size = _popup_container.rect_min_size
	show()
	_popup_container.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)


func _on_button_pressed() -> void:
	hide()
	emit_signal("accepted")
