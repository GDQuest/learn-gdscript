extends Control

@onready var _outliner_button := $Layout/TopBar/MarginContainer/ToolBarLayout/OutlinerButton
@onready var _rich_text_labels := [
	$Layout/PanelContainer/Sky/Control/Panel/Margin/ScrollContainer/Column/RichTextLabel,
	$Layout/PanelContainer/Sky/Control/Panel/Margin/ScrollContainer/Column/RichTextLabel2,
]

func _ready() -> void:
	_outliner_button.connect("pressed", Callable(self, "_on_outliner_button_pressed"))
	for rtl in _rich_text_labels:
		rtl.connect("meta_clicked", Callable(self, "_on_meta_clicked"))


func _on_outliner_button_pressed() -> void:
	NavigationManager.emit_signal("outliner_navigation_requested")
	hide()


func _on_meta_clicked(data) -> void:
	if typeof(data) == TYPE_STRING:
		OS.shell_open(data)
