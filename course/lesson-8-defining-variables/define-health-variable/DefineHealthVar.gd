extends Control

# EXPORT health
var health = 100
# /EXPORT health

func _run():
	test_assignment()

func test_assignment():
	for property in get_property_list():
		if property.name == "health":
			$Label.bbcode_text = "Variable [code]health[/code] has a value of %s" % get("health")
			return
	$Label.bbcode_text = "Variable [code]health[/code] is not defined."
