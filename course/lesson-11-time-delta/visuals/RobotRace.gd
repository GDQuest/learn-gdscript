extends Node2D

const DELTAS := [0.1, 0.3, 0.5, 0.1, 0.2, 0.2, 0.6, 0.1, 0.1, 0.1, 0.3, 0.2, 0.1, 0.1, 0.1, 0.1]

var computer_speed := 1.0 setget _set_computer_speed, get_computer_speed
var _index := 0

onready var _robots := $Robots
onready var _timer := $Timer
onready var _robot_normal := $Robots/RunningRobotNormal
onready var _robot_frame_delta := $Robots/RunningRobotFrameDelta
onready var _robot_frame := $Robots/RunningRobotFrame


func run() -> void:
	if not _robot_normal.is_connected("animation_complete", _robot_frame_delta, "reset"):
		_robot_normal.connect("animation_complete", _robot_frame_delta, "reset")
	if not _robot_normal.is_connected("animation_complete", _robot_frame, "reset"):
		_robot_normal.connect("animation_complete", _robot_frame, "reset")

	reset()
	for child in _robots.get_children():
		child.run()

	_on_Timer_timeout()


func _set_computer_speed(new_computer_speed: float) -> void:
	computer_speed = new_computer_speed * 10

	if not _robots:
		return

	for child in _robots.get_children():
		child.computer_speed = computer_speed
	
	reset()


func get_computer_speed() -> float:
	return computer_speed


func reset() -> void:
	_index = 0
	_timer.stop()
	_robot_normal.reset()


func _on_Timer_timeout() -> void:
	if _index > DELTAS.size() - 1:
		_index = 0
		return
	
	_robot_frame_delta.set_sprite_position(_robot_normal.get_sprite_position())
	_robot_frame.move(Vector2(30, 0))
	
	_timer.start(DELTAS[_index] / computer_speed)
	_index += 1
