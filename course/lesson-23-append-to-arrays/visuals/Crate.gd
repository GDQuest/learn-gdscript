extends Panel

signal used
signal restored

const FIRE := preload("res://course/lesson-24-access-array-indices/visuals/inventory/pickup_fire.png")
const GEM := preload("res://course/lesson-24-access-array-indices/visuals/inventory/pickup_gem.png")
const HEALTH := preload("res://course/lesson-24-access-array-indices/visuals/inventory/pickup_health.png")
const ICE := preload("res://course/lesson-24-access-array-indices/visuals/inventory/pickup_ice.png")
const LIGHTNING := preload("res://course/lesson-24-access-array-indices/visuals/inventory/pickup_lightning.png")

const textures = [
	FIRE,
	GEM,
	HEALTH,
	ICE,
	LIGHTNING
]

var texture: Texture setget set_texture, get_texture

onready var anim_player := $AnimationPlayer as AnimationPlayer
onready var texture_rect := $TextureRect as TextureRect
onready var label := $Label as Label

var _animation_backwards := false


func _ready() -> void:
	if texture == null:
		set_texture(textures[randi() % textures.size()])
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


func set_texture(new_texture: Texture) -> void:
	texture = new_texture
	if not is_inside_tree():
		yield(self, "ready")
	texture_rect.texture = new_texture
	
func get_texture() -> Texture:
	return texture

func get_texture_name():
	var path := texture.resource_path
	var filename := path.get_file().get_basename().split("_")
	filename.invert()
	return PoolStringArray(filename).join(" ")

func set_label_index(index: int) -> void:
	label.text = str(index)
