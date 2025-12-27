extends ColorRect

var health := 100
var max_health := 100

@onready var _empty_health_bar := $HealthBarEmpty as ColorRect
@onready var _health_bar := $HealthBarCurrent as ColorRect
@onready var _label := $Label as Label
var _tween: Tween


func _ready() -> void:
	size.x = _empty_health_bar.size.x * float(health) / float(max_health)


func set_health(new_health: int) -> void:
	health = new_health
	_update_bars()


func set_max_health(new_max_health: int) -> void:
	max_health = new_max_health
	health = max_health
	_update_bars()


func _update_bars() -> void:
	var size_to: float = _empty_health_bar.size.x * float(health) / float(max_health)

	_label.text = "health = %s" % [health]

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_health_bar, "size:x", size_to, 0.2)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)
