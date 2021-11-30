extends Node2D

const Obstacle := preload("./Obstacle.gd")
const ObstacleDispenser := preload("./ObstacleDispenser.gd")
const Player := preload("./Player.gd")

signal game_over
signal add_point

var _speed := 0.0
var _started := false

onready var _player := $Player as Player
onready var _background_player := $Background/AnimationPlayer as AnimationPlayer
onready var _timer := $Timer as Timer
onready var _obstacles := $ObstaclesDispenser as ObstacleDispenser


func _add_obstacle() -> void:
	var obstacle: Obstacle = _obstacles.dispense()
	obstacle.global_position.y = 500
	obstacle.global_position.x = get_viewport_rect().size.x
	obstacle.speed = _speed
	obstacle.set_destination(0, 4.0)
	obstacle.connect("body_entered", self, "_on_body_entered")
	obstacle.connect("reached_destination", self, "_on_obstacle_reached_destination")


func set_speed(new_speed: float) -> void:
	_speed = new_speed
	_background_player.playback_speed = _speed
	for obstacle in _obstacles.get_children():
		obstacle.speed = _speed


func _increase_speed() -> void:
	set_speed(_speed + 0.1)


func _get_animation_length() -> float:
	return _background_player.current_animation_length * _speed


func _on_obstacle_reached_destination():
	_increase_speed()


func _on_Timer_timeout() -> void:
	emit_signal("add_point")
	if randi() % 10 > 3:
		_add_obstacle()


func _on_body_entered(body: CollisionObject2D) -> void:
	if body.is_in_group("Player"):
		emit_signal("game_over")


func game_over() -> void:
	_started = false
	for obstacle in _obstacles.get_children():
		obstacle.queue_free()
	_timer.stop()
	_player.is_walking = false
	set_speed(0)
	_player.set_physics_process(false)


func start() -> void:
	_started = true
	_timer.start()
	_player.is_walking = true
	set_speed(1.0)
	_add_obstacle()
	_player.set_physics_process(true)
