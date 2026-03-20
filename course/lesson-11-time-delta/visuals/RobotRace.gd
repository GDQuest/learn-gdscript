extends Node2D

@onready var _robots := [$Robots/RunningRobotFrameDelta, $Robots/RunningRobotFrame]
@onready var _timer := $Timer


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
