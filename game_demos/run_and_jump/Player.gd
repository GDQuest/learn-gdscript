extends KinematicBody2D

export var jump_speed := 200
export var jump_max_height := 100.0
export var gravity := 4000

var is_walking := false

onready var animated_sprite := $AnimatedSprite as AnimatedSprite

var _velocity_y = 0.0
var _jump_starting_point := 0.0


func _ready() -> void:
	add_to_group("Player")


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("jump"):
		# EXPORT jump
		if is_on_floor():
			_jump_starting_point = position.y
			_velocity_y -= jump_speed
		else:
			var jump_height := _jump_starting_point - position.y
			var is_going_up: bool = _velocity_y < 0
			var is_under_apex: bool = jump_height < jump_max_height
			if is_going_up and is_under_apex:
				_velocity_y -= jump_speed
		# /EXPORT jump

	if Input.is_action_just_pressed("jump"):
		animated_sprite.play("jump")
	elif is_on_floor() and is_walking:
		animated_sprite.play("walk")

	_velocity_y += gravity * delta

	var velocity := Vector2(0, _velocity_y)
	_velocity_y = move_and_slide(velocity, Vector2.UP).y
