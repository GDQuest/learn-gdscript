extends Control

const COURSE_URL := "https://school.gdquest.com/products/godot-4-early-access"

onready var _outliner_button := $Layout/TopBar/MarginContainer/ToolBarLayout/OutlinerButton
onready var _learn_more_button := $Layout/CenterRow/Panel/Margin/Column/Control2/LearnMoreButton


func _ready() -> void:
	_outliner_button.connect("pressed", self, "_on_outliner_button_pressed")
	for node in [$Layout/CenterRow/Panel/Margin/Column/VBoxContainer2/VBoxContainer/RichTextLabel3, $Layout/CenterRow/Panel/Margin/Column/VBoxContainer3/RichTextLabel4]:
		node.connect("meta_clicked", OS, "shell_open")
	_learn_more_button.connect("pressed", OS, "shell_open", [COURSE_URL])
	_learn_more_button.connect("button_down", self, "_learn_more_button_button_down")
	_learn_more_button.connect("button_up", self, "_learn_more_button_button_up")


func _input(event: InputEvent) -> void:
	if _learn_more_button.pressed and event is InputEventMouseMotion:
		if not _learn_more_button.get_global_rect().has_point(get_global_mouse_position()):
			_learn_more_button.rect_position.y = 0
		else:
			_learn_more_button.rect_position.y = 4


func _on_outliner_button_pressed() -> void:
	NavigationManager.emit_signal("outliner_navigation_requested")
	hide()


func _learn_more_button_button_down():
	_learn_more_button.rect_position.y = 4
	

func _learn_more_button_button_up():
	_learn_more_button.rect_position.y = 0
