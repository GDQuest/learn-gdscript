extends PracticeTester


func test_character_is_visible() -> String:
	if not _scene_root_viewport.get_child(0).visible:
		return "The character is still invisible! Did you call the show() function?"
	return ""
