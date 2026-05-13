class_name GDIdentifierExpr
extends GDExpr


var _name: String
var _regex: RegEx = null
var _do_capture := false
var _capture_name: StringName
var _captures: Dictionary

func _init(name: String, use_regex: bool) -> void:
	_name = name
	if use_regex:
		_regex = RegEx.create_from_string(name)


func matches(node: GDNode) -> bool:
	if node.get_type() != GDNode.IDENTIFIER:
		return false
	
	var ident_node := node as GDIdentifierNode
	var does_match := false
	if _regex:
		does_match = _regex.search(ident_node.name) != null
	else:
		does_match = ident_node.name == _name
	if _do_capture:
		_captures[_capture_name] = ident_node.name
	return does_match


## Captures the identifier. This will prime the `captures` dictionary with the capture `name`.
## When the node is matched in `matches()`, its identifier name will be stored.
## GDCaptureExpr can then match against it by its capture name instead of its real identifier name.
## [codeblock]
## var captures := {}
## # for item_name in inventory:
## if GDExpr.for_loop(
## 	GDExpr.any_identifier().capture("item_name", captures),
## 	GDExpr.identifier("inventory"),
## 	GDExpr.suite(
## 		# print(item_name)
## 		GDExpr.function_call(
## 			"print",
## 			GDExpr.captured_identifier("item_name", captures)
## 		)
## 	)
## ).matches(for_statement):
## [/codeblock]
func capture(name: StringName, captures: Dictionary) -> GDIdentifierExpr:
	_capture_name = name
	_captures = captures
	_captures[_capture_name] = &""
	_do_capture = true
	return self
