extends ColorRect

var health := 100
var max_health := 100

onready var _empty_health_bar := $HealthBarEmpty as ColorRect
onready var _health_bar := $HealthBarCurrent as ColorRect
onready var _label := $Label as Label
onready var _tween := $Tween as Tween


func _ready() -> void:
	rect_size.x = _empty_health_bar.rect_size.x * health / max_health


func set_health(new_health: int) -> void:
	health = new_health
	_update_bars()


func set_max_health(new_max_health: int) -> void:
	max_health = new_max_health
	health = max_health
	_update_bars()


func _update_bars() -> void:
	var size_current = _health_bar.rect_size.x
	var size_to = _empty_health_bar.rect_size.x * health / max_health
	
	_label.text = "health = %s" % [health]
	
	_tween.interpolate_property(_health_bar, "rect_size:x", size_current, size_to, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	_tween.start()
