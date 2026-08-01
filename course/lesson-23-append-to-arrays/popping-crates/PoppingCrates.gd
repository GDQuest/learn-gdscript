extends Control

@onready var _initial_crates: Array[Node] = $Column.get_children()

var _crates := []
var current_index := 0
# If true the student code uses pop_back() to remove crates from the end of the
# array, otherwise it uses pop_front()
var _do_pop_from_back := true
var _is_resetting := false


func _ready() -> void:
	_initial_crates.reverse()
	var i := 0
	for crate in _initial_crates:
		crate.set_label_index(i)
		i += 1
		if not crate.used.is_connected(_pop_next):
			crate.used.connect(_pop_next)
		if not crate.restored.is_connected(_restore_next):
			crate.restored.connect(_restore_next)
	crates = _initial_crates.duplicate()
	if get_tree().current_scene == self:
		_run()


func _run() -> void:
	reset()
	run()
	_do_pop_from_back = _does_student_code_use_pop_back()
	current_index = _initial_crates.size() - 1 if _do_pop_from_back else 0
	_pop_next()


func _does_student_code_use_pop_back() -> bool:
	var checker := GDScriptErrorChecker.new()
	if checker.set_source(get_script().source_code) != OK:
		return true
	var analyzer := GDScriptASTAnalyzer.new(checker.get_root_parse_node())
	var run_function := analyzer.get_function_named("run")
	if not run_function:
		return true
	for statement in run_function.get_body().get_statements():
		if statement.get_type() != GDNode.WHILE:
			continue
		for loop_statement in (statement as GDWhileNode).get_loop().get_statements():
			if (
				loop_statement.get_type() == GDNode.CALL
				and (loop_statement as GDCallNode).get_function_name() == "pop_back"
			):
				return true
	return false


func _complete_run() -> void:
	Events.practice_run_completed.emit()


func _pop_next() -> void:
	var has_finished := (
		(_do_pop_from_back and current_index < crates.size())
		or (not _do_pop_from_back and current_index >= _initial_crates.size())
	)
	if has_finished:
		_complete_run()
	else:
		var crate = _initial_crates[current_index]
		var crate_name = crate.get_texture_name()
		print("popping crate %s '%s'" % [current_index, crate_name])
		crate.use()
		current_index += -1 if _do_pop_from_back else 1


func reset() -> void:
	crates = _initial_crates.duplicate()
	current_index = _initial_crates.size()
	for crate in _initial_crates:
		crate.reset(0)


func _restore_next() -> void:
	current_index -= 1
	if current_index < 0:
		current_index = 0
		return
	_initial_crates[current_index].reset(3)


# EXPORT run
var crates = [
	"healing heart",
	"shield",
	"gems",
	"sword",
]

func run():
	while crates:
		crates.pop_back()
# /EXPORT run
