extends Panel

signal used
signal restored

const SWORD := preload("res://course/common/inventory/sword.png")
const SHIELD := preload("res://course/common/inventory/shield.png")
const HEALTH := preload("res://course/common/inventory/healing_heart.png")
const GEMS := preload("res://course/common/inventory/gems.png")

const textures = [
	SWORD,
	SHIELD,
	HEALTH,
	GEMS
]


@export var texture: Texture2D: get = get_texture, set = set_texture
@export var hide_after_animation := false

@onready var anim_player := $AnimationPlayer as AnimationPlayer
@onready var texture_rect := $TextureRect as TextureRect
@onready var label := $Label as Label

var _animation_backwards := false


func _ready() -> void:
	set_label_index(get_index())
	if texture == null:
		randomize()
		set_random_texture()
	anim_player.connect("animation_finished", Callable(self, "_on_animation_finished"))


func set_random_texture():
	if get_index() > 0 and get_index() < textures.size():
		# ensure textures appear at least once each in the first loop
		var previous_crate = get_parent().get_child(get_index() - 1)
		if previous_crate and previous_crate.texture:
			var previous_texture_index := textures.find(previous_crate.texture)
			if previous_texture_index > -1:
				var next_index := (previous_texture_index + 1) % textures.size()
				set_texture(textures[next_index])
				return
	randomize_texture()

func randomize_texture():
	set_texture(textures[randi() % textures.size()])
	
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
	if hide_after_animation:
		hide()
	emit_signal("used")


func set_texture(new_texture: Texture2D) -> void:
	texture = new_texture
	if not is_inside_tree():
		await self.ready
	texture_rect.texture = new_texture
	
func get_texture() -> Texture2D:
	return texture

func get_texture_name():
	var path := texture.resource_path
	var filename := path.get_file().get_basename().split("_")
	return " ".join(PackedStringArray(filename))

func set_label_index(index: int) -> void:
	label.text = str(index)
