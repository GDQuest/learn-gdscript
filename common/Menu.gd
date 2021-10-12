extends VBoxContainer

# warning-ignore:unused_signal
signal request_play

onready var _play_button := $PlayButton as Button
onready var _exit_button := $ExitButton as Button
onready var _highest_score_label := $HBoxContainer/HighScoreLabel as Label

var _highest_score := 0


func _ready() -> void:
	_play_button.connect("pressed", self, "emit_signal", ["request_play"])
	_exit_button.connect("pressed", get_tree(), "quit")
	set_focus()


func set_highest_score(new_highest_score: int) -> void:
	_highest_score = new_highest_score
	if not is_inside_tree():
		yield(self, "ready")
	_highest_score_label.text = String(new_highest_score).pad_zeros(5)


# Sets a higher score if the passed integer is higher than the current
# highest score
# EXPORT set_score_if_highest
func set_new_score_if_is_highest(maybe_highest_score: int) -> void:
	if maybe_highest_score > _highest_score:
		set_highest_score(maybe_highest_score)


# /EXPORT set_score_if_highest


func set_focus() -> void:
	grab_focus()
	_play_button.grab_focus()
