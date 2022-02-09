extends PracticeTester


func test_moving_in_a_circle_is_time_dependent() -> String:
	var has_delta := _slice.current_text.rfind("delta") > 0
	var has_multiplication_sign := _slice.current_text.rfind("*") > 0
	var has_two := _slice.current_text.rfind("2") > 0
	var has_hundred := _slice.current_text.rfind("100") > 0
	var ends_width_parenthesis := _slice.current_text.strip_edges().rfind(")")

	if not has_delta:
		return "Did you use delta to make the rotation time-dependent?"
	elif not has_two:
		return "Is the rotation speed correct?"
	elif not has_hundred:
		return "Is the movement speed correct?"
	elif not has_multiplication_sign:
		return "Did you use spaces between *?"
	elif not ends_width_parenthesis:
		return "Did you not multiply by delta inside the function call? You need to multiply inside the parentheses for delta to take effect."
	return ""
