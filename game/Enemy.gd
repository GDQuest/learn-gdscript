extends KinematicBody2D

export var speed := 1200
export var jump_speed := -1800
export var gravity := 4000
export (float, 0, 1.0) var friction = 0.1
export (float, 0, 1.0) var acceleration = 0.25
export (float, 0, 1) var time_span := .5

var velocity = Vector2.ZERO
var direction = Vector2()

var _timer := Timer.new()


func _ready():
	add_child(_timer)
	_timer.connect("timeout", self, "random_action")
	_timer.start(time_span)
	print("a log thing")
	push_error("an error")
	push_warning("a warning")
	prints("several", ["arguments"])


func random_action():
	match randi() % 2:
		0:
			direction.y = 1
		_:
			direction.y = 0
	match randi() % 2 if direction.y != 0 else 5:
		0:
			direction.x = 1
		1:
			direction.x = -1
		_:
			direction.x = 0


func _physics_process(delta):
	if direction.x != 0:
		velocity.x = lerp(velocity.x, direction.x * speed, acceleration)
	else:
		velocity.x = lerp(velocity.x, 0, friction)
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	if direction.y > 0:
		if is_on_floor():
			velocity.y = jump_speed
