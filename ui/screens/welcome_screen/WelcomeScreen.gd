extends Control

signal course_requested(force_outliner)

onready var _settings_button := $GDQuestBoy/Margin/Buttons/SettingsButton as Button
onready var _outliner_button := $GDQuestBoy/Margin/Buttons/OutlinerButton as Button
onready var _start_button := $GDQuestBoy/Margin/Buttons/StartButton as Button
onready var _quit_button := $GDQuestBoy/Margin/Buttons/QuitButton as Button

onready var _anim_player:= $AnimationPlayer as AnimationPlayer
onready var _robot := $Robot

onready var _buttons_to_disable := [_settings_button, _outliner_button, _start_button, _quit_button]

func _init() -> void:
	randomize()


func _ready() -> void:
	for button in _buttons_to_disable:
		button.disabled = true

	_settings_button.connect("pressed", Events, "emit_signal", ["settings_requested"])
	_outliner_button.connect("pressed", self, "_on_outliner_pressed")
	_start_button.connect("pressed", self, "_on_start_requested")
	_quit_button.connect("pressed", get_tree(), "quit")
	
	_start_button.grab_focus()
	
	if OS.has_feature('JavaScript'):
		_quit_button.queue_free()
	
	_anim_player.connect("animation_finished", self, "_on_animation_finished")


func appear() -> void:
	_anim_player.play("appear")


func set_button_continue(enable: bool = true) -> void:
	if enable:
		_start_button.text = tr("CONTINUE")
	else:
		_start_button.text = tr("START")


func _on_outliner_pressed() -> void:
	emit_signal("course_requested", true)


func _on_start_requested() -> void:
	emit_signal("course_requested", false)


func _on_animation_finished(anim_name: String) -> void:
	for button in _buttons_to_disable:
		button.disabled = false
	_robot.appear()
	
