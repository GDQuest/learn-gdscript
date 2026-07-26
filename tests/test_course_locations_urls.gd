extends Node

const TEST_CASES := [
	{ "label": "L1", "url": "what-code-is-like", "tag": BBCodeParserData.Tag.LESSON },
	{
		"label": "l1.p1",
		"url": "what-code-is-like/try-your-first-code",
		"tag": BBCodeParserData.Tag.PRACTICE,
	},
	{
		"label": "L15P1",
		"url": "2d-vectors/increasing-scale-using-vectors",
		"tag": BBCodeParserData.Tag.PRACTICE,
	},
	{
		"label": "what-code-is-like/try-your-first-code",
		"url": "what-code-is-like/try-your-first-code",
		"tag": BBCodeParserData.Tag.PRACTICE,
	},
	{
		"label": "res://course/lesson-5-your-first-function/lesson.bbcode",
		"url": "your-first-function",
		"tag": BBCodeParserData.Tag.LESSON,
	},
]


func _ready() -> void:
	var failure_messages := PackedStringArray()

	for test_case: Dictionary in TEST_CASES:
		NavigationManager.history.clear()
		NavigationManager.navigate_to(test_case.label)

		if NavigationManager.current_url != test_case.url:
			failure_messages.append(
				"%s resolved to '%s', expected '%s'."
				% [test_case.label, NavigationManager.current_url, test_case.url],
			)

		var resource := NavigationManager.get_navigation_resource(test_case.label)
		if resource == null:
			failure_messages.append("%s did not resolve to a resource." % test_case.label)
		elif resource.tag != test_case.tag:
			failure_messages.append("%s resolved to the wrong resource type." % test_case.label)

	NavigationManager.history.clear()
	var invalid_resource := NavigationManager.get_navigation_resource("not-a-real-lesson")
	if invalid_resource != null:
		failure_messages.append("An unknown lesson slug resolved to a resource.")

	if failure_messages.is_empty():
		print("Passed all tests for course locations and URL slug resolution.")
		get_tree().quit(0)
		return

	for failure_message in failure_messages:
		printerr(failure_message)
	get_tree().quit(1)
