extends MarginContainer

@onready var _error_label: Label = %ErrorLabel
@onready var _explanation: RichTextLabelRTL = %ErrorExplanationValue
@onready var _suggestion: RichTextLabelRTL = %ErrorSuggestionValue


func _ready() -> void:
	# There was an issue with inherited scenes losing overridden properties, so I'm now using this script to force the text to properly display every time.
	_error_label.text = "The identifier \"angular_speed\" isn't declared in the current scope (at line 6)."
	_explanation.text = tr("The [code]set_angular_speed()[/code] function can't use the [code]angular_speed[/code] variable because it isn't script-wide. It also isn't in the [code]set_angular_speed()[/code] function.")
	_suggestion.text = tr("Make sure you define the [code]angular_speed[/code] variable in the [code]set_angular_speed()[/code] function, or define it outside of functions so it's script-wide.")
