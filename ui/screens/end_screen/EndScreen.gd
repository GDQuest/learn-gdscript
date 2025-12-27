extends Control

const COURSE_URL := "https://school.gdquest.com/products/godot-4-early-access"

@onready var _outliner_button := $Layout/TopBar/MarginContainer/ToolBarLayout/OutlinerButton as Button
@onready var _learn_more_button := $Layout/CenterRow/Panel/Margin/Column/Control2/LearnMoreButton as Button


func _ready() -> void:
	# FIX: Godot 4 signal syntax
	_outliner_button.pressed.connect(_on_outliner_button_pressed)
	
	# Typed loop to avoid "Unsafe" warnings
	var labels: Array[RichTextLabel] = [
		$Layout/CenterRow/Panel/Margin/Column/VBoxContainer2/VBoxContainer/RichTextLabel3,
		$Layout/CenterRow/Panel/Margin/Column/VBoxContainer3/RichTextLabel4
	]
	
	for node: RichTextLabel in labels:
		node.meta_clicked.connect(OS.shell_open)
	
	# Use .bind() to pass the URL argument
	_learn_more_button.pressed.connect(OS.shell_open.bind(COURSE_URL))
	_learn_more_button.button_down.connect(_learn_more_button_button_down)
	_learn_more_button.button_up.connect(_learn_more_button_button_up)


func _input(event: InputEvent) -> void:
	# Check if button is held and mouse is moving
	if _learn_more_button.button_pressed and event is InputEventMouseMotion:
		# rect_position -> position
		if not _learn_more_button.get_global_rect().has_point(get_global_mouse_position()):
			_learn_more_button.position.y = 0
		else:
			_learn_more_button.position.y = 4


func _on_outliner_button_pressed() -> void:
	# emit_signal -> .emit()
	NavigationManager.outliner_navigation_requested.emit()
	hide()


func _learn_more_button_button_down() -> void:
	_learn_more_button.position.y = 4
	

func _learn_more_button_button_up() -> void:
	_learn_more_button.position.y = 0
