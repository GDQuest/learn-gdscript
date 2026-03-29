extends ColorRect

var health := 100
var max_health := 100

@onready var _empty_health_bar := $HealthBarEmpty as ColorRect
@onready var _health_bar := $HealthBarCurrent as ColorRect
@onready var _label := $Label as Label


func _ready() -> void:
	size.x = _empty_health_bar.size.x * health / max_health


func set_health(new_health: int) -> void:
	health = new_health
	_update_bars()


func set_max_health(new_max_health: int) -> void:
	max_health = new_max_health
	health = max_health
	_update_bars()


func _update_bars() -> void:
	var size_current = _health_bar.size.x
	var size_to = _empty_health_bar.size.x * health / max_health

	_label.text = "health = %s" % [health]

	var tween := create_tween()
	tween.tween_property(_health_bar, "size:x", size_to, 0.2).from(size_current).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
