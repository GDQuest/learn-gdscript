extends CanvasLayer

onready var _color_rect := $ColorRect as ColorRect
onready var _panel := $PanelContainer as PanelContainer

onready var _confirm_button := $PanelContainer/Column/Margin/Column/ConfirmButton as Button
onready var _summary_label := $PanelContainer/Column/Margin/Column/Summary as RichTextLabel
onready var _title_label: Label = $PanelContainer/Column/Margin/Column/Title

onready var _title := _title_label.text
onready var _summary := _summary_label.bbcode_text


func _ready():
	hide()
	_confirm_button.connect("pressed", self, "hide")
	_summary_label.connect("meta_clicked", self, "_on_meta_clicked")
	_update_translations()

func show() -> void:
	_color_rect.show()
	_panel.show()


func hide() -> void:
	_confirm_button.grab_focus()
	_color_rect.hide()
	_panel.hide()


func _on_meta_clicked(data) -> void:
	if typeof(data) == TYPE_STRING:
		if data.begins_with("https://"):
			OS.shell_open(data)
		elif data == "download":
			Log.download()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_translations()


func _update_translations() -> void:
	if _title_label:
		_title_label.text = tr(_title)
		_summary_label.bbcode_text = tr(_summary)
