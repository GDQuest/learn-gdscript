extends CenterContainer

var current_item: Node = null
var used_items: Array[Node] = []
# Godot 4: PoolStringArray is now PackedStringArray
var used_items_names := PackedStringArray()

@onready var grid_container := $GridContainer as GridContainer

# EXPORT pick
# Moved declaration to the top to follow Godot 4 style, 
# though it can stay at the bottom if preferred.
var inventory: Array[Node] = []

func pick_items() -> void:
	use_item(inventory[6])
	use_item(inventory[8])
# /EXPORT pick


func _ready() -> void:
	# Convert Array to Typed Array
	inventory.assign(grid_container.get_children())
	
	var first_item_index := 6
	var second_item_index := 8
	
	for i in inventory.size():
		var child = inventory[i]
		if i == first_item_index:
			child.texture = child.SWORD
		elif i == second_item_index:
			child.texture = child.SHIELD
		
		# Godot 4 Signal connection syntax using .bind()
		child.mouse_entered.connect(set_current_item.bind(child))
		child.mouse_exited.connect(set_current_item.bind(null))
		child.used.connect(_on_item_used)
		
	if get_tree().current_scene == self:
		_run()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed and current_item:
			use_item(current_item)


func set_current_item(item: Node) -> void:
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
	print("used items: %s" % [used_items_names])
	await get_tree().create_timer(0.5).timeout
	# Godot 4 Signal emission
	Events.practice_run_completed.emit()


func _use_item(item: Node) -> void:
	var index = item.get_index()
	
	# Godot 4 uses @ annotations for warning suppression
	@warning_ignore("unsafe_method_access")
	var item_name = item.get_texture_name()
	
	print("using item %d: \"%s\"" % [index, item_name])
	
	@warning_ignore("unsafe_method_access")
	item.use()
	
	used_items_names.append(item_name)


func _run() -> void:
	pick_items()
	_on_item_used()
