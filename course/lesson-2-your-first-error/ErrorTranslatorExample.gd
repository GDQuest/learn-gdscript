extends MarginContainer

@onready var explanation := $MarginContainer/Column/Content/ErrorExplanation/Value as RichTextLabel
@onready var suggestion := $MarginContainer/Column/Content/ErrorSuggestion/Value as RichTextLabel


func _ready() -> void:
	var message := GDScriptErrorDatabase.get_message(GDScriptCodes.ErrorCode.DUPLICATE_DECLARATION)
	explanation.text = TextUtils.tr_paragraph(message.explanation)
	suggestion.text = TextUtils.tr_paragraph(message.suggestion)
