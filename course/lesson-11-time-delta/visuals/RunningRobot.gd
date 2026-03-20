extends Node2D

var computer_speed := 1.0
var distance := 400
var speed := distance/3

@onready var _sprite := $Robot

func _ready() -> void:
	_sprite.position.x = -distance/2

func run() -> void:
	pass

func reset() -> void:
	pass

func set_sprite_position(new_position: Vector2) -> void:
	_sprite.position = new_position

func get_sprite_position() -> Vector2:
	return _sprite.position
