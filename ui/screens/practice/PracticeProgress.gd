extends PanelContainer

signal previous_requested
signal next_requested
signal list_requested

onready var _prev_button := $Layout/PrevButton as Button
onready var _next_button := $Layout/NextButton as Button
onready var _list_button := $Layout/ListButton as Button


func _ready() -> void:
	_prev_button.connect("pressed", self, "emit_signal", [ "previous_requested" ])
	_next_button.connect("pressed", self, "emit_signal", [ "next_requested" ])
	_list_button.connect("pressed", self, "emit_signal", [ "list_requested" ])


func set_previous_enabled(state: bool) -> void:
	_prev_button.disabled = not state


func set_next_enabled(state: bool) -> void:
	_next_button.disabled = not state
