extends PanelContainer

signal loading_finished()
signal faded_in()
signal faded_out()

const FADING_DURATION := 0.5
const PROGRESS_DURATION := 0.75

enum State { IDLE, LOADING, FADING_IN, FADING_OUT }

var _progress_value: float = 0.0
var progress_value: float:
	set(value):
		set_progress_value(value)
	get:
		return _progress_value

var _state: int = State.IDLE
var _tween: Tween

func _kill_tween() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = null

@onready var _progress_bar := $MarginContainer/Control/ProgressBar as ProgressBar

func _ready() -> void:
	_state = State.IDLE
	_progress_bar.value = 0.0

	_animate_progress()


func set_progress_value(value: float) -> void:
	_progress_value = clamp(value, 0.0, 1.0)

	if is_inside_tree():
		_animate_progress()


func reset_progress_value() -> void:
	_progress_value = 0.0

	if is_inside_tree():
		_progress_bar.value = _progress_value


func fade_in() -> void:
	_state = State.FADING_IN
	modulate.a = 0.0
	visible = true

	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADING_DURATION)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)
	_tween.finished.connect(_on_tweener_finished)


func fade_out() -> void:
	_state = State.FADING_OUT

	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, FADING_DURATION)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)
	_tween.finished.connect(_on_tweener_finished)


func _animate_progress() -> void:
	if _state != State.IDLE:
		return

	_state = State.LOADING
	_kill_tween()

	if _progress_bar.value == progress_value:
		_state = State.IDLE
		loading_finished.emit()
		return

	_tween = create_tween()
	_tween.tween_property(_progress_bar, "value", progress_value, PROGRESS_DURATION)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)
	_tween.finished.connect(_on_tweener_finished)


func _on_tweener_finished() -> void:
	if _state == State.FADING_IN:
		faded_in.emit()
		_state = State.IDLE
		_animate_progress()

	elif _state == State.FADING_OUT:
		faded_out.emit()
		_state = State.IDLE
		visible = false

	elif _state == State.LOADING:
		if _progress_bar.value == _progress_bar.max_value:
			loading_finished.emit()

		_state = State.IDLE
		fade_out()
