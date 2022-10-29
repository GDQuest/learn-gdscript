extends PracticeTester


var _robot: Node2D
var _body: String
var _has_proper_body: bool


func _prepare() -> void:
	_robot = _scene_root_viewport.get_child(0).get_node("Robot")
	_body = ""
	_has_proper_body = true

	for line in _slice.current_text.split("\n"):
		line = line.strip_edges()
		if line != "":
			_body = line
	
	if _body != "":
		_has_proper_body = _body.replace(" ", "") in ["rotate(delta*2)", "rotate(2*delta)"]


func test_rotating_character_is_time_dependent() -> String:
	if not _has_proper_body:
		var has_delta := _body.rfind("delta") > 0
		if not has_delta:
			return tr("Did you use delta to make the rotation time-dependent?")

		var regex_delta_in_parentheses = RegEx.new()
		regex_delta_in_parentheses.compile("rotate\\([^\\)]*delta.*\\)")

		var is_in_parentheses: bool = regex_delta_in_parentheses.search(_body) != null
		if not is_in_parentheses:
			return tr("Did you not multiply by delta inside the function call? You need to multiply inside the parentheses for delta to take effect.")
	return ""


func test_rotation_speed_is_2_radians_per_second() -> String:
	if not _has_proper_body:
		var regex_has_two = RegEx.new()
		regex_has_two.compile("rotate\\([^\\)0-9.]*2[^0-9.\\)]*\\)|rotate\\([^\\)0-9.]*2\\.[0]+[^0-9.\\)]*\\)")

		var has_two: bool = regex_has_two.search(_body) != null
		if not has_two:
			return tr("Is the rotation speed correct?")

		var has_multiplication_sign := _body.rfind("*") > 0
		if not has_multiplication_sign:
			return tr("We couldn't find a multiplication sign. Did you use it to make the rotation time-dependent?")
	return ""
