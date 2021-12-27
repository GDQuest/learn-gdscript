extends Control

# EXPORT health
var health = 100
# /EXPORT health

func _run():
	test_assignment()

func test_assignment():
	for property in get_property_list():
		if property.name == "health":
			print("Health has a value of %s" % health)
			return
	print("Health property does not exist.")
