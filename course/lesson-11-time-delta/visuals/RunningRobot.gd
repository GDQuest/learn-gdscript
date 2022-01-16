extends Node2D

var computer_speed := 1.0
var distance := 400
var speed := distance/3

onready var _sprite := $Robot

func _ready():
	_sprite.position.x = -distance/2

func run():
	pass

func reset():
	pass
