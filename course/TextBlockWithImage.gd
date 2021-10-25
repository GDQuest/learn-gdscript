tool
extends HBoxContainer

onready var texture_rect := $TextureRect as TextureRect
onready var text_label := $RichTextLabel as RichTextLabel

enum ORDER { TEXT_IMAGE, IMAGE_TEXT }

export (String, MULTILINE) var text: String setget set_text
export var texture: Texture setget set_texture
export (ORDER) var order := ORDER.TEXT_IMAGE setget set_order
export var min_width_to_show_image := 500.0


func _ready() -> void:
	connect("resized", self, "_on_resized")


func set_texture(new_texture: Texture) -> void:
	texture = new_texture
	if not is_inside_tree():
		yield(self, "ready")
	texture_rect.texture = texture


func set_text(new_text: String) -> void:
	text = new_text
	if not is_inside_tree():
		yield(self, "ready")
	text_label.bbcode_text = text


func set_order(new_order: int) -> void:
	if new_order == order:
		return
	order = new_order
	if not is_inside_tree():
		yield(self, "ready")
	if order == ORDER.IMAGE_TEXT:
		move_child(texture_rect, 0)
	else:
		move_child(texture_rect, 1)


func _on_resized() -> void:
	var width = rect_size.x
	texture_rect.visible = width >= min_width_to_show_image
	texture_rect.rect_min_size.x = width / 3
