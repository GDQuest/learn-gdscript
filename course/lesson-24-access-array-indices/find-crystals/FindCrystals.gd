extends CenterContainer

var current_item: Node = null
var used_items := []
var used_items_names := PackedStringArray()

@onready var grid_container := $GridContainer as GridContainer


func _ready() -> void:
	inventory = grid_container.get_children()
	# Sadly, we can't randomize because we can't provide
	# a dynamic solution. TODO: allow generating a solution
	# var first_item_index := randi() % inventory.size()
	# var second_item_index := first_item_index
	# while second_item_index - first_item_index < 2:
	#	second_item_index = randi() % inventory.size()
	# The user can pick any tuple [ fire, lightning ], but
	# we need to ensure there are at least 2 we know for sure
	# make sure those indices are the same in `pick_items`
	# at the bottom
	var first_item_index := 6
	var second_item_index := 8
	for i in inventory.size():
		var child = inventory[i]
		if i == first_item_index:
			child.texture = child.SWORD
		elif i == second_item_index:
			child.texture = child.SHIELD
		if not child.mouse_entered.is_connected(set_current_item):
			child.mouse_entered.connect(set_current_item.bind(child))
		if not child.mouse_exited.is_connected(set_current_item):
			child.mouse_exited.connect(set_current_item.bind(null))
		if not child.used.is_connected(_on_item_used):
			child.used.connect(_on_item_used)
	if get_tree().get_current_scene() == self:
		_run()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed and current_item:
			use_item(current_item)


func set_current_item(item: Node):
	current_item = item


func use_item(item: Node) -> void:
	used_items.append(item)


func _on_item_used() -> void:
	var item = used_items.pop_front()
	if item != null:
		_use_item(item)
	else:
		_complete_run()

func _complete_run() -> void:
	print("used items: %s"%[used_items_names])
	await get_tree().create_timer(0.5).timeout
	Events.practice_run_completed.emit()


func _use_item(item: Node) -> void:
	var index = item.get_index()
	# warning-ignore:unsafe_method_access
	var item_name = item.get_texture_name()
	print("using item %s: \"%s\""%[index, item_name])
	# warning-ignore:unsafe_method_access
	item.use()
	used_items_names.append(item_name)


func _run():
	pick_items()
	_on_item_used()


# EXPORT pick
var inventory = []

func pick_items():
	use_item(inventory[6])
	use_item(inventory[8])
# /EXPORT pick
