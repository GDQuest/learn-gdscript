extends VBoxContainer

const TEXTURE_UNCHECKED := preload("uid://cqdddd2njewww")
const TEXTURE_CHECKED := preload("uid://64neugja7awi")

signal meal_ready

@export var text := "cheese sandwich"
@export var time := 2.0

@onready var _label := $Header/Label as Label
@onready var _progress := $ProgressBar as ProgressBar
@onready var _texture := $Header/TextureRect as TextureRect

var _scene_tween: Tween
var _meal_is_ready := false


func setup(init_text: String, init_time: float = 0) -> void:
	text = init_text
	time = init_time


func _ready() -> void:
	_label.text = text
	modulate.a = 0
	_scene_tween = create_tween().set_parallel()
	_scene_tween.tween_property(self, "modulate:a", 1.0, 1).from(0.0).set_ease(Tween.EASE_OUT)
	if time > 0:
		_texture.texture = TEXTURE_UNCHECKED
		_scene_tween.finished.connect(_on_tween_completed)
		_scene_tween.tween_property(_progress, "value", 100.0, time).from(0.0)
	else:
		_texture.texture = TEXTURE_CHECKED
		_progress.value = 100


func _on_tween_completed() -> void:
	if _meal_is_ready:
		queue_free()
		return
	_meal_is_ready = true
	_texture.texture = TEXTURE_CHECKED
	meal_ready.emit()
	_scene_tween = create_tween()
	_scene_tween.tween_property(self, "modulate:a", 0.0, 1).from(modulate.a).set_ease(Tween.EASE_IN)


func get_text() -> String:
	return text
