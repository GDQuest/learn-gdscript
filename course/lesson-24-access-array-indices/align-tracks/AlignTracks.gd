extends Node2D

onready var tilemap := $TileMap as TileMap
onready var tiles := $Tiles as Node2D

const shift := Vector2(10, 10)
var aligned_tracks := []


func _ready() -> void:
	tilemap.hide()
	reset()
	if get_tree().get_current_scene() == self:
		_run()


func reset():
	aligned_tracks = []
	remove_cells()
	copy_cells()


func remove_cells():
	tracks = []
	for child in tiles.get_children():
		child.queue_free()


func copy_cells():
	for cell_pos in tilemap.get_used_cells():
		var x := int(cell_pos.x)
		var y := int(cell_pos.y)
		var cell := tilemap.get_cell(x, y)
		var is_transposed := tilemap.is_cell_transposed(x, y)
		var is_x_flipped := tilemap.is_cell_x_flipped(x, y)
		var is_y_flipped := tilemap.is_cell_y_flipped(x, y)
		var sub_tilemap = TileMap.new()
		var is_not_in_position := false
		if cell == 4:
			cell = 2
			is_not_in_position = true
		sub_tilemap.tile_set = tilemap.tile_set
		sub_tilemap.set_cell(0, 0, cell, is_x_flipped, is_y_flipped, is_transposed)
		var sprite := Sprite.new()
		sprite.position = tilemap.map_to_world(cell_pos)
		if is_not_in_position:
			sprite.position += shift
		sprite.add_child(sub_tilemap)
		tiles.add_child(sprite)
		tracks.append(sprite)


func align(track: Sprite) -> void:
	if track == null:
		aligned_tracks.append("You tried to align a track that doesn't exist. Make sure your indices make sense")
	else:
		aligned_tracks.append(track)


func _realign_selected_sprites() -> void:
	var item = aligned_tracks.pop_front()
	if item is String:
		push_error(item)
	elif item:
		var track := item as Sprite
		var tween := Tween.new()
		track.add_child(tween)
		var initial := track.position
		var target := initial - shift
		tween.connect("tween_all_completed", self, "_realign_selected_sprites")
		tween.connect("tween_all_completed", tween, "queue_free")
		tween.interpolate_property(track, "position", initial, target, 1, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
		tween.start()
	else:
		_complete_run()


func _complete_run() -> void:
	yield(get_tree().create_timer(0.5), "timeout")
	Events.emit_signal("practice_run_completed")


func _run():
	reset()
	fix_tracks()
	_realign_selected_sprites()


# EXPORT fix
var tracks = []

func fix_tracks():
	align(tracks[-1])
	align(tracks[-3])
	align(tracks[-4])
# /EXPORT fix
