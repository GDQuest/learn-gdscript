extends Node2D


var light_index := -1

onready var index_label := $Index
onready var lights := [
	$Red,
	$Orange,
	$Green
]
onready var _tween := $Tween

func _ready():
	run()


func run() -> void:
	if _tween.is_active():
		return
	light_index += 1
	light_index %= 3
	
	turn_on_light(light_index)
	
	index_label.text = str(light_index)


func turn_on_light(light_index) -> void:
	
	for light in lights:
		_tween.interpolate_property(light, "modulate:a", light.modulate.a, 0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	
	_tween.interpolate_property(lights[light_index], "modulate:a", 0, 1, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.2)
	
	_tween.start()
	
	index_label.rect_position.y = 60 * (light_index - 1) - 20
