extends Node2D

const INITIAL_ORDERS := ["cheese sandwich", "burger", "toast", "tomato soup"]

@onready var _waiting_orders_box := $Row/Pending/VBoxContainer as VBoxContainer
@onready var _completed_orders_box := $Row/Done/VBoxContainer as VBoxContainer


func _run():
	reset()
	waiting_orders = INITIAL_ORDERS.duplicate()

	for i in waiting_orders.size():
		var cook_time := 2.0 + i * 0.5
		var meal := Meal.new(waiting_orders[i], cook_time)
		meal.meal_ready.connect(_on_meal_ready.bind(meal))
		_waiting_orders_box.add_child(meal)


func _on_meal_ready(completed_meal: Meal):
	complete_current_order()
	var order = completed_orders.back()
	if order != null:
		var order_name := "%s"%[order]
		var meal := Meal.new(order_name)
		_completed_orders_box.add_child(meal)
	if waiting_orders.is_empty():
		_complete_run()


# EXPORT complete
var waiting_orders = [
	"cheese sandwich",
	"burger",
	"toast",
	"tomato soup",
]
var completed_orders = []

func complete_current_order():
	var completed_order = waiting_orders.pop_front()
	completed_orders.append(completed_order)
# /EXPORT complete


func reset():
	waiting_orders.clear()
	completed_orders.clear()

	for child in _waiting_orders_box.get_children():
		child.queue_free()

	for child in _completed_orders_box.get_children():
		child.queue_free()


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.practice_run_completed.emit()


class Meal extends VBoxContainer:

	const TEXTURE_UNCHECKED := preload("res://ui/assets/icons/checkbox_empty.png")
	const TEXTURE_CHECKED := preload("res://ui/assets/icons/checkbox_checked.png")
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
		progress.show_percentage = false
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
			scene_tween.finished.connect(_on_tween_completed)
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
		meal_ready.emit()
		scene_tween = create_tween()
		scene_tween.tween_property(self, "modulate:a", 0.0, 1).from(modulate.a).set_ease(Tween.EASE_IN)

	func get_text() -> String:
		return label.text
