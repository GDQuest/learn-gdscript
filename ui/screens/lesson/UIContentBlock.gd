# Displays text and scenes or other visuals (optional) side-by-side.
#
# The block has a transparent background by default, except when inside a Revealer.
class_name UIContentBlock
extends MarginContainer

# Minimum width of the block before the visual content is hidden (doesn't apply to standalone visuals).
const VISUAL_VISIBLE_MIN_WIDTH := 500.0

const COLOR_NOTE := Color(0.14902, 0.776471, 0.968627)

const RevealerScene := preload("res://ui/components/Revealer.tscn")


var _content_block: ContentBlock
var _visual_element: CanvasItem
var _revealer_block: Revealer

onready var _content_root := $Panel as PanelContainer
onready var _content_margin := $Panel/MarginContainer as MarginContainer

onready var _content_header := $Panel/MarginContainer/Layout/ContentHeader as Label
onready var _content_container := $Panel/MarginContainer/Layout/ContentLayout as Control
onready var _text_content := $Panel/MarginContainer/Layout/ContentLayout/TextContent as RichTextLabel
onready var _content_separator := $Panel/MarginContainer/Layout/ContentSeparator as HSeparator


func _ready() -> void:
	connect("resized", self, "_on_resized")


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_labels()


func setup(content_block: ContentBlock) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_content_block = content_block
	if _content_block.type == ContentBlock.Type.PLAIN:
		_content_header.visible = not _content_block.title.empty()
		_content_header.text = tr(_content_block.title)
	else:
		_content_header.visible = false
		_make_revealer()

	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_text_content.bbcode_text = TextUtils.bbcode_add_code_color(tr(_content_block.text.replace("\r\n", "\n")))
	_text_content.visible = not _content_block.text.empty()

	if _content_block.visual_element_path != "":
		_make_visual_element()

	_content_separator.visible = _content_block.has_separator


func _make_revealer() -> void:
	if _content_block.type == ContentBlock.Type.PLAIN:
		return

	var revealer := RevealerScene.instance() as Revealer
	revealer.title_panel = preload("res://ui/theme/revealer_notes_title.tres")
	revealer.title_panel_expanded = preload("res://ui/theme/revealer_notes_title_expanded.tres")
	revealer.content_panel = preload("res://ui/theme/revealer_notes_panel.tres")

	if _content_block.type == ContentBlock.Type.NOTE:
		revealer.title_font_color = COLOR_NOTE
	revealer.title = tr("Learn More") if _content_block.title.empty() else tr(_content_block.title)

	remove_child(_content_root)
	add_child(revealer)
	revealer.add_child(_content_root)
	_revealer_block = revealer


func _make_visual_element() -> void:
	if _content_block.visual_element_path.empty():
		return

	# If the path isn't absolute, we try to load the file from the current directory
	var path := _content_block.visual_element_path
	if path.is_rel_path():
		# TODO: Should probably avoid relying on content ID for getting paths.
		path = _content_block.content_id.get_base_dir().plus_file(path)
	var resource := load(path)
	if not resource:
		printerr(
			(
				"ContentBlock visual element is not a valid resource. From path: "
				+ path
			)
		)
		return


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
				+ resource.get_class() + " From path: "
				+ path
			)
		)
		return

	# As this is a box container, we can reverse the order of elements by
	# raising the panel.
	if _content_block.reverse_blocks and is_instance_valid(_visual_element):
		_visual_element.raise()


func _update_labels() -> void:
	if not _content_block:
		return
	
	if _content_block.type == ContentBlock.Type.PLAIN:
		_content_header.text = tr(_content_block.title)
	
	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_text_content.bbcode_text = TextUtils.bbcode_add_code_color(tr(_content_block.text.replace("\r\n", "\n")))
	
	if _revealer_block:
		_revealer_block.title = tr("Learn More") if _content_block.title.empty() else tr(_content_block.title)


func _on_resized() -> void:
	var width = rect_size.x
	if _text_content.visible and is_instance_valid(_visual_element):
		_visual_element.visible = width >= VISUAL_VISIBLE_MIN_WIDTH
