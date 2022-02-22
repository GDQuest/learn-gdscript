extends PracticeTester


func test_remove_errors() -> String:
	for line in _slice.get_main_lines():
		if "#" in line:
			return tr("There's still a comment in your code. You need to remove the comment sign (#).")
	return ""
