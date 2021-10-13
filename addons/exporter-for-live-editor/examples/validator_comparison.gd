extends Validator


func restore(menu, initial_score) -> void:
	menu.set_highest_score(initial_score)


func validate(scene: Node, _script: ScriptHandler, _slice: ScriptSlice):
	var menu = scene.get_node("Menu")
	var initial_score = menu._highest_score
	menu._highest_score = 10
	var higher_score = 11
	var lower_score = 9
	menu.set_new_score_if_is_highest(lower_score)
	if not verify(menu._highest_score != lower_score, "lower score passed when it shouldn't"):
		restore(menu, initial_score)
		return
	menu.set_new_score_if_is_highest(higher_score)
	if not verify(menu._highest_score == higher_score, "higher score did not pass"):
		restore(menu, initial_score)
		return
	restore(menu, initial_score)
	_validation_success()
