extends Panel

signal used
signal restored

# Godot 4 uses Texture2D for UI textures
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

# Godot 4 Property syntax replacing setget
@export var texture: Texture2D:
	set(value):
		texture = value
		if not is_inside_tree():
			await ready
		if texture_rect:
			texture_rect.texture = value
	get:
		return texture

@export var hide_after_animation := false

@onready var anim_player := $AnimationPlayer as AnimationPlayer
@onready var texture_rect := $TextureRect as TextureRect
@onready var label := $Label as Label

var _animation_backwards := false


func _ready() -> void:
	set_label_index(get_index())
	if texture == null:
		# Note: In Godot 4, randomize() is called automatically on startup, 
		# but you can still call it if you need a specific seed reset.
		set_random_texture()
	
	# Godot 4 Signal connection syntax
	anim_player.animation_finished.connect(_on_animation_finished)


func set_random_texture() -> void:
	if get_index() > 0 and get_index() < textures.size():
		# ensure textures appear at least once each in the first loop
		var parent = get_parent()
		if parent:
			var previous_crate = parent.get_child(get_index() - 1)
			if previous_crate and previous_crate.texture:
				var previous_texture_index := textures.find(previous_crate.texture)
				if previous_texture_index > -1:
					var next_index := (previous_texture_index + 1) % textures.size()
					texture = textures[next_index]
					return
	randomize_texture()


func randomize_texture() -> void:
	texture = textures[randi() % textures.size()]
	

func use() -> void:
	anim_player.play("use")


func reset(speed := 2.0) -> void:
	show()
	if speed == 0:
		anim_player.play("RESET")
		return
	_animation_backwards = true
	# play(name, custom_blend, custom_speed, from_end)
	anim_player.play("use", -1, -1.0 * speed, true)


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != &"use":
		return
	if _animation_backwards:
		_animation_backwards = false
		restored.emit()
		return
	if hide_after_animation:
		hide()
	used.emit()


func get_texture_name() -> String:
	if not texture:
		return ""
	var path := texture.resource_path
	var filename_parts := path.get_file().get_basename().split("_")
	# Godot 4: join is now a method of the string separator
	return " ".join(PackedStringArray(filename_parts))


func set_label_index(index: int) -> void:
	label.text = str(index)
