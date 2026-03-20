extends Node2D

const WAIT_QUEUE := [
	{name = "cheese sandwich", time = 1.0},
	{name = "burger", time = 1.5},
	{name = "toast", time = 2.0},
	{name = "tomato soup", time = 2.0},
]

var _add_timer := Timer.new()

var _wait_queue := []

@onready var _waiting_orders_box := $Row/Pending/VBoxContainer as VBoxContainer
@onready var _completed_orders_box := $Row/Done/VBoxContainer as VBoxContainer


func _ready():
	add_child(_add_timer)
	_add_timer.wait_time = 1.0
	_add_timer.connect("timeout", Callable(self, "add_order"))


func _run():
	reset()
	_wait_queue = WAIT_QUEUE.duplicate()
	add_order()
	_add_timer.start()


func add_order():
	if _wait_queue.is_empty():
		_add_timer.stop()
		return
	
	var order = _wait_queue.pop_back()
	var meal := Meal.new(order.name, order.time)
	meal.connect("meal_ready", Callable(self, "_on_meal_ready").bind(meal))
	waiting_orders.append(order.name)
	_waiting_orders_box.add_child(meal)


func _on_meal_ready(completed_meal: Meal):
	print("completing order `%s`"%[completed_meal.text])
	complete_current_order()
	var order = completed_orders.back()
	if order != null:
		var order_name := "%s"%[order]
		var meal := Meal.new(order_name)
		_completed_orders_box.add_child(meal)
	if waiting_orders.is_empty():
		_complete_run()

# EXPORT complete
var waiting_orders = []
var completed_orders = []

func complete_current_order():
	var completed_order = waiting_orders.pop_front()
	completed_orders.append(completed_order)
# /EXPORT complete

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
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")

class Meal extends VBoxContainer:

	const TEXTURE_UNCHECKED := preload("res://ui/icons/checkbox_empty.png")
	const TEXTURE_CHECKED := preload("res://ui/icons/checkbox_checked.png")
	signal meal_ready
	
	var label := Label.new()
	var progress := ProgressBar.new()
	var scene_tween: Tween
	var texture := TextureRect.new()
	var time := 0.0
	var _meal_is_ready := false
	var text := "": get = get_text

	func _init(init_text: String, init_time: float = 0) -> void:
		var container := HBoxContainer.new()
		progress.percent_visible = false
		container.add_child(texture)
		container.add_child(label)
		add_child(container)
		add_child(progress)
		time = init_time
		label.text = init_text

	func _ready() -> void:
		modulate.a = 0
		scene_tween = create_tween().set_parallel()
		scene_tween.tween_property(self, "modulate:a", 1.0, 1).from(0.0).set_ease(Tween.EASE_OUT)
		if time > 0:
			texture.texture = TEXTURE_UNCHECKED
			scene_tween.connect("finished", Callable(self, "_on_tween_completed"))
			scene_tween.tween_property(progress, "value", 100.0, time).from(0.0)
		else:
			texture.texture = TEXTURE_CHECKED
			progress.value = 100

	func _on_tween_completed():
		if _meal_is_ready:
			queue_free()
			return
		_meal_is_ready = true
		texture.texture = TEXTURE_CHECKED
		emit_signal("meal_ready")
		scene_tween = create_tween()
		scene_tween.tween_property(self, "modulate:a", 0.0, 1).from(modulate.a).set_ease(Tween.EASE_IN)

	func get_text() -> String:
		return label.text
