extends KinematicBody2D


export (int) var speed = 1200
export (int) var jump_speed = -1800
export (int) var gravity = 4000

var velocity = Vector2.ZERO

export (float, 0, 1.0) var friction = 0.1
export (float, 0, 1.0) var acceleration = 0.25

export (float, 0, 1) var time_span := .5

var timer := Timer.new()
var dir = Vector2()

func _ready():
	add_child(timer)
	timer.connect("timeout", self, "random_action")
	timer.start(time_span)

func random_action():
	match(randi() % 2):
		0: dir.y = 1
		_: dir.y = 0
	match(randi() % 2 if dir.y != 0 else 5):
		0: dir.x = 1
		1: dir.x = -1
		_: dir.x = 0

func _physics_process(delta):
		if dir.x != 0:
				velocity.x = lerp(velocity.x, dir.x * speed, acceleration)
		else:
				velocity.x = lerp(velocity.x, 0, friction)
		velocity.y += gravity * delta
		velocity = move_and_slide(velocity, Vector2.UP)
		if dir.y > 0:
				if is_on_floor():
						velocity.y = jump_speed
