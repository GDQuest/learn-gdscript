class_name UIContentBlock
extends HBoxContainer

var min_width_to_show_image := 500.0

var _visual_element: Node

onready var _panel := $Panel as Panel
onready var _rich_text_label := $Panel/Panel/MarginContainer/RichTextLabel as RichTextLabel


func _ready() -> void:
	connect("resized", self, "_on_resized")


func setup(content_block: ContentBlock) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_rich_text_label.bbcode_text = content_block.text

	if content_block.visual_element_path != "":
		var resource := load(content_block.visual_element_path)
		if resource is Texture:
			var texture_rect := TextureRect.new()
			texture_rect.texture = resource
			add_child(texture_rect)
			_visual_element = texture_rect
		elif resource is PackedScene:
			var instance = resource.instance()
			add_child(instance)
			_visual_element = instance
		else:
			printerr(
				(
					"ContentBlock resource is not a Texture or a PackedScene. Loaded type: "
					+ resource.get_class()
				)
			)

	# As this is a box container, we can reverse the order of elements by
	# raising the panel.
	if content_block.reverse_blocks:
		_panel.raise()


func _on_resized() -> void:
	var width = rect_size.x
	if _visual_element:
		_visual_element.visible = width >= min_width_to_show_image
