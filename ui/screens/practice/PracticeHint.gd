@tool
class_name PracticeHint
extends Revealer

## Displays the hint as ordered content blocks: text chunks become
## RichTextLabels, code listings become read-only code editors.

@onready var _content_blocks: ContentBlocks = $ContentBlocks


## Displays the hint as ordered content blocks: text chunks become
## RichTextLabels, code listings become read-only code editors.
func set_blocks(blocks: Array) -> void:
	_content_blocks.set_blocks(blocks)
