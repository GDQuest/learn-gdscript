extends Control


func _ready() -> void:
	for child in get_children():
		if child is RichTextLabel:
			NavigationManager.connect_rich_text_links(child)
