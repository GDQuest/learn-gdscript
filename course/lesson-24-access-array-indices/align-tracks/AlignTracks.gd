extends Node2D

@onready var tilemap := $TileMap as TileMapLayer
@onready var tiles := $Tiles as Node2D

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
	
	for cell_pos: Vector2i in tilemap.get_used_cells():
		var cell := tilemap.get_cell_source_id(cell_pos)
		var tile_alternative := tilemap.get_cell_alternative_tile(cell_pos)
		var atlas_coords := tilemap.get_cell_atlas_coords(cell_pos)
		
		var sub_tilemap := TileMapLayer.new()
		var is_not_in_position := false
		if cell == 9:
			cell = 5
			tile_alternative = 4
			is_not_in_position = true
		sub_tilemap.tile_set = tilemap.tile_set
		sub_tilemap.set_cell(Vector2i(0, 0), cell, atlas_coords, tile_alternative)
		
		var sprite := Sprite2D.new()
		sprite.position = tilemap.map_to_local(cell_pos) - Vector2(tilemap.tile_set.tile_size/2)
		if is_not_in_position:
			sprite.position += shift
		sprite.add_child(sub_tilemap)
		tiles.add_child(sprite)
		tracks.append(sprite)


func align(track: Sprite2D) -> void:
	if track == null:
		aligned_tracks.append("You tried to align a track that doesn't exist. Make sure your indices make sense")
	else:
		aligned_tracks.append(track)


func _realign_selected_sprites() -> void:
	var item = aligned_tracks.pop_front()
	if item is String:
		push_error(item)
	elif item:
		var track := item as Sprite2D
		var tween := create_tween()
		var initial := track.position
		var target := initial - shift
		tween.finished.connect(_realign_selected_sprites)
		tween.tween_property(track, "position", target, 1).from(initial).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	else:
		_complete_run()


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
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
