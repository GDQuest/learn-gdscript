extends ColorRect

onready var _confirm_button := $PanelContainer/Column/Margin/Column/ConfirmButton as Button
onready var _summary_label := $PanelContainer/Column/Margin/Column/Summary as RichTextLabel


func _ready():
	_confirm_button.connect("pressed", self, "hide")
	_summary_label.connect("meta_clicked", self, "_on_meta_clicked")
	connect("visibility_changed", self, "_on_visibility_changed")


func _on_meta_clicked(data) -> void:
	if typeof(data) == TYPE_STRING:
		if data.begins_with("https://"):
			OS.shell_open(data)
		elif data == "download":
			Log.download()


func _on_visibility_changed() -> void:
	if visible:
		_confirm_button.grab_focus()
