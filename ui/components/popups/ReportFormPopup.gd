extends CanvasLayer

onready var _color_rect := $ColorRect as ColorRect
onready var _panel := $PanelContainer as PanelContainer

onready var _confirm_button := $PanelContainer/Column/Margin/Column/ConfirmButton as Button
onready var _summary_label := $PanelContainer/Column/Margin/Column/Summary as RichTextLabel


func _ready():
	hide()
	_confirm_button.connect("pressed", self, "hide")
	_summary_label.connect("meta_clicked", self, "_on_meta_clicked")


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
