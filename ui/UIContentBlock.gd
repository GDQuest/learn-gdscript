# Displays text and scenes or other visuals (optional) side-by-side.
#
# The block has a transparent background by default, except when inside a Revealer.
class_name UIContentBlock
extends Control

# Margin to apply to the panel in pixels when the block is inside a revealer.
const MARGIN := 16

var min_width_to_show_image := 500.0

var _visual_element: CanvasItem

onready var _rich_text_label := $HBoxContainer/MarginContainer/RichTextLabel as RichTextLabel
onready var _margin := $HBoxContainer/MarginContainer as MarginContainer


func _ready() -> void:
	connect("resized", self, "_on_resized")


func setup(content_block: ContentBlock) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_rich_text_label.bbcode_text = content_block.text
	_margin.visible = not content_block.text.empty()

	if content_block.visual_element_path != "":
		# If the path isn't absolute, we try to load the file from the current directory
		var path := content_block.visual_element_path
		if path.is_rel_path():
			path = content_block.resource_path.get_base_dir().plus_file(path)
		var resource := load(path)

		if resource is Texture:
			var texture_rect := TextureRect.new()
			texture_rect.texture = resource
			add_child(texture_rect)
			_visual_element = texture_rect
		elif resource is PackedScene:
			var instance = (resource as PackedScene).instance()
			add_child(instance)
			_visual_element = instance
		else:
			printerr(
				(
					"ContentBlock visual element is not a Texture or a PackedScene. Loaded type: "
					+ resource.get_class()
				)
			)

	# As this is a box container, we can reverse the order of elements by
	# raising the panel.
	if content_block.reverse_blocks:
		_rich_text_label.raise()


func set_draw_panel(do_draw_panel: bool) -> void:
	if not is_inside_tree():
		yield(self, "ready")
	
	if do_draw_panel:
		add_stylebox_override("panel", preload("theme/panel_content_in_spoiler.tres"))
		_margin.add_constant_override("margin_left", MARGIN)
		_margin.add_constant_override("margin_right", MARGIN)
		_margin.add_constant_override("margin_top", MARGIN)
		_margin.add_constant_override("margin_bottom", MARGIN)


func _on_resized() -> void:
	var width = rect_size.x
	if _visual_element:
		_visual_element.visible = width >= min_width_to_show_image
