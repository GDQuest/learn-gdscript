extends PracticeTester


var game_board: Node2D
var tracks := []
var expected_positions := {
	1: Vector2(96, 32),
	8: Vector2(32, 160)
}


func _prepare() -> void:
	game_board = _scene_root_viewport.get_child(0)
	tracks = game_board.tracks

func _compare(track_index: int) -> String:
	var expected: Vector2 = expected_positions[track_index]
	var track: Sprite = tracks[track_index]
	var received := track.position
	if received.is_equal_approx(expected):
		return ""
	return "Track %s is not correctly positioned! Expected: %s. Received: %s"%[track_index, expected, received]


func test_first_track_is_well_positioned() -> String:
	return _compare(expected_positions.keys()[0])


func test_second_track_is_well_positioned() -> String:
	return _compare(expected_positions.keys()[1])

func test_tracks_are_aligned() -> String:
	for i in tracks.size():
		var track: Sprite = tracks[i]
		var x := int(track.position.x) % 32
		var y := int(track.position.y) % 32
		if (x + y) > 0:
			return "Track %s is not correctly aligned to the grid!"%[i]
	return ""
