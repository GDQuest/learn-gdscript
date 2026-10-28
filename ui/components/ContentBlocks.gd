@tool
class_name ContentBlocks
extends VBoxContainer
## Displays sequences of content blocks returned by BBCodeUtils.get_content_blocks().
## Content is only updated through set_blocks(), called by parent screens in
## response to TranslationManager.translation_changed. The node does not react
## to NOTIFICATION_TRANSLATION_CHANGED: _blocks holds already-translated text,
## so rebuilding from it on locale change would re-render the old language.

var _blocks: Array = []
var _is_rebuild_queued := false


## Creates a read-only code editor displaying a [lb]code_listing[rb] BBCode node's code.
static func make_code_listing(node: BBCodeParser.ParseNode) -> CodeEdit:
	const CODE_LISTING_SCENE := preload("res://ui/components/CodeListing.tscn")
	var listing: CodeEdit = CODE_LISTING_SCENE.instantiate()
	listing.text = BBCodeUtils.get_code_listing_text(node)
	return listing


func set_blocks(blocks: Array) -> void:
	_blocks = blocks
	visible = not blocks.is_empty()
	_update_children()


func _update_children() -> void:
	if _is_rebuild_queued:
		return

	_is_rebuild_queued = true
	if not is_node_ready():
		await ready
	_rebuild_children.call_deferred()


func _rebuild_children() -> void:
	_is_rebuild_queued = false

	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	var is_rtl := _get_text_alignment()
	for block: Variant in _blocks:
		if block is BBCodeParser.ParseNode:
			add_child(make_code_listing(block))
		else:
			add_child(_make_text_label(block, is_rtl))


func _make_text_label(text: String, rtl: bool) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabelRTL.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.selection_enabled = true
	label.text = TextUtils.preprocess_bbcode_for_rich_text_label(text)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if rtl else HORIZONTAL_ALIGNMENT_LEFT
	return label


func _get_text_alignment() -> bool:
	if Engine.is_editor_hint():
		return false
	return TranslationManager.current_translation_is_rtl()
