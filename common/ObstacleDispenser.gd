extends Node2D

const Obstacle = preload("./Obstacle.gd")
const ObstacleScene = preload("./Obstacle.tscn")

var _obstacles := []


func _ready() -> void:
	for child in get_children():
		if child is Obstacle:
			_obstacles.push_back(child)
			remove_child(child)


# EXPORT get_random
func get_random_obstacle() -> Obstacle:
	var size := _obstacles.size()
	var index := randi() % size
	# warning-ignore:unsafe_cast
	var obstacle := _obstacles[index] as Obstacle
	return obstacle


# /EXPORT get_random


func dispense() -> Obstacle:
	var model := get_random_obstacle()
	var obstacle := ObstacleScene.instance() as Obstacle
	obstacle.texture = model.texture
	obstacle.shape = model.shape
	add_child(obstacle)
	return obstacle
