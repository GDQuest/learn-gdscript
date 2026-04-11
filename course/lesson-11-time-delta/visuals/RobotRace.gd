extends Node2D

@export var _robot_frame_delta: Node2D
@export var _robot_frame: Node2D
@export var _timer: Timer

@onready var _robots := [_robot_frame_delta, _robot_frame]


func _ready() -> void:
	set_process(false)


func run() -> void:
	reset()
	_timer.start()
	set_process(true)


func _process(delta: float) -> void:
	for robot in _robots:
		robot.move(delta)


func reset() -> void:
	set_process(false)
	_timer.stop()
	for robot in _robots:
		robot.reset()


func _on_Timer_timeout() -> void:
	set_process(false)
