extends PracticeTester

var permutations = [
	PackedStringArray(["sword", "shield"]),
	PackedStringArray(["shield", "sword"])
]

var game_board: Control

func _prepare() -> void:
	game_board = _scene_root_viewport.get_child(0)


func test_correct_items_have_been_picked() -> String:
	var received = game_board.used_items_names
	for expected in permutations:
		if received == expected:
			return ""
	return "The picked items are wrong! Expected: %s; received: %s"%[permutations[0], received]


func test_picked_correct_item_amount() -> String:
	var received: PackedStringArray = game_board.used_items_names
	if received.size() != 2:
		return "We expected 2 items to be picked. Instead, we got %s."%[received.size()]
	return ""
