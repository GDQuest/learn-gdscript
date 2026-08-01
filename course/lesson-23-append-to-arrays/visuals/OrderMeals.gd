extends Node2D

const MEAL_SCENE := preload("res://course/lesson-23-append-to-arrays/clearing-meals/Meal.tscn")
const WAIT_QUEUE := [
	{name = "cheese sandwich", time = 1.0},
	{name = "burger", time = 1.5},
	{name = "toast", time = 2.0},
	{name = "tomato soup", time = 2.0},
]

var waiting_orders = []
var completed_orders = []
var _add_timer := Timer.new()

var _wait_queue := []

@onready var _waiting_orders_box := $Row/Pending/VBoxContainer as VBoxContainer
@onready var _completed_orders_box := $Row/Done/VBoxContainer as VBoxContainer


func _ready():
	add_child(_add_timer)
	_add_timer.wait_time = 1.0
	_add_timer.timeout.connect(add_order)


func run():
	_wait_queue = WAIT_QUEUE.duplicate()
	add_order()
	_add_timer.start()


func add_order():
	if _wait_queue.is_empty():
		_add_timer.stop()
		return

	var order = _wait_queue.pop_back()
	var meal := MEAL_SCENE.instantiate()
	meal.call("setup", order.name, order.time)
	meal.connect("meal_ready", _on_meal_ready)
	waiting_orders.append(order.name)
	_waiting_orders_box.add_child(meal)


func _on_meal_ready():
	complete_current_order()
	var order_name := "%s"%[completed_orders.back()]
	var meal := MEAL_SCENE.instantiate()
	meal.call("setup", order_name)
	_completed_orders_box.add_child(meal)
	if waiting_orders.is_empty():
		_complete_run()


func complete_current_order():
	var completed_order = waiting_orders.pop_front()
	completed_orders.append(completed_order)


func reset():
	_add_timer.stop()

	_wait_queue.clear()
	waiting_orders.clear()
	completed_orders.clear()

	for child in _waiting_orders_box.get_children():
		child.queue_free()

	for child in _completed_orders_box.get_children():
		child.queue_free()


func _complete_run() -> void:
	pass
