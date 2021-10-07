extends Node2D

const Obstacle := preload("./assets/Obstacle.gd")
const ObstacleSmall := preload("./assets/ObstacleSmall.tscn")
const ObstacleBig := preload("./assets/ObstacleBig.tscn")
const Player := preload("./assets/Player.gd")

var speed := 0.0
var points := 0

var _started := false

onready var _player := $Player as Player
onready var _background_player := $Background/AnimationPlayer as AnimationPlayer
onready var _label := $Label as Label
onready var _timer := $Timer as Timer
onready var _obstacles := $Obstacles as Node2D


func _ready() -> void:
	randomize()
	_game_over()
	_start()


func _add_obstacle() -> void:
	var is_big = randi() % 2
	var obstacle: Obstacle = ObstacleBig.instance() if is_big else ObstacleSmall.instance()
	_obstacles.add_child(obstacle)
	obstacle.position.y = 500
	obstacle.position.x = get_viewport_rect().size.x
	obstacle.tween.playback_speed = speed
	obstacle.set_destination(0, 4.0)
	obstacle.connect("body_entered", self, "_on_body_entered")
	obstacle.connect("reached_destination", self, "_on_obstacle_reached_destination")


func set_speed(new_speed: float) -> void:
	speed = new_speed
	_background_player.playback_speed = speed
	for obstacle in _obstacles.get_children():
		obstacle.tween.playback_speed = speed


func _increase_speed() -> void:
	set_speed(speed + 0.1)


func _get_animation_length() -> float:
	return _background_player.current_animation_length * speed


func _on_obstacle_reached_destination():
	_increase_speed()


func _on_Timer_timeout() -> void:
	points += 1
	_set_points_label()
	if randi() % 10 > 3:
		_add_obstacle()


func _set_points_label() -> void:
	_label.text = String(points).pad_zeros(4)


func _on_body_entered(body: CollisionObject2D) -> void:
	if body is Player:
		_game_over()


func _game_over() -> void:
	_started = false
	for obstacle in _obstacles.get_children():
		obstacle.queue_free()
	_timer.stop()
	_player.is_walking = false
	set_speed(0)
	points = 0
	_set_points_label()


func _start() -> void:
	_started = true
	_timer.start()
	_player.is_walking = true
	set_speed(1.0)
	_add_obstacle()


func _input(event: InputEvent) -> void:
	if _started:
		return
	# warning-ignore:unsafe_property_access
	if event is InputEventKey and event.pressed:
		_start()
