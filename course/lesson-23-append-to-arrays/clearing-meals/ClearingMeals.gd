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


func _ready() -> void:
	add_child(_add_timer)
	_add_timer.wait_time = 1.0
	# Godot 4 Signal Syntax
	_add_timer.timeout.connect(add_order)


func _run() -> void:
	reset()
	_wait_queue = WAIT_QUEUE.duplicate()
	add_order()
	_add_timer.start()


func add_order() -> void:
	if _wait_queue.is_empty():
		_add_timer.stop()
		return
	
	var order: Dictionary = _wait_queue.pop_back()
	var meal := Meal.new(order.name, order.time)
	# Godot 4: bind() replaces the extra array argument in connect()
	meal.meal_ready.connect(_on_meal_ready.bind(meal))
	waiting_orders.append(order.name)
	_waiting_orders_box.add_child(meal)


func _on_meal_ready(completed_meal: Meal) -> void:
	print("completing order `%s`" % completed_meal.text)
	complete_current_order()
	
	if not completed_orders.is_empty():
		var order = completed_orders.back()
		var order_name := str(order)
		var meal := Meal.new(order_name)
		_completed_orders_box.add_child(meal)
		
	if waiting_orders.is_empty():
		_complete_run()

# EXPORT complete
var waiting_orders: Array = []
var completed_orders: Array = []

func complete_current_order() -> void:
	var completed_order = waiting_orders.pop_front()
	completed_orders.append(completed_order)
# /EXPORT complete

func reset() -> void:
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
	# Godot 4 Signal Syntax
	Events.practice_run_completed.emit()


class Meal extends VBoxContainer:
	const TEXTURE_UNCHECKED := preload("res://ui/icons/checkbox_empty.png")
	const TEXTURE_CHECKED := preload("res://ui/icons/checkbox_checked.png")
	
	signal meal_ready
	
	var label := Label.new()
	var progress := ProgressBar.new()
	var texture := TextureRect.new()	
	var time := 0.0
	var _meal_is_ready := false
	
	# Godot 4 property syntax
	var text: String: 
		get: return label.text

	func _init(init_text: String, init_time: float = 0) -> void:
		var container := HBoxContainer.new()
		# percent_visible -> show_percentage
		progress.show_percentage = false
		container.add_child(texture)
		container.add_child(label)
		add_child(container)
		add_child(progress)
		# Note: We do NOT add a Tween node in Godot 4; we use create_tween()
		time = init_time
		label.text = init_text

	func _ready() -> void:
		modulate.a = 0
		
		# Godot 4 Tween system (SceneTreeTween)
		var tween := create_tween()
		# We use parallel() to fade in and update progress at the same time
		tween.set_parallel(true)
		tween.tween_property(self, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
		
		if time > 0:
			texture.texture = TEXTURE_UNCHECKED
			tween.tween_property(progress, "value", 100.0, time).from(0.0)
			# Chain the finish signal
			tween.set_parallel(false)
			tween.finished.connect(_on_tween_completed)
		else:
			texture.texture = TEXTURE_CHECKED
			progress.value = 100
			# Only fade in
			tween.set_parallel(false)
			# Even if time is 0, we start the tween to trigger modulate
		
	func _on_tween_completed() -> void:
		if _meal_is_ready:
			queue_free()
			return
			
		_meal_is_ready = true
		texture.texture = TEXTURE_CHECKED
		meal_ready.emit()
		
		var fade_out := create_tween()
		fade_out.tween_property(self, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		fade_out.finished.connect(_on_tween_completed)
