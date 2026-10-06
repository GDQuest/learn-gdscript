extends MarginContainer

@onready var explanation: RichTextLabelRTL = %ErrorExplanationValue
@onready var suggestion: RichTextLabelRTL = %ErrorSuggestionValue


func _ready() -> void:
	var message := GDScriptErrorDatabase.get_message(GDScriptCodes.ErrorCode.DUPLICATE_DECLARATION)

	if message:
		explanation.text = TextUtils.tr_paragraph(message.explanation)
		suggestion.text = TextUtils.tr_paragraph(message.suggestion)
	else:
		explanation.text = ""
		suggestion.text = ""
