extends Node2D

const INITIAL_ORDERS := ["cheese sandwich", "burger", "toast", "tomato soup"]
const MEAL_SCENE := preload("res://course/lesson-23-append-to-arrays/clearing-meals/Meal.tscn")

@onready var _waiting_orders_box := $Row/Pending/VBoxContainer as VBoxContainer
@onready var _completed_orders_box := $Row/Done/VBoxContainer as VBoxContainer

var _do_pop_from_back := false


func _run():
	reset()
	waiting_orders = INITIAL_ORDERS.duplicate()
	_do_pop_from_back = _does_student_code_use_pop_back()

	for i in waiting_orders.size():
		var cook_time := 2.0 + i * 0.5
		var order_index := waiting_orders.size() - i - 1 if _do_pop_from_back else i
		var meal := MEAL_SCENE.instantiate()
		meal.call("setup", waiting_orders[order_index], cook_time)
		meal.connect("meal_ready", _on_meal_ready.bind(meal))
		_waiting_orders_box.add_child(meal)


func _does_student_code_use_pop_back() -> bool:
	var checker := GDScriptErrorChecker.new()
	if checker.set_source(get_script().source_code) != OK:
		return false
	var analyzer := GDScriptASTAnalyzer.new(checker.get_root_parse_node())
	var complete_function := analyzer.get_function_named("complete_current_order")
	if not complete_function:
		return false
	for statement in complete_function.get_body().get_statements():
		if statement.get_type() != GDNode.VARIABLE:
			continue
		var initializer := (statement as GDVariableNode).get_initializer()
		if (
			initializer
			and initializer.get_type() == GDNode.CALL
			and (initializer as GDCallNode).get_function_name() == "pop_back"
		):
			return true
	return false


func _on_meal_ready(completed_meal: Node):
	complete_current_order()
	var order = completed_orders.back()
	if order != null:
		var order_name := "%s"%[order]
		var meal := MEAL_SCENE.instantiate()
		meal.call("setup", order_name)
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
