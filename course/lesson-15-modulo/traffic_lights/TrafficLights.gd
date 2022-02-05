extends Node2D


var light_index := 0
var lights_switched_on := []

onready var _tween := $Tween
onready var _index_label := $Index
onready var _lights := [
	$Red,
	$Yellow,
	$Green
]

# EXPORT traffic_light
func advance_traffic_light():
	light_index += 1
	light_index %= 3
# /EXPORT traffic_light
	lights_switched_on.append(light_index)


func _run() -> void:
	light_index = 0
	for i in range(5):
		advance_traffic_light()
		turn_on_light(light_index)
		_index_label.text = str(light_index)
		yield(_tween, "tween_all_completed")
	Events.emit_signal("practice_run_completed")


func turn_on_light(light_index) -> void:
	for light in _lights:
		light.modulate.a = 0
	
	if light_index > 2:
		_tween.interpolate_property(_lights[0], "modulate:a", 0, 0, 1.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	else:
		_tween.interpolate_property(_lights[light_index], "modulate:a", 0, 1, 1.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	_tween.start()
