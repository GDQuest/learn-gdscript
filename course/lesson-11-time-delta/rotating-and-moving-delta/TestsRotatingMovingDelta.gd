extends PracticeTester


func test_moving_in_a_circle_is_time_dependent() -> String:
	var has_delta := _slice.current_text.rfind("delta") > 0
	var has_spaces := _slice.current_text.rfind(" * ") > 0
	var has_two := _slice.current_text.rfind("2") > 0
	var has_hundred := _slice.current_text.rfind("100") > 0

	if not has_delta:
		return "Did you use delta to make the rotation time-dependent?"
	elif not has_two:
		return "Is the rotation speed correct?"
	elif not has_hundred:
		return "Is the movement speed correct?"
	elif not has_spaces:
		return "Did you use spaces between *?"
	elif not _slice.current_text.match(_slice.get_slice_text()):
		return "There's something wrong here."

	return ""
