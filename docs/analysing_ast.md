# Analyzing student code with the GDScript AST

The app uses a custom version of the Godot engine that exposes the GDScriptParser's parse tree.

## Access

1. Create a `GDScriptErrorChecker`
2. Call `set_source()` and provide the source code. The code should be a valid, parsable class.
3. Provided there are no parser, analyzer, or compiler errors, you can then call `get_root_parse_node()`, which returns a `GDClassNode`.

`set_source()` will return `OK` if there are no parser, analyzer, or compiler errors.

If you mean to analyze the parser nodes outside of the scope where you set the checker up, make sure to keep a reference to it. Once the `GDScriptErrorChecker` has its RefCount go to 0, it will clear the parser and all the nodes, and you will get garbage data out of the GDNodes at best.

### Low level access

The most raw way of analyzing student code is to directly access the functions in the root `GDClassNode`, like `get_member(function_name)` to get a `GDFunctionNode`.

See the in-editor documentation for the individual `GDNode` RefCounted objects for the API.

### High level access

The `GDScriptASTAnalyzer` class is available to make accessing data easier without worrying about the API as much.

```gdscript
var checker = GDScriptErrorChecker.new()
checker.set_source(class_code)
var root := _checker.get_root_parse_node()
var analyzer = GDScriptASTAnalyzer.new(root)
```

From there, you can access friendly functions like `analyzer.get_function_named(function_name)` and `analyzer.get_function_parameter_name(function, parameter_index)`.

#### Expression system

If you want to check that the tree has a particular shape and uses particular patterns, you can use the `GDExpr` class' static functions to build a comparator tree.

For example, the expected code is

```gdscript
func run():
	var health = 100

	if health > 5:
		print("health is greater than five.")
```

To verify it, I can thus write an expression against it:

```gdscript
func test_statement_is_true() -> String:
	var run_function := _analyzer.get_function_named("run")
	
	# suites are the bodies of functions, loops, match branches, etc
	if not GDExpr.suite(
        # if
		GDExpr.if_block(
            # health > 5
			GDExpr.bin_op(
				GDExpr.identifier("health"),
				GDExpr.literal(5),
				GDBinaryOpNode.OP_COMP_GREATER
			)
		)
	).matches(run_function):
		return tr("The comparison is not correct. Did you use the right comparison?")
	return ""
```
