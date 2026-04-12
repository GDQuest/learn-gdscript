# Displays text and scenes or other visuals (optional) side-by-side.
#
# The block has a transparent background by default, except when inside a Revealer.
class_name UIContentBlock
extends MarginContainer

signal glossary_entry_clicked(term: String)

# Minimum width of the block before the visual content is hidden (doesn't apply to standalone visuals).
const VISUAL_VISIBLE_MIN_WIDTH := 500.0

const COLOR_NOTE := Color(0.14902, 0.776471, 0.968627)

const RevealerScene := preload("res://ui/components/Revealer.tscn")

@export var _content_root: PanelContainer
@export var _content_header: Label
@export var _content_container: Control
@export var _text_content: RichTextLabel
@export var _content_separator: HSeparator

var _content_block: Variant
var _lesson: BBCodeParser.ParseNode
var _block_index: int
var _visual_element: CanvasItem
var _revealer_block: Revealer


func _ready() -> void:
	resized.connect(_on_resized)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_labels()


func setup(content_block, lesson: BBCodeParser.ParseNode, block_index: int) -> void:
	if not is_inside_tree():
		await self.ready

	_content_block = content_block
	_lesson = lesson
	_block_index = block_index

	var node := _content_block as BBCodeParser.ParseNode
	match node.tag:
		BBCodeParserData.Tag.PARAGRAPH:
			var title := BBCodeUtils.get_lesson_title_for_index(lesson, block_index)
			_content_header.visible = not title.is_empty()
			_content_header.text = tr(title)
		BBCodeParserData.Tag.NOTE:
			_content_header.visible = false
			_make_revealer()
		_:
			_content_header.visible = false

	_update_text_content()
	_text_content.meta_clicked.connect(_on_text_meta_clicked)

	if (_content_block as BBCodeParser.ParseNode).tag == BBCodeParserData.Tag.VISUAL:
		_make_visual_element()

	_content_separator.visible = (_content_block as BBCodeParser.ParseNode).tag == BBCodeParserData.Tag.SEPARATOR


func _make_revealer() -> void:
	var revealer := RevealerScene.instantiate() as Revealer
	revealer.title_panel = preload("res://ui/theme/revealer_notes_title.tres")
	revealer.title_panel_expanded = preload("res://ui/theme/revealer_notes_title_expanded.tres")
	revealer.content_panel = preload("res://ui/theme/revealer_notes_panel.tres")

	revealer.title_font_color = COLOR_NOTE
	var title := BBCodeUtils.get_note_title(_content_block as BBCodeParser.ParseNode)
	revealer.title = tr("Learn More") if title.is_empty() else tr(title)

	remove_child(_content_root)
	add_child(revealer)
	revealer.add_child(_content_root)
	_revealer_block = revealer


func _make_visual_element() -> void:
	var path := BBCodeUtils.get_visual_path(_content_block as BBCodeParser.ParseNode)
	if path.is_empty():
		return

	# If the path isn't absolute, we try to load the file from the current directory
	if path.is_relative_path():
		path = (_content_block.bbcode_path as String).get_base_dir().path_join(path)
	var resource := load(path)
	if not resource:
		printerr(
			(
				"ContentBlock visual element is not a valid resource. From path: "
				+ path
			),
		)
		return

	if resource is Texture2D:
		var texture_rect := TextureRect.new()
		texture_rect.texture = resource
		_content_container.add_child(texture_rect)
		_visual_element = texture_rect
	elif resource is PackedScene:
		var instance: Node = (resource as PackedScene).instantiate()
		_content_container.add_child(instance)
		_visual_element = instance
	else:
		printerr(
			(
				"ContentBlock visual element is not a Texture2D or a PackedScene. Loaded type: "
				+ resource.get_class() + " From path: "
				+ path
			),
		)
		return

	# As this is a box container, we can reverse the order of elements by
	# raising the panel.
#	if _content_block.reverse_blocks and is_instance_valid(_visual_element):
#		_visual_element.raise()


func _update_labels() -> void:
	if not _content_block:
		return

	var node := _content_block as BBCodeParser.ParseNode
	if node.tag == BBCodeParserData.Tag.PARAGRAPH:
		var title := BBCodeUtils.get_lesson_title_for_index(_lesson, _block_index)
		_content_header.visible = not title.is_empty()
		_content_header.text = tr(title)

	_update_text_content()

	if _revealer_block:
		var title := BBCodeUtils.get_note_title(_content_block as BBCodeParser.ParseNode)
		_revealer_block.title = tr("Learn More") if title.is_empty() else tr(title)


func _update_text_content() -> void:
	var text_content := ""
	var node := _content_block as BBCodeParser.ParseNode
	match node.tag:
		BBCodeParserData.Tag.PARAGRAPH:
			text_content = BBCodeUtils.get_paragraph_text(node)
		BBCodeParserData.Tag.NOTE:
			text_content = BBCodeUtils.get_note_contents(node)
	_text_content.text = TextUtils.bbcode_add_code_color(TextUtils.tr_paragraph(text_content))
	_text_content.visible = not text_content.is_empty()


func _on_text_meta_clicked(meta: String) -> void:
	glossary_entry_clicked.emit(meta)


func _on_resized() -> void:
	var width = size.x
	if _text_content.visible and is_instance_valid(_visual_element):
		_visual_element.visible = width >= VISUAL_VISIBLE_MIN_WIDTH
