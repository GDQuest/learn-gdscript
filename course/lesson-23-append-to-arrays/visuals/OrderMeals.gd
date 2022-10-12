extends Node2D

const WAIT_QUEUE := [
	{name = "cheese sandwich", time = 1.0},
	{name = "burger", time = 1.5},
	{name = "toast", time = 2.0},
	{name = "tomato soup", time = 2.0},
]

var waiting_orders := []
var completed_orders := []
var _add_timer := Timer.new()

var _wait_queue := []

onready var _waiting_orders_box := $Row/Pending/VBoxContainer as VBoxContainer
onready var _completed_orders_box := $Row/Done/VBoxContainer as VBoxContainer


func _ready():
	add_child(_add_timer)
	_add_timer.wait_time = 1.0
	_add_timer.connect("timeout", self, "add_order")


func run():
	_wait_queue = WAIT_QUEUE.duplicate()
	add_order()
	_add_timer.start()


func add_order():
	if _wait_queue.empty():
		_add_timer.stop()
		return
	
	var order = _wait_queue.pop_back()
	var meal := Meal.new(order.name, order.time)
	meal.connect("meal_ready", self, "_on_meal_ready")
	waiting_orders.append(order.name)
	_waiting_orders_box.add_child(meal)


func _on_meal_ready():
	complete_current_order()
	var order_name := "%s"%[completed_orders.back()]
	var meal := Meal.new(order_name)
	_completed_orders_box.add_child(meal)
	if waiting_orders.empty():
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


class Meal extends VBoxContainer:

	const TEXTURE_UNCHECKED := preload("res://ui/icons/checkbox_empty.png")
	const TEXTURE_CHECKED := preload("res://ui/icons/checkbox_checked.png")
	signal meal_ready
	
	var progress := ProgressBar.new()
	var tween := Tween.new()
	var texture := TextureRect.new()	
	var time := 0.0
	var _meal_is_ready := false
	
	func _init(init_text: String, init_time: float = 0) -> void:
		var label := Label.new()
		var container := HBoxContainer.new()
		progress.percent_visible = false
		container.add_child(texture)
		container.add_child(label)
		add_child(container)
		add_child(progress)
		add_child(tween)
		time = init_time
		label.text = init_text

	func _ready() -> void:
		modulate.a = 0.0
		tween.interpolate_property(self, "modulate:a", 0, 1, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		if time > 0:
			texture.texture = TEXTURE_UNCHECKED
			tween.connect("tween_all_completed", self, "_on_tween_completed")
			tween.interpolate_property(progress, "value", 0, 100.0, time)
		else:
			texture.texture = TEXTURE_CHECKED
			progress.value = 100
		tween.start()

	func _on_tween_completed():
		if _meal_is_ready:
			queue_free()
			return
		_meal_is_ready = true
		texture.texture = TEXTURE_CHECKED
		emit_signal("meal_ready")
		tween.interpolate_property(self, "modulate:a", modulate.a, 0, 1, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.start()
