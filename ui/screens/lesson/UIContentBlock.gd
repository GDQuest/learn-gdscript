# Displays text and scenes or other visuals (optional) side-by-side.
#
# The block has a transparent background by default, except when inside a Revealer.
class_name UIContentBlock
extends MarginContainer

# Minimum width of the block before the visual content is hidden (doesn't apply to standalone visuals).
const VISUAL_VISIBLE_MIN_WIDTH := 500.0

const COLOR_NOTE := Color(0.14902, 0.776471, 0.968627)

const RevealerScene := preload("res://ui/components/Revealer.tscn")


var _content_block
var _lesson: BBCodeParser.ParseNode
var _block_index: int
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


func setup(content_block, lesson: BBCodeParser.ParseNode, block_index: int) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_content_block = content_block
	_lesson = lesson
	_block_index = block_index
	if _content_block is String:
		_content_block = BBCodeUtils.clean_text_content(_content_block)
		var title := BBCodeUtils.get_lesson_title_for_index(lesson, block_index)
		_content_header.visible = not title.empty()
		_content_header.text = tr(title)
	elif _content_block is BBCodeParser.ParseNode:
		_content_header.visible = false
		if _content_block.tag == BBCodeParserData.Tag.NOTE:
			_make_revealer()

	var text_content := ""
	if _content_block is String:
		text_content = _content_block
	elif _content_block is BBCodeParser.ParseNode and _content_block.tag == BBCodeParserData.Tag.NOTE:
		text_content = BBCodeUtils.get_note_contents(_content_block)
	_text_content.bbcode_text = TextUtils.bbcode_add_code_color(TextUtils.tr_paragraph(text_content))
	_text_content.visible = not text_content.empty()

	if BBCodeUtils.get_block_type(_content_block) == BBCodeParserData.Tag.VISUAL:
		_make_visual_element()

	_content_separator.visible = _content_block is BBCodeParser.ParseNode and BBCodeUtils.get_block_type(_content_block) == BBCodeParserData.Tag.SEPARATOR


func _make_revealer() -> void:
	var revealer := RevealerScene.instance() as Revealer
	revealer.title_panel = preload("res://ui/theme/revealer_notes_title.tres")
	revealer.title_panel_expanded = preload("res://ui/theme/revealer_notes_title_expanded.tres")
	revealer.content_panel = preload("res://ui/theme/revealer_notes_panel.tres")

	revealer.title_font_color = COLOR_NOTE
	var title := BBCodeUtils.get_note_title(_content_block)
	revealer.title = tr("Learn More") if title.empty() else tr(title)

	remove_child(_content_root)
	add_child(revealer)
	revealer.add_child(_content_root)
	_revealer_block = revealer


func _make_visual_element() -> void:
	var path := BBCodeUtils.get_visual_path(_content_block)
	if path.empty():
		return

	# If the path isn't absolute, we try to load the file from the current directory
	if path.is_rel_path():
		path = _content_block.bbcode_path.get_base_dir().plus_file(path)
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
#	if _content_block.reverse_blocks and is_instance_valid(_visual_element):
#		_visual_element.raise()


func _update_labels() -> void:
	if not _content_block:
		return

	if _content_block is String:
		var title := BBCodeUtils.get_lesson_title_for_index(_lesson, _block_index)
		_content_header.visible = not title.empty()
		_content_header.text = tr(title)

	if _content_block is String:
		var title := BBCodeUtils.get_lesson_title_for_index(_lesson, _block_index)
		_content_header.text = tr(title)

	var text_content := ""
	if _content_block is String:
		text_content = _content_block
	elif _content_block is BBCodeParser.ParseNode and _content_block.tag == BBCodeParserData.Tag.NOTE:
		text_content = BBCodeUtils.get_note_contents(_content_block)
	_text_content.bbcode_text = TextUtils.bbcode_add_code_color(TextUtils.tr_paragraph(text_content))

	if _revealer_block:
		var title := BBCodeUtils.get_note_title(_content_block)
		_revealer_block.title = tr("Learn More") if title.empty() else tr(title)


func _on_resized() -> void:
	var width = rect_size.x
	if _text_content.visible and is_instance_valid(_visual_element):
		_visual_element.visible = width >= VISUAL_VISIBLE_MIN_WIDTH
