extends Node2D

onready var index_label := $PanelContainer/HBoxContainer/Values/IndexLabel as Label
onready var position_label := $PanelContainer/HBoxContainer/Values/PositionLabel as Label

var current_item: Sprite

func _ready() -> void:
	tracks = $Grid.get_children()
	for i in tracks.size():
		var track := tracks[i] as Sprite
		var container := Control.new()
		add_child(container)
		container.rect_size = track.region_rect.size
		container.rect_global_position = track.global_position - container.rect_size / 2
		container.connect("mouse_entered", self, "set_current_item", [true, track])
		container.connect("mouse_exited", self, "set_current_item", [false, track])
	if get_tree().get_current_scene() == self:
		_run()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed and current_item:
			var text = "index: %s, position: %s"%[current_item.get_index(), current_item.position.round()]
			print(text)

func set_current_item(enter: bool, item: Sprite):
	if not enter:
		current_item = null
		index_label.text = "-1"
		position_label.text = "(0, 0)"
	else:
		current_item = item
		index_label.text = str(current_item.get_index())
		position_label.text = str(current_item.position.round())
		

func _run():
	fix_tracks()
	Events.emit_signal("practice_completed")

# EXPORT fix
var tracks = []
func fix_tracks():
	tracks[1].position.y -= 10
	tracks[8].position += Vector2(-10, 10)
# /EXPORT fix
