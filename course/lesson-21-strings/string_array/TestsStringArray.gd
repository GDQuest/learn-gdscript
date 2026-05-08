extends PracticeTester

var desired_combo = ["jab", "jab", "uppercut"]
var robot: Node2D
var _checker: GDScriptErrorChecker
var _analyzer: GDScriptASTAnalyzer


func _prepare() -> void:
	robot = _scene_root_viewport.get_child(0)

	_checker = GDScriptErrorChecker.new()
	_checker.set_source(_slice.current_text)
	var root := _checker.get_root_parse_node()
	_analyzer = GDScriptASTAnalyzer.new(root)


func test_use_for_loop() -> String:
	var run_function := _analyzer.get_function_named("run")
	
	if not run_function:
		return tr("The run function is missing; did you remove it?")
	
	if not GDExpr.suite(GDExpr.for_loop(null, null, null)).matches(run_function):
		return tr("Your code has no for loop. You need to use a for loop to complete this practice, even if there are other solutions!")
	
	if not GDExpr.suite(
		GDExpr.for_loop(
			null,
			null,
			GDExpr.suite(
				GDExpr.function_call("play_animation")
			)
		)
	).matches(run_function):
		return tr("Your code does not play any animations. Did you remember to call play_animation() in your for loop?")
	
	if GDExpr.suite(
		GDExpr.for_loop(
			null,
			null,
			GDExpr.suite(
				GDExpr.function_call(
					"play_animation",
					GDExpr.identifier("combo")
				)
			)
		)
	).matches(run_function):
		return tr("It seems you're passing the entire array of combos instead of a single animation name at a time.")

	var captures := {}
	if not GDExpr.suite(
		GDExpr.for_loop(
			GDExpr.any_identifier().capture("animation_name", captures),
			null,
			GDExpr.suite(
				GDExpr.function_call(
					"play_animation",
					GDExpr.captured_identifier("animation_name", captures)
				)
			)
		)
	).matches(run_function):
		return tr("Your code does not use the iterator. Did you remember to call play_animation(%s) in your for loop?") % captures.animation_name
	
	return ""


func test_robot_combo_is_correct() -> String:
	var robot_combo = robot.get("combo")
	if robot_combo == desired_combo:
		return ""

	var run_function := _analyzer.get_function_named("run")
	var combo_var := _analyzer.get_local_var_named(run_function, "combo")
	var initializer := combo_var.get_initializer()

	if GDExpr.array(
		desired_combo.map(
			func(animation_name: String) -> GDExpr: return GDExpr.literal(animation_name)
		)
	).matches(initializer):
		return ""
	
	return tr("The combo isn't correct. Did you use the right actions in the right order?")
