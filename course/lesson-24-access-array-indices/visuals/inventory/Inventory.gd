extends Control

var current_item: Node = null

func _ready() -> void:
	for child in get_children():
		child.connect("mouse_entered", Callable(self, "set_current_item").bind(child))
		child.connect("mouse_exited", Callable(self, "set_current_item").bind(null))


func set_current_item(item: Node):
	current_item = item


func use_item(index: int) -> void:
	if(index < 0):
		index += get_child_count()
	if index < 0 or index > get_child_count() - 1:
			printerr("Trying to access nonexistent item in inventory.")
			return
	print("using item %s"%[index])
	# warning-ignore:unsafe_method_access
	get_child(index).use()
