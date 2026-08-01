extends Panel

signal used
signal restored

const SWORD := preload("res://course/common/inventory/sword.png")
const SHIELD := preload("res://course/common/inventory/shield.png")
const HEALTH := preload("res://course/common/inventory/healing_heart.png")
const GEMS := preload("res://course/common/inventory/gems.png")

const TEXTURES: Array[Texture2D] = [SWORD, SHIELD, HEALTH, GEMS]

@export var texture: Texture2D:
	get = get_texture, set = set_texture
@export var hide_after_animation := false

@onready var sprite := $Sprite2D as Sprite2D
@onready var label := $Label as Label

const USE_DURATION := 0.7
const LIFT_DURATION := 0.1
const LIFT_OFFSET := Vector2(0, -15)

var _animation_tween: Tween
var _sprite_position := Vector2.ZERO


func _ready() -> void:
	set_label_index(get_index())
	if texture == null:
		randomize()
		set_random_texture()
	_sprite_position = sprite.position


func set_random_texture():
	if get_index() > 0 and get_index() < TEXTURES.size():
		# ensure textures appear at least once each in the first loop
		var previous_crate = get_parent().get_child(get_index() - 1)
		if previous_crate and previous_crate.texture:
			var previous_texture_index := TEXTURES.find(previous_crate.texture)
			if previous_texture_index > -1:
				var next_index := (previous_texture_index + 1) % TEXTURES.size()
				set_texture(TEXTURES[next_index])
				return
	randomize_texture()


func randomize_texture():
	set_texture(TEXTURES[randi() % TEXTURES.size()])


func use() -> void:
	_stop_animation()
	show()
	var tween := create_tween()
	tween.tween_property(sprite, "position", _sprite_position + LIFT_OFFSET, LIFT_DURATION)
	tween.tween_property(sprite, "position", _sprite_position, USE_DURATION - LIFT_DURATION)
	tween.parallel().tween_property(self, "modulate:a", 0.0, USE_DURATION - LIFT_DURATION)
	tween.finished.connect(_on_use_finished)
	_animation_tween = tween


func reset(speed := 2.0) -> void:
	_stop_animation()
	show()
	if speed == 0:
		sprite.position = _sprite_position
		modulate.a = 1.0
		return
	sprite.position = _sprite_position + LIFT_OFFSET
	modulate.a = 0.0
	var tween := create_tween()
	var duration := USE_DURATION / speed
	tween.tween_property(sprite, "position", _sprite_position, LIFT_DURATION / speed)
	tween.tween_property(sprite, "position", _sprite_position, duration - LIFT_DURATION / speed)
	tween.parallel().tween_property(self, "modulate:a", 1.0, duration - LIFT_DURATION / speed)
	tween.finished.connect(restored.emit)
	_animation_tween = tween


func set_texture(new_texture: Texture2D) -> void:
	texture = new_texture
	if not is_inside_tree():
		await self.ready
	sprite.texture = new_texture


func get_texture() -> Texture2D:
	return texture


func get_texture_name():
	var path := texture.resource_path
	var filename := path.get_file().get_basename().split("_")
	return " ".join(PackedStringArray(filename))


func set_label_index(index: int) -> void:
	label.text = str(index)


func _stop_animation() -> void:
	if _animation_tween:
		_animation_tween.kill()
	_animation_tween = null


func _on_use_finished() -> void:
	if hide_after_animation:
		hide()
	used.emit()
