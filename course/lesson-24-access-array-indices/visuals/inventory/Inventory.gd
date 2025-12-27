extends Control

var current_item: Node = null

func _ready() -> void:
	for child in get_children():
		# Godot 4 uses the signal.connect() syntax
		# We use .bind() to pass the 'child' or 'null' argument
		child.mouse_entered.connect(set_current_item.bind(child))
		child.mouse_exited.connect(set_current_item.bind(null))


func set_current_item(item: Node) -> void:
	current_item = item


func use_item(index: int) -> void:
	# Support for negative indices
	if index < 0:
		index += get_child_count()
	
	if index < 0 or index > get_child_count() - 1:
		printerr("Trying to access nonexistent item in inventory.")
		return
		
	print("using item %s" % index)
	
	# Godot 4 uses @ annotations for warning suppression
	@warning_ignore("unsafe_method_access")
	get_child(index).use()
