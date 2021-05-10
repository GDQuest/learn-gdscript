extends KinematicBody2D

export (int) var speed := 1200
export (int) var jump_speed := -1800
export (int) var gravity := 4000

var velocity = Vector2.ZERO

export (float, 0, 1.0) var friction := 0.1
export (float, 0, 1.0) var acceleration := 0.25

func _physics_process(delta):
		var dir = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
		).normalized()
		if dir.x != 0:
				velocity.x = lerp(velocity.x, dir.x * speed, acceleration)
		else:
				velocity.x = lerp(velocity.x, 0, friction)
		velocity.y += gravity * delta
		velocity = move_and_slide(velocity, Vector2.UP)
		if Input.is_action_just_pressed("ui_up"):
				if is_on_floor():
						velocity.y = jump_speed
