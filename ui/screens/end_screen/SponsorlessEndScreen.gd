extends Control

@onready var _outliner_button: BaseButton = $Layout/TopBar/MarginContainer/ToolBarLayout/OutlinerButton
@onready var _rich_text_labels: Array[RichTextLabel] = [
	$Layout/PanelContainer/Sky/Control/Panel/Margin/ScrollContainer/Column/RichTextLabel,
	$Layout/PanelContainer/Sky/Control/Panel/Margin/ScrollContainer/Column/RichTextLabel2,
]


func _ready() -> void:
	_outliner_button.pressed.connect(_on_outliner_button_pressed)
	for rtl: RichTextLabel in _rich_text_labels:
		rtl.meta_clicked.connect(_on_meta_clicked)



func _on_outliner_button_pressed() -> void:
	NavigationManager.outliner_navigation_requested.emit()
	hide()


func _on_meta_clicked(data) -> void:
	if data is String:
		OS.shell_open(data as String)
