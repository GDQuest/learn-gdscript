extends PanelContainer

signal loading_finished()
signal faded_in()
signal faded_out()

const FADING_DURATION := 0.5
const PROGRESS_DURATION := 0.75

enum State { IDLE, LOADING, FADING_IN, FADING_OUT }

var progress_value := 0.0 setget set_progress_value

var _state: int = State.IDLE

onready var _progress_bar := $MarginContainer/Control/ProgressBar as ProgressBar
onready var _tweener := $Tween as Tween


func _ready() -> void:
	_state = State.IDLE
	_progress_bar.value = 0.0

	_tweener.connect("tween_all_completed", self, "_on_tweener_finished")
	_animate_progress()


func set_progress_value(value: float) -> void:
	progress_value = clamp(value, 0.0, 1.0)
	
	if is_inside_tree():
		_animate_progress()


func reset_progress_value() -> void:
	progress_value = 0.0
	
	if is_inside_tree():
		_progress_bar.value = progress_value


func fade_in() -> void:
	_state = State.FADING_IN
	modulate.a = 0.0
	visible = true

	_tweener.stop_all()
	_tweener.interpolate_property(self, "modulate:a", 0.0, 1.0, FADING_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	_tweener.start()


func fade_out() -> void:
	_state = State.FADING_OUT

	_tweener.stop_all()
	_tweener.interpolate_property(self, "modulate:a", modulate.a, 0.0, FADING_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	_tweener.start()


func _animate_progress() -> void:
	if _state != State.IDLE:
		return
	
	_state = State.LOADING
	_tweener.stop_all()

	if _progress_bar.value == progress_value:
		_state = State.IDLE
		emit_signal("loading_finished")
		return

	_tweener.interpolate_property(_progress_bar, "value", _progress_bar.value, progress_value, PROGRESS_DURATION, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	_tweener.start()


func _on_tweener_finished() -> void:
	if _state == State.FADING_IN:
		emit_signal("faded_in")

		_state = State.IDLE
		_animate_progress()
	elif _state == State.FADING_OUT:
		emit_signal("faded_out")

		_state = State.IDLE
		visible = false

	elif _state == State.LOADING:
		if _progress_bar.value == _progress_bar.max_value:
			emit_signal("loading_finished")

		_state = State.IDLE
		fade_out()
