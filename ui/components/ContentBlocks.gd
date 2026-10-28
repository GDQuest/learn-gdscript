@tool
class_name ContentBlocks
extends VBoxContainer
## Displays sequences of content blocks returned by BBCodeUtils.get_content_blocks():
## Updates its children when the locale changes.

var _blocks: Array = []


## Creates a read-only code editor displaying a [lb]code_listing[rb] BBCode node's code.
static func make_code_listing(node: BBCodeParser.ParseNode) -> CodeEdit:
	const CODE_LISTING_SCENE := preload("res://ui/components/CodeListing.tscn")
	var listing: CodeEdit = CODE_LISTING_SCENE.instantiate()
	listing.text = BBCodeUtils.get_code_listing_text(node)
	return listing


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_children()


func set_blocks(blocks: Array) -> void:
	_blocks = blocks
	visible = not blocks.is_empty()
	_update_children()


func _update_children() -> void:
	if not is_node_ready():
		# Wait for ready when called from outside the tree, e.g. from setup().
		await ready
	for child: Node in get_children():
		remove_child.call_deferred(child)
		child.queue_free()
	var rtl := _get_text_alignment()
	for block: Variant in _blocks:
		if block is BBCodeParser.ParseNode:
			add_child.call_deferred(make_code_listing(block))
		else:
			add_child.call_deferred(_make_text_label(block, rtl))


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
