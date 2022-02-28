extends Panel

signal used
signal restored

onready var anim_player := $AnimationPlayer as AnimationPlayer
onready var texture_rect := $TextureRect as TextureRect
onready var label := $Label as Label
var _animation_backwards := false

func _ready() -> void:
	label.text = str(get_index())
	anim_player.connect("animation_finished", self, "_on_animation_finished")


func use() -> void:
	anim_player.play("use")


func reset(speed := 2.0) -> void:
	show()
	if speed == 0:
		anim_player.play("RESET")
		return
	_animation_backwards = true
	anim_player.play("use", -1, -1 * speed, true)


func _on_animation_finished(animation_name: String) -> void:
	if animation_name != "use":
		return
	if _animation_backwards:
		_animation_backwards = false
		emit_signal("restored")
		return
	hide()
	emit_signal("used")
