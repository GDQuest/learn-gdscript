extends PracticeTester


func test_character_is_visible() -> String:
	var node_2d := _scene_root_viewport.get_child(0) as Node2D
	if not node_2d.visible:
		return tr("The character is still invisible! Did you call the show() function?")
	return ""
