extends PracticeTester

var robot: Node2D

func _prepare() -> void:
    robot = _scene_root_viewport.get_child(0).get_child(1)

func test_use_vector2_to_reset_robot() -> String:
    var text := _slice.current_text
    var decl_re := RegEx.new()
    var compile_result := decl_re.compile("(?m)\\b(?:var|const|onready)\\s+([A-Za-z_]\\w*)\\s*(?::\\s*Vector2\\s*)?(?:=|:=)\\s*Vector2\\s*\\(")
    var vec_vars := []
    var pos := 0
    while true:
        var m := decl_re.search(text, pos)
        if not m:
            break
        vec_vars.append(m.get_string(1))
        pos = m.get_end()

    var var_alts := ""
    if vec_vars.size() > 0:
        var buf := "("
        for i in range(vec_vars.size()):
            if i > 0:
                buf += "|"
            buf += str(vec_vars[i])
        buf += ")"
        var_alts = buf

    var position_ok := false
    var scale_ok := false

    var pos_direct_re := RegEx.new()
    compile_result = pos_direct_re.compile("\\b(?:self\\.)?position\\s*=\\s*(?:Vector2\\s*\\(|Vector2\\.ZERO\\b)")
    if pos_direct_re.search(text):
        position_ok = true
    elif var_alts != "":
        var pos_var_re := RegEx.new()
        compile_result = pos_var_re.compile("\\b(?:self\\.)?position\\s*=\\s*" + var_alts + "\\b")
        if pos_var_re.search(text):
            position_ok = true

    var scale_direct_re := RegEx.new()
    compile_result = scale_direct_re.compile("\\b(?:self\\.)?scale\\s*=\\s*(?:Vector2\\s*\\(|Vector2\\.(?:ZERO|ONE)\\b)")
    if scale_direct_re.search(text):
        scale_ok = true
    elif var_alts != "":
        var scale_var_re := RegEx.new()
        compile_result = scale_var_re.compile("\\b(?:self\\.)?scale\\s*=\\s*" + var_alts + "\\b")
        if scale_var_re.search(text):
            scale_ok = true

    if position_ok and scale_ok:
        return ""
    return tr("It looks like scale or position isn't reset using a Vector2 (directly or via a Vector2 variable).")

func test_robot_scale_is_reset() -> String:
    var scale = robot.get("scale") as Vector2
    if scale.is_equal_approx(Vector2(1.0, 1.0)):
        return ""
    return tr("scale's value is %s; It should be (1.0, 1.0) after resetting.") % [scale]

func test_robot_position_is_reset() -> String:
    var position = robot.get("position") as Vector2
    if position.is_equal_approx(Vector2.ZERO):
        return ""
    return tr("position's value is %s; It should be (0.0, 0.0) after resetting.") % [position]
