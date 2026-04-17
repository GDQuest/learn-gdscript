extends Control

signal course_requested(force_outliner)

@export var _settings_button: Button
@export var _outliner_button: Button
@export var _start_button: Button
@export var _quit_button: Button
@export var _title_link_label: RichTextLabel
@export var _anim_player: AnimationPlayer
@export var _robot: Node2D
@export var _gdquest_boy: Control

@onready var _buttons_to_disable := [_settings_button, _outliner_button, _start_button, _quit_button]


func _init() -> void:
	randomize()


func _ready() -> void:
	for button: BaseButton in _buttons_to_disable:
		button.disabled = true

	_settings_button.pressed.connect(Events.settings_requested.emit)
	_outliner_button.pressed.connect(_on_outliner_pressed)
	_start_button.pressed.connect(_on_start_requested)
	_quit_button.pressed.connect(get_tree().quit)
	_title_link_label.meta_clicked.connect(_on_meta_clicked)

	_start_button.grab_focus()

	if OS.has_feature('web'):
		_quit_button.queue_free()

	_anim_player.animation_finished.connect(_on_animation_finished)
	visibility_changed.connect(_on_welcome_screen_visibility_changed)


func appear() -> void:
	_anim_player.play("appear")


func _on_welcome_screen_visibility_changed() -> void:
	if not visible:
		return
	if _gdquest_boy.modulate.a < 1.0 and (_anim_player.current_animation != "appear" or not _anim_player.is_playing()):
		appear()


func set_button_continue(enable: bool = true) -> void:
	if enable:
		_start_button.text = tr("CONTINUE")
	else:
		_start_button.text = tr("START")


func _on_outliner_pressed() -> void:
	emit_signal("course_requested", true)


func _on_start_requested() -> void:
	emit_signal("course_requested", false)


func _on_animation_finished(_anim_name: String) -> void:
	for button in _buttons_to_disable:
		button.disabled = false
	@warning_ignore("unsafe_method_access")
	_robot.appear()


func _on_meta_clicked(data) -> void:
	if typeof(data) == TYPE_STRING:
		var data_string: String = data
		if data_string.begins_with("https://"):
			OS.shell_open(data_string)
