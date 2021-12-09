extends PracticeTester


func test_remove_errors() -> String:
	if "#" in _slice.get_main_lines():
		return "There's still a comment in your code. You need to remove the comment sign (#)."
	return ""
