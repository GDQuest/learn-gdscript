extends Control

var current_item: Node = null

func _ready() -> void:
	for child in get_children():
		child.connect("mouse_entered", self, "set_current_item", [child])
		child.connect("mouse_exited", self, "set_current_item", [null])


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed and current_item:
			var index: int = current_item.get_index()
			use_item(index)
		

func set_current_item(item: Node):
	current_item = item


func use_item(index: int) -> void:
	if (index < 0 and abs(index) < get_child_count()) \
		or \
		index > get_child_count() - 1:
			printerr("Trying to access nonexistent item in inventory.")
			return
	print("using item %s"%[index])
	get_child(index).use()
