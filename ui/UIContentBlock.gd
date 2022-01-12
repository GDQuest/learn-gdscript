# Displays text and scenes or other visuals (optional) side-by-side.
#
# The block has a transparent background by default, except when inside a Revealer.
class_name UIContentBlock
extends MarginContainer

# Margin to apply to the panel in pixels when the block is inside a revealer.
const REVEALER_MARGIN := 16
# Minimum width of the block before the visual content is hidden (doesn't apply to standalone visuals).
const VISUAL_VISIBLE_MIN_WIDTH := 500.0

const COLOR_NOTE := Color(0.14902, 0.776471, 0.968627)

const RevealerScene := preload("components/Revealer.tscn")


var _content_block: ContentBlock
var _visual_element: CanvasItem

onready var _content_root := $Panel as PanelContainer
onready var _content_margin := $Panel/MarginContainer as MarginContainer

onready var _content_header := $Panel/MarginContainer/Layout/ContentHeader as Label
onready var _content_container := $Panel/MarginContainer/Layout/ContentLayout as Control
onready var _text_content := $Panel/MarginContainer/Layout/ContentLayout/TextContent as RichTextLabel
onready var _content_separator := $Panel/MarginContainer/Layout/ContentSeparator as HSeparator


func _ready() -> void:
	connect("resized", self, "_on_resized")


func setup(content_block: ContentBlock) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_content_block = content_block
	if _content_block.type == ContentBlock.Type.PLAIN:
		_content_header.visible = not _content_block.title.empty()
		_content_header.text = _content_block.title
	else:
		_content_header.visible = false
		_make_revealer()

	_text_content.bbcode_text = TextUtils.bbcode_add_code_color(_content_block.text)
	_text_content.visible = not _content_block.text.empty()

	if _content_block.visual_element_path != "":
		_make_visual_element()
	
	_content_separator.visible = _content_block.has_separator


func _make_revealer() -> void:
	if _content_block.type == ContentBlock.Type.PLAIN:
		return
	
	var revealer := RevealerScene.instance() as Revealer
	revealer.padding = 0.0
	revealer.first_margin = 0.0
	revealer.children_margin = 0.0
	
	if _content_block.type == ContentBlock.Type.NOTE:
		revealer.text_color = COLOR_NOTE
		revealer.title = "Note" if _content_block.title.empty() else _content_block.title
	else:
		revealer.title = "Learn More" if _content_block.title.empty() else _content_block.title

	remove_child(_content_root)
	add_child(revealer)
	revealer.add_child(_content_root)
	
	_content_root.set_anchors_and_margins_preset(Control.PRESET_WIDE, Control.PRESET_MODE_MINSIZE)
	_content_root.add_stylebox_override("panel", preload("theme/panel_content_in_spoiler.tres"))
	_content_margin.add_constant_override("margin_left", REVEALER_MARGIN)
	_content_margin.add_constant_override("margin_right", REVEALER_MARGIN)
	_content_margin.add_constant_override("margin_top", REVEALER_MARGIN)
	_content_margin.add_constant_override("margin_bottom", REVEALER_MARGIN)


func _make_visual_element() -> void:
	if _content_block.visual_element_path.empty():
		return
	
	# If the path isn't absolute, we try to load the file from the current directory
	var path := _content_block.visual_element_path
	if path.is_rel_path():
		path = _content_block.resource_path.get_base_dir().plus_file(path)
	var resource := load(path)

	if resource is Texture:
		var texture_rect := TextureRect.new()
		texture_rect.texture = resource
		_content_container.add_child(texture_rect)
		_visual_element = texture_rect
	elif resource is PackedScene:
		var instance = (resource as PackedScene).instance()
		_content_container.add_child(instance)
		_visual_element = instance
	else:
		printerr(
			(
				"ContentBlock visual element is not a Texture or a PackedScene. Loaded type: "
				+ resource.get_class()
			)
		)
		return
	
	# As this is a box container, we can reverse the order of elements by
	# raising the panel.
	if _content_block.reverse_blocks and is_instance_valid(_visual_element):
		_visual_element.raise()


func _on_resized() -> void:
	var width = rect_size.x
	if _text_content.visible and is_instance_valid(_visual_element):
		_visual_element.visible = width >= VISUAL_VISIBLE_MIN_WIDTH
