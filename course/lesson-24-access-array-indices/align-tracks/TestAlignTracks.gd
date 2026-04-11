extends PracticeTester


var game_board: Node2D
var expected_positions := {
	-1: Vector2(7, 6) * 64,
	-3: Vector2(5, 6) * 64,
	-4: Vector2(4, 6) * 64
}


func _prepare() -> void:
	game_board = _scene_root_viewport.get_child(0)


func _compare(track_index: int) -> String:
	var expected: Vector2 = expected_positions[track_index]
	var tracks: Array = game_board.tracks
	var track: Sprite2D = tracks[track_index]
	var received := track.position
	if received.is_equal_approx(expected):
		return ""
	return "Track %s is not correctly positioned! Expected: %s. Received: %s"%[track_index, expected, received]


func test_first_track_is_well_positioned() -> String:
	return _compare(expected_positions.keys()[0])


func test_second_track_is_well_positioned() -> String:
	return _compare(expected_positions.keys()[1])


func test_third_track_is_well_positioned() -> String:
	return _compare(expected_positions.keys()[2])


func test_all_other_tracks_are_aligned_to_grid() -> String:
	var tracks: Array = game_board.tracks
	for i in tracks.size():
		var track: Sprite2D = tracks[i]
		var x := int(track.position.x) % 32
		var y := int(track.position.y) % 32
		if (x + y) > 0:
			return "Track %s is not correctly aligned to the grid!"%[i]
	return ""
