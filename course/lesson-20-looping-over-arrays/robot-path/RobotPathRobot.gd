class_name RobotPathRobot
extends Node2D

signal goal_reached

var move_queue := []
var points := []

var tween: Tween


func move_to(cell: Vector2) -> void:
	move_queue.append(cell)
	points.append(cell)
	if not tween or not tween.is_running():
		_play_move_animation()


func _play_move_animation() -> void:
	var target_cell = move_queue.pop_front()
	if not target_cell:
		goal_reached.emit()
		return

	while target_cell:
		tween = create_tween()
		tween.tween_property(self, "position", get_parent().cell_to_position(target_cell), 0.2).from(
			position
		)
		await tween.finished
		await get_tree().create_timer(0.2).timeout
		target_cell = move_queue.pop_front()

	goal_reached.emit()
