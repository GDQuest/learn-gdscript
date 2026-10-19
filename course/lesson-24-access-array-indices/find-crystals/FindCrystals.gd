extends CenterContainer

var current_item: Node = null
var used_items := []
var used_items_names := PackedStringArray()

@onready var grid_container := $GridContainer as GridContainer

const SWORD := preload("res://course/common/inventory/sword.png")
const SHIELD := preload("res://course/common/inventory/shield.png")
const HEART := preload("res://course/common/inventory/healing_heart.png")
const GEMS := preload("res://course/common/inventory/gems.png")

# IMPORTANT: Make sure the practice starter code matches this. We can't show
# texture values to students so we show them matching strings
const ITEM_TEXTURES: Array[Texture2D] = [
	HEART, GEMS, HEART, GEMS,
	GEMS, HEART, SWORD, HEART,
	SHIELD, GEMS, HEART, GEMS,
]


func _ready() -> void:
	inventory = grid_container.get_children()
	for i in inventory.size():
		var child = inventory[i]
		child.texture = ITEM_TEXTURES[i]
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


func reset() -> void:
	used_items = []
	used_items_names = PackedStringArray()
	current_item = null
	for item in inventory:
		item.reset(0)


func _run():
	pick_items()
	_on_item_used()


# EXPORT pick
var inventory = [
	"heart", "gems", "heart", "gems",
	"gems", "heart", "sword", "heart",
	"shield", "gems", "heart", "gems"
]

func pick_items():
	use_item(inventory[6])
	use_item(inventory[8])
# /EXPORT pick
