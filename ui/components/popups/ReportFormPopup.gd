extends CanvasLayer

@onready var _color_rect := %ColorRect as ColorRect
@onready var _panel := %PanelContainer as PanelContainer

@onready var _close_button := %CloseButton as Button
@onready var _send_button := %SendButton as Button
@onready var _category_option := %CategoryOption as OptionButton
@onready var _description := %Description as TextEdit
@onready var _help_label := %Help as RichTextLabel
@onready var _translation_guidance := %TranslationGuidance as RichTextLabel
@onready var _title_label: Label = %Title

@onready var _title := _title_label.text

var _context := ReportContext.new()


func _ready():
	hide()
	_close_button.pressed.connect(hide)
	_send_button.pressed.connect(_send_report)
	_category_option.item_selected.connect(
		func _on_category_selected(category_index: int) -> void:
			_update_description_guidance(category_index)
			_update_translation_guidance(category_index),
	)
	_help_label.meta_clicked.connect(_on_meta_clicked)
	_translation_guidance.meta_clicked.connect(_on_meta_clicked)
	_update_translations()
	visibility_changed.connect(
		func _on_visibility_changed() -> void:
			if visible:
				_color_rect.show()
				_panel.show()
				_category_option.grab_focus()
			else:
				_color_rect.hide()
				_panel.hide(),
	)


## Initializes the form content with context from the currently visible screen.
func setup(context: ReportContext) -> void:
	_context = context
	_description.clear()
	_update_description_guidance(_category_option.selected)
	_update_translation_guidance(_category_option.selected)

	const DISCORD_URL := "https://discord.gg/bNj469SYQj"
	_help_label.text = (
		tr(
			"Select the kind of issue and describe it in the box below, then click \"Send report\" to open the contact page on our website with the report prefilled."
		)
		+ "\n\n"
		+ tr(
			"For questions and help with learning, [url=%s]join the community on Discord[/url]."
			% DISCORD_URL
		)
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_translations()


func _on_meta_clicked(data) -> void:
	if typeof(data) == TYPE_STRING:
		var string_data: String = data
		if string_data.begins_with("https://"):
			OS.shell_open(string_data)


func _send_report() -> void:
	const SUBJECTS := [
		"Bug report",
		"Unclear or incorrect content",
		"Improvement suggestion",
		"Translation issue",
	]
	var subject := "Learn GDScript From Zero: %s" % SUBJECTS[_category_option.selected]

	var body := _description.text.strip_edges() + "\n\n"

	var platform := ""
	if OS.has_feature("web"):
		platform = "Web"
	if OS.has_feature("windows"):
		platform = "Windows"
	if OS.has_feature("macos"):
		platform = "macOS"
	if OS.has_feature("linux"):
		platform = "Linux"
	_context.platform = _context.platform if not _context.platform.is_empty() else platform
	_context.commit_hash = AppVersion.git_commit.substr(0, 7)

	const INDEX_TRANSLATION_ISSUE_TYPE := 3
	if _category_option.selected == INDEX_TRANSLATION_ISSUE_TYPE:
		var language_code := TranslationManager.current_language
		var language_name: String = TranslationManager.LOCALE_TO_LABEL.get(
			language_code,
			TranslationServer.get_locale_name(language_code),
		)
		_context.selected_language = "%s (%s)" % [language_name, language_code]
	body += _context.build_email_context()
	if not _context.user_code.is_empty():
		body += "\nCode from the current practice\n```gdscript\n%s\n```\n" % _context.user_code
	const SUPPORT_EMAIL := "support@gdquest.com"
	OS.shell_open(
		"https://school.gdquest.com/about-us/contact?subject=%s&message=%s"
		% [subject.uri_encode(), body.uri_encode()]
	)
	hide()


func _update_description_guidance(category_index: int) -> void:
	var guidance: Array[String] = [
		"Describe what went wrong, what you were doing, and what you expected to happen.",
		"Type or copy paste a piece of the text that is unclear or incorrect and optionally tell us what you understood if it confused you.",
		"Describe what you would like to see improved and how it would help you.",
		"Tell us what is not translated correctly or what is not translated at all.",
	]
	_description.placeholder_text = tr(guidance[category_index])


func _update_translation_guidance(category_index: int) -> void:
	_translation_guidance.visible = category_index == 3
	const TRANSLATION_GUIDE_URL := "https://github.com/GDQuest/learn-gdscript-translations/#readme"
	if _translation_guidance.visible:
		_translation_guidance.text = tr(
			"Translations are unofficial and maintained by the community. If you'd like to help, [url=%s]learn how to help translate the app[/url]."
			% TRANSLATION_GUIDE_URL
		)


func _update_translations() -> void:
	if _title_label:
		_title_label.text = tr(_title)
		_update_description_guidance(_category_option.selected)
		_update_translation_guidance(_category_option.selected)
