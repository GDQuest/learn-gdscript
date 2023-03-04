extends Node2D

signal line_highlight_requested

var light_index := 0

onready var _tween := $Tween as Tween
onready var _index_label := $Index as Label
onready var _lights := [
	$Red,
	$Yellow,
	$Green
]


func _ready() -> void:
	reset()


func run() -> void:
	emit_signal("line_highlight_requested", 2)
	yield()
	
	light_index += 1
	_index_label.text = str(light_index)
	emit_signal("line_highlight_requested", 3)
	yield()
	light_index %= 3
	_index_label.text = str(light_index)
	emit_signal("line_highlight_requested", 4)
	yield()
	
	turn_on_light(light_index, false)
	emit_signal("line_highlight_requested", 5)
	yield()


func reset() -> void:
	light_index = 0
	turn_on_light(light_index, true)
	_index_label.text = str(light_index)


func turn_on_light(_light_index: int, skip: bool) -> void:
	if _tween.is_active():
		_tween.seek(1.0)
	
	for light in _lights:
		_tween.interpolate_property(light, "modulate:a", light.modulate.a, 0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	
	_tween.interpolate_property(_lights[light_index], "modulate:a", 0, 1, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.2)
	_tween.start()
	
	if skip:
		_tween.seek(1.0)
