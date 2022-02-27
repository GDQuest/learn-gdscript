extends Node2D

const ADD_QUEUE := [
	{name = "cheese sandwich", time = 2.5},
	{name = "burger", time = 1.5},
	{name = "toast", time = 2.0},
	{name = "cheese sandwich", time = 2.0},
]

var orders := []
var completed_orders := []
var add_timer := Timer.new()
var complete_timer := Timer.new()

var _queue := []

onready var orders_label := $Row/Pending/MarginContainer/Orders as Label
onready var completed_label := $Row/Done/MarginContainer/Orders as Label


func _ready():
	orders_label.text = ""
	completed_label.text = ""

	add_child(add_timer)
	add_timer.wait_time = 1.0
	add_timer.connect("timeout", self, "add_order")

	add_child(complete_timer)
	complete_timer.connect("timeout", self, "complete_order")
	complete_timer.one_shot = true


func run():
	_queue = ADD_QUEUE.duplicate()
	add_order()
	add_timer.start()
	complete_timer.wait_time = orders.front().time
	complete_timer.start()


func add_order():
	if _queue.empty():
		add_timer.stop()
		return

	orders.append(_queue.pop_back())
	if complete_timer.is_stopped():
		complete_timer.wait_time = orders.front().time
		complete_timer.start()
	_update_labels()


func complete_order():
	completed_orders.append(orders.pop_front())
	if not orders.empty():
		complete_timer.wait_time = orders.front().time
		complete_timer.start()
	_update_labels()


func _update_labels():
	orders_label.text = ""
	for order in orders:
		orders_label.text += "• " + order.name + "\n"

	completed_label.text = ""
	for order in completed_orders:
		completed_label.text += "• " + order.name + "\n"


func reset():
	add_timer.stop()
	complete_timer.stop()

	_queue.clear()
	orders.clear()
	completed_orders.clear()

	_update_labels()
