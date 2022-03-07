extends MarginContainer

onready var explanation := $MarginContainer/Column/Content/ErrorExplanation/Value as RichTextLabel
onready var suggestion := $MarginContainer/Column/Content/ErrorSuggestion/Value as RichTextLabel


func _ready() -> void:
	var message := GDScriptErrorDatabase.get_message(GDScriptCodes.ErrorCode.DUPLICATE_DECLARATION)
	explanation.bbcode_text = tr(message.explanation)
	suggestion.bbcode_text = tr(message.suggestion)
