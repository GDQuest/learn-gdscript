extends PracticeTester

var first_node: Node2D
const EXPECTED_LIGHT_SEQUENCE := [1, 2, 0, 1, 2]


func _prepare() -> void:
	first_node = _scene_root_viewport.get_child(0)


func test_modulo_wraps_index_to_zero() -> String:
	var regex = RegEx.new()
	regex.compile("light_index\\s*\\%|\\%\\s*light_index|\\%\\s*\\d")
	var result = regex.search(_slice.current_text)
	if not result:
		return "It looks like modulo isn't used in the script. Did you use the modulo (%) symbol?"
	return ""


func test_correct_light_sequence() -> String:
	var light_sequence = first_node.get("lights_switched_on")
	
	if not light_sequence.hash() == EXPECTED_LIGHT_SEQUENCE.hash():
		return "The light sequence varies from standard traffic lights. Did you increment the light_index by 1?"
	return ""
