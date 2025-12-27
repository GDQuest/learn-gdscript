extends Node2D

@onready var tilemap := $TileMap as TileMap
@onready var tiles := $Tiles as Node2D

const shift := Vector2(10, 10)
var aligned_tracks: Array = []

# EXPORT fix
var tracks: Array[Sprite2D] = []

func fix_tracks() -> void:
	# Godot 4 supports negative indices in arrays natively
	align(tracks[-1])
	align(tracks[-3])
	align(tracks[-4])
# /EXPORT fix


func _ready() -> void:
	tilemap.hide()
	reset()
	if get_tree().current_scene == self:
		_run()


func reset() -> void:
	aligned_tracks = []
	remove_cells()
	copy_cells()


func remove_cells() -> void:
	tracks = []
	for child in tiles.get_children():
		child.queue_free()


func copy_cells() -> void:
	# Godot 4: get_used_cells now returns Array[Vector2i] (integer vectors)
	# It also requires a layer index (usually 0)
	for cell_pos in tilemap.get_used_cells(0):
		var source_id := tilemap.get_cell_source_id(0, cell_pos)
		var atlas_coords := tilemap.get_cell_atlas_coords(0, cell_pos)
		var alternative_tile := tilemap.get_cell_alternative_tile(0, cell_pos)
		
		var is_not_in_position := false
		# Original logic: if the tile index was 4, change to 2
		if source_id == 4:
			source_id = 2
			is_not_in_position = true
		
		# In Godot 4, TileMap logic is more complex, but to replicate the 
		# "Tile-inside-a-Sprite" behavior:
		var sub_tilemap = TileMap.new()
		sub_tilemap.tile_set = tilemap.tile_set
		# Godot 4 set_cell: (layer, coords, source_id, atlas_coords, alternative_tile)
		sub_tilemap.set_cell(0, Vector2i(0, 0), source_id, atlas_coords, alternative_tile)
		
		var sprite := Sprite2D.new()
		# map_to_world is now map_to_local
		sprite.position = tilemap.map_to_local(cell_pos)
		
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
	if aligned_tracks.is_empty():
		_complete_run()
		return

	var item = aligned_tracks.pop_front()
	
	if item is String:
		push_error(item)
		_realign_selected_sprites() # Continue to next
	elif item:
		var track := item as Sprite2D
		var target := track.position - shift
		
		# Godot 4 Tweens are created via create_tween() and are not nodes
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_BOUNCE)
		tween.set_ease(Tween.EASE_OUT)
		
		# tween_property(object, property, final_val, duration)
		tween.tween_property(track, "position", target, 1.0)
		
		# Connect to the finished signal to process the next sprite
		tween.finished.connect(_realign_selected_sprites)
	else:
		_complete_run()


func _complete_run() -> void:
	await get_tree().create_timer(0.5).timeout
	Events.practice_run_completed.emit()


func _run() -> void:
	reset()
	fix_tracks()
	_realign_selected_sprites()
