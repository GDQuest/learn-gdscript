extends PracticeTester


func test_rotating_character_is_time_dependent() -> String:
	var has_delta := _slice.current_text.rfind("delta") > 0
	var has_multiplication_sign := _slice.current_text.rfind("*") > 0
	var has_two := _slice.current_text.rfind("2") > 0
	var is_in_parentheses := _slice.current_text.strip_edges().rfind(")")

	if not has_delta:
		return "Did you use delta to make the rotation time-dependent?"
	elif not has_two:
		return "Is the rotation speed correct?"
	elif not has_multiplication_sign:
		return "We couldn't find a multiplication sign. Did you use it to make the rotation time-dependent?"
	elif not is_in_parentheses:
		return "Did you not multiply by delta inside the function call? You need to multiply inside the parentheses for delta to take effect."
	return ""
