tool
extends "./ButtonsContainer.gd"

const BOTH = "both"
const GAME = "game"
const CONSOLE = "console"

export (String, "both", "game", "console") var mode := BOTH setget set_mode, get_mode
export var split_container_path: NodePath setget set_split_container_path

var _split_container: SplitContainer


func _init() -> void:
	values = [BOTH, GAME, CONSOLE]
	for button_name in values:
		var button := Button.new()
		button.text = button_name
		button.toggle_mode = true
		button.set_meta("value", button_name)
		add_child(button)
	if Engine.editor_hint:
		return
	connect("item_selected", self, "_on_item_selected")


func _ready() -> void:
	select_first()


func _on_item_selected(new_value) -> void:
	if _split_container:
		var height := 0
		if new_value == GAME:
			height = 0
		elif new_value == CONSOLE:
			height = _split_container.rect_size.y
		else:
			height = _split_container.rect_size.y / 2
		_split_container.split_offset = height


func _on_split_container_dragged(offset: int) -> void:
	print(offset)


func set_split_container_path(path: NodePath) -> void:
	split_container_path = path
	if not is_inside_tree():
		yield(self, "ready")
	var node = get_node_or_null(path)
	if not (node is SplitContainer):
		push_error("nodepath %s does not yield a SplitContainer" % [path])
		return
	_split_container = node
	if not Engine.editor_hint:
		_split_container.connect("dragged", self, "_on_split_container_dragged")


func set_mode(new_mode: String) -> void:
	if new_mode != BOTH and new_mode != GAME and new_mode != CONSOLE:
		return
	mode = new_mode
	set_selected_value(new_mode)


func get_mode() -> String:
	var _mode = get_selected_value()
	if _mode == GAME:
		return GAME
	elif _mode == CONSOLE:
		return CONSOLE
	return BOTH
