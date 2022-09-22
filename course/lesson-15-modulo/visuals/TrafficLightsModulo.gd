extends Node2D

signal line_highlight_requested

var initial_light_index := 0
var light_index := initial_light_index - 1

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
	emit_signal("line_highlight_requested", 0)
	yield()
	
	if _tween.is_active():
		return
	
	light_index += 1
	_index_label.text = str(light_index)
	emit_signal("line_highlight_requested", 1)
	yield()
	light_index %= 3
	_index_label.text = str(light_index)
	emit_signal("line_highlight_requested", 2)
	yield()
	
	turn_on_light(light_index)


func reset() -> void:
	light_index = initial_light_index
	turn_on_light(initial_light_index)
	
	_index_label.text = str(light_index)


func turn_on_light(_light_index: int) -> void:
	
	for light in _lights:
		_tween.interpolate_property(light, "modulate:a", light.modulate.a, 0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	
	_tween.interpolate_property(_lights[light_index], "modulate:a", 0, 1, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.2)
	_tween.start()
