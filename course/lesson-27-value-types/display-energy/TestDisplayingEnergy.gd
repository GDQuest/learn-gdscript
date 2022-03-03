extends PracticeTester

var node: Node


func _prepare():
	node = _scene_root_viewport.get_child(0)


func test_displayed_energy_matches_energy_value() -> String:
	var energy = node.get("energy")
	if not energy is int:
		return tr("The energy variable is not an int anymore. Did you change the energy value?")

	if not str(energy) in node.energy_label.text:
		return tr(
			"The value of the energy variable does not match the displayed text. Did you call the str() function?"
		)
	return ""
