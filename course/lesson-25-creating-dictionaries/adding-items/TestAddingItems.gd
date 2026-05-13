extends PracticeTester

var inventory: Node

var desired_inventory := {
	"healing heart": 8,
	"gems": 4,
	"sword": 6,
}

func _prepare() -> void:
	inventory = _scene_root_viewport.get_child(0)


func test_add_item_function_works_as_intended():
	var source: Dictionary = inventory.get("inventory")
	var inventories_match := source.has_all(desired_inventory.keys())
	if inventories_match:
		for key in source.keys():
			if not desired_inventory[key] == source[key]:
				inventories_match = false
				break

	if not inventories_match:
		return tr(
			"The amount of items isn't correct. Does each key have the correct value?"
		)

	return ""


func test_add_item_function_uses_addition() -> String:
	var add_item_function := _analyzer.get_function_named("add_item")
	
	var captures := {}
	# func add_item(item_name, amount)
	if not GDExpr.function(
		&"add_item",
		GDExpr.suite(
			GDExpr.any_of(
				# inventory[item_name] += amount
				GDExpr.assignment(
					GDExpr.subscript(
						GDExpr.identifier("inventory"),
						GDExpr.captured_identifier("item_name", captures)
					),
					GDExpr.captured_identifier("amount", captures),
					GDAssignmentNode.OP_ADDITION
				),
				# inventory[item_name] = inventory[item_name] + amount
				GDExpr.assignment(
					GDExpr.subscript(
						GDExpr.identifier("inventory"),
						GDExpr.captured_identifier("item_name", captures)
					),
					GDExpr.bin_op(
						GDExpr.subscript(
							GDExpr.identifier("inventory"),
							GDExpr.captured_identifier("item_name", captures),
						),
						GDExpr.captured_identifier("amount", captures),
						GDBinaryOpNode.OP_ADDITION,
						false,
					),
				)
			)
		),
		GDExpr.parameter(
			GDExpr.any_identifier().capture("item_name", captures)
		),
		GDExpr.parameter(
			GDExpr.any_identifier().capture("amount", captures)
		)
	).matches(add_item_function):
		return tr("It doesn't look like you're adding '%s' to the value in the inventory dictionary." % [captures.amount])
	
	return ""
