extends Validator

func validate(scene: Node, _script: ScriptHandler, _slice: ScriptSlice):
	var dispenser := scene.get_node("Level").find_node("ObstaclesDispenser", false)
	if not verify(
		dispenser.has_method("get_random_obstacle"),
		"dispenser does not have a `get_random_obstacle` method"
	):
		return
	var cache := {}
	# warning-ignore:unsafe_property_access
	for obstacle in dispenser._obstacles:
		cache[obstacle] = 0
	seed(0)
	var correct_result = [163, 164, 165, 167, 168, 173]
	for iteration in 1000:
		# warning-ignore:unsafe_method_access
		var obstacle = dispenser.get_random_obstacle()
		cache[obstacle] += 1
	var values := cache.values()
	values.sort()
	for index in correct_result.size():
		var correct_value = correct_result[index]
		var value = values[index]
		var is_same = correct_value == value
		if not verify(is_same, "method does not seem to be random"):
			return
	_validation_success()
