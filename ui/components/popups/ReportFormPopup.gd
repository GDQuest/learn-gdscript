extends CanvasLayer

@onready var _color_rect := $ColorRect as ColorRect
@onready var _panel := $PanelContainer as PanelContainer

@onready var _confirm_button := $PanelContainer/Column/Margin/Column/ConfirmButton as Button
@onready var _summary_label := $PanelContainer/Column/Margin/Column/Summary as RichTextLabel
@onready var _title_label := $PanelContainer/Column/Margin/Column/Title as Label

@onready var _title: String = _title_label.text
@onready var _summary: String = str(_summary_label.text)

func _on_confirm_pressed() -> void:
	hide_popup()
	
func _ready() -> void:
	hide_popup()
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_summary_label.meta_clicked.connect(_on_meta_clicked)
	_update_translations()

func show_popup() -> void:
	_color_rect.show()
	_panel.show()
	visible = true
	_confirm_button.grab_focus()

func hide_popup() -> void:
	visible = false
	_color_rect.hide()
	_panel.hide()

func _on_meta_clicked(data: Variant) -> void:
	if data is String:
		var link := data as String
		if link.begins_with("https://"):
			OS.shell_open(link)
		elif link == "download":
			if "download" in Log:
				Log.call("download")

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_translations()

func _update_translations() -> void:
	if _title_label:
		_title_label.text = tr(_title)
		_summary_label.text = tr(_summary)
