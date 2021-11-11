extends Validator

enum TEST_TYPE { TEST_NONE, TEST_HIGHER, TEST_LOWER, TEST_BOTH, TEST_COMPARISON }

export (TEST_TYPE) var test_type := TEST_TYPE.TEST_NONE


func restore(menu, initial_score) -> void:
	menu.set_highest_score(initial_score)


func validate_scene_and_script(scene: Node, slice_properties: SliceProperties) -> void:
	if test_type == TEST_TYPE.TEST_COMPARISON:
		var uses_comparison = slice_properties.current_full_text.find(">") > -1
		if not verify(uses_comparison, "there's no comparison operator"):
			return
		_validation_success()
	if test_type == TEST_TYPE.TEST_NONE:
		_validation_success()
		return
	var menu = scene.get_node("Menu")
	var initial_score = menu._highest_score
	menu._highest_score = 10
	var higher_score = 11
	var lower_score = 9
	if test_type == TEST_TYPE.TEST_BOTH or test_type == TEST_TYPE.TEST_LOWER:
		menu.set_new_score_if_is_highest(lower_score)
		if not verify(menu._highest_score != lower_score, "lower score passed when it shouldn't"):
			restore(menu, initial_score)
			return
	if test_type == TEST_TYPE.TEST_BOTH or test_type == TEST_TYPE.TEST_HIGHER:
		menu.set_new_score_if_is_highest(higher_score)
		if not verify(menu._highest_score == higher_score, "higher score did not pass"):
			restore(menu, initial_score)
			return
	restore(menu, initial_score)
	_validation_success()
