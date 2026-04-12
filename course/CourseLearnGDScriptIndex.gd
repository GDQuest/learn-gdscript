extends CourseIndex

# Key: Path to lesson BBCode
# Value: URL Slug
const LESSONS := {
	"res://course/lesson-1-what-code-is-like/lesson.bbcode": "what-code-is-like",
	"res://course/lesson-2-your-first-error/lesson.bbcode": "your-first-error",
	"res://course/lesson-3-standing-on-shoulders-of-giants/lesson.bbcode": "standing-on-shoulders-of-giants",
	"res://course/lesson-4-drawing-a-rectangle/lesson.bbcode": "drawing-a-rectangle",
	"res://course/lesson-5-your-first-function/lesson.bbcode": "your-first-function",
	"res://course/lesson-6-multiple-function-parameters/lesson.bbcode": "multiple-function-parameters",
	"res://course/lesson-7-member-variables/lesson.bbcode": "member-variables",
	"res://course/lesson-8-defining-variables/lesson.bbcode": "defining-variables",
	"res://course/lesson-9-adding-and-subtracting/lesson.bbcode": "adding-and-subtracting",
	"res://course/lesson-10-the-game-loop/lesson.bbcode": "the-game-loop",
	"res://course/lesson-11-time-delta/lesson.bbcode": "time-delta",
	"res://course/lesson-12-using-variables/lesson.bbcode": "using-variables",
	"res://course/lesson-13-conditions/lesson.bbcode": "conditions",
	"res://course/lesson-14-multiplying/lesson.bbcode": "multiplying",
	"res://course/lesson-16-2d-vectors/lesson.bbcode": "2d-vectors",
	"res://course/lesson-17-while-loops/lesson.bbcode": "while-loops",
	"res://course/lesson-18-for-loops/lesson.bbcode": "for-loops",
	"res://course/lesson-19-creating-arrays/lesson.bbcode": "creating-arrays",
	"res://course/lesson-20-looping-over-arrays/lesson.bbcode": "looping-over-arrays",
	"res://course/lesson-21-strings/lesson.bbcode": "strings",
	"res://course/lesson-22-functions-return-values/lesson.bbcode": "functions-return-values",
	"res://course/lesson-23-append-to-arrays/lesson.bbcode": "append-to-arrays",
	"res://course/lesson-24-access-array-indices/lesson.bbcode": "access-array-indices",
	"res://course/lesson-25-creating-dictionaries/lesson.bbcode": "creating-dictionaries",
	"res://course/lesson-26-looping-over-dictionaries/lesson.bbcode": "looping-over-dictionaries",
	"res://course/lesson-27-value-types/lesson.bbcode": "value-types",
	"res://course/lesson-28-specifying-types/lesson.bbcode": "specifying-types",
}

const _LESSON_SLUG_ALIASES := {
	# legacy lessons
	"lesson-1-what-code-is-like/lesson.tres": "what-code-is-like",
	"lesson-2-your-first-error/lesson.tres": "your-first-error",
	"lesson-3-standing-on-shoulders-of-giants/lesson.tres": "standing-on-shoulders-of-giants",
	"lesson-4-drawing-a-rectangle/lesson.tres": "drawing-a-rectangle",
	"lesson-5-your-first-function/lesson.tres": "your-first-function",
	"lesson-6-multiple-function-parameters/lesson.tres": "multiple-function-parameters",
	"lesson-7-member-variables/lesson.tres": "member-variables",
	"lesson-8-defining-variables/lesson.tres": "defining-variables",
	"lesson-9-adding-and-subtracting/lesson.tres": "adding-and-subtracting",
	"lesson-10-the-game-loop/lesson.tres": "the-game-loop",
	"lesson-11-time-delta/lesson.tres": "time-delta",
	"lesson-12-using-variables/lesson.tres": "using-variables",
	"lesson-13-conditions/lesson.tres": "conditions",
	"lesson-14-multiplying/lesson.tres": "multiplying",
	"lesson-16-2d-vectors/lesson.tres": "2d-vectors",
	"lesson-17-while-loops/lesson.tres": "while-loops",
	"lesson-18-for-loops/lesson.tres": "for-loops",
	"lesson-19-creating-arrays/lesson.tres": "creating-arrays",
	"lesson-20-looping-over-arrays/lesson.tres": "looping-over-arrays",
	"lesson-21-strings/lesson.tres": "strings",
	"lesson-22-functions-return-values/lesson.tres": "functions-return-values",
	"lesson-23-append-to-arrays/lesson.tres": "append-to-arrays",
	"lesson-24-access-array-indices/lesson.tres": "access-array-indices",
	"lesson-25-creating-dictionaries/lesson.tres": "creating-dictionaries",
	"lesson-26-looping-over-dictionaries/lesson.tres": "looping-over-dictionaries",
	"lesson-27-value-types/lesson.tres": "value-types",
	"lesson-28-specifying-types/lesson.tres": "specifying-types",
	
	# legacy practices
	"lesson-1-what-code-is-like/practice-55916.tres": "what-code-is-like/$try-your-first-code",
	"lesson-2-your-first-error/practice-85733.tres": "your-first-error/$fix-your-first-error",
	
	"lesson-3-standing-on-shoulders-of-giants/practice-QiGjB7tK.tres": "standing-on-shoulders-of-giants/$make-the-character-visible",
	"lesson-3-standing-on-shoulders-of-giants/practice-HJMQ2XNw.tres": "standing-on-shoulders-of-giants/$make-the-robot-upright",
	
	"lesson-4-drawing-a-rectangle/practice-Gx0c7DDi.tres": "drawing-a-rectangle/$drawing-a-corner",
	"lesson-4-drawing-a-rectangle/practice-5AJTESv5.tres": "drawing-a-rectangle/$drawing-a-rectangle",
	"lesson-4-drawing-a-rectangle/practice-kGx0c7DD.tres": "drawing-a-rectangle/$drawing-a-bigger-rectangle",
	
	"lesson-5-your-first-function/practice-QiGjB7tK.tres": "your-first-function/$a-function-to-draw-squares",
	"lesson-5-your-first-function/practice-kGx0c7DD.tres": "your-first-function/$drawing-multiple-squares",
	
	"lesson-6-multiple-function-parameters/practice-qAYVjotx.tres": "multiple-function-parameters/$drawing-corners-of-different-sizes",
	"lesson-6-multiple-function-parameters/practice-DwfyqdYO.tres": "multiple-function-parameters/$using-multiple-parameters",
	"lesson-6-multiple-function-parameters/practice-v5tT6n1T.tres": "multiple-function-parameters/$drawing-squares-of-any-size",
	"lesson-6-multiple-function-parameters/practice-lkGx0c7D.tres": "multiple-function-parameters/$drawing-rectangles-of-any-size",
	
	"lesson-7-member-variables/practice-Gx0c7DDi.tres": "member-variables/$draw-a-rectangle-at-a-precise-position",
	"lesson-7-member-variables/practice-x0c7DDiz.tres": "member-variables/$draw-squares-at-different-positions",
	
	"lesson-8-defining-variables/practice-lkGx0c7D.tres": "defining-variables/$define-a-health-variable",
	
	"lesson-9-adding-and-subtracting/practice-nk1K416Q.tres": "adding-and-subtracting/$damaging-the-robot",
	"lesson-9-adding-and-subtracting/practice-kGx0c7DD.tres": "adding-and-subtracting/$healing-the-robot",
	
	"lesson-10-the-game-loop/practice-tKRHJMQ2.tres": "the-game-loop/$rotating-a-character-continuously",
	"lesson-10-the-game-loop/practice-QiGjB7tK.tres": "the-game-loop/$creating-circular-movement",
	
	"lesson-11-time-delta/practice-UdOCQiGj.tres": "time-delta/$rotating-using-delta",
	"lesson-11-time-delta/practice-x0c7DDiz.tres": "time-delta/$moving-in-a-circle-using-delta",
	
	"lesson-12-using-variables/practice-lkGx0c7D.tres": "using-variables/$clarifying-code-using-variables",
	"lesson-12-using-variables/practice-KUdOCQiG.tres": "using-variables/$fixing-an-out-of-scope-error",
	
	"lesson-13-conditions/practice-KRHJMQ2X.tres": "conditions/$using-comparisons",
	"lesson-13-conditions/practice-MqAYVjot.tres": "conditions/$limiting-healing",
	"lesson-13-conditions/practice-xZPxY8VU.tres": "conditions/$preventing-health-from-going-below-zero",
	
	"lesson-14-multiplying/practice-0c7DDizK.tres": "multiplying/$increasing-maximum-health-exponentially",
	"lesson-14-multiplying/practice-CQiGjB7t.tres": "multiplying/$reducing-damage-at-higher-levels",
	
	"lesson-16-2d-vectors/practice-RHJMQ2XN.tres": "2d-vectors/$increasing-scale-using-vectors",
	"lesson-16-2d-vectors/practice-kGx0c7DD.tres": "2d-vectors/$resetting-size-and-position-using-vectors",
	
	"lesson-17-while-loops/practice-lkGx0c7D.tres": "while-loops/$moving-to-the-end-of-a-board",
	
	"lesson-18-for-loops/practice-7tKRHJMQ.tres": "for-loops/$using-a-for-loop-to-move-to-the-end-of-the-board",
	"lesson-18-for-loops/practice-UDpPwQDw.tres": "for-loops/$improving-code-with-a-for-loop",
	
	"lesson-19-creating-arrays/practice-otxF5HUx.tres": "creating-arrays/$walking-to-the-robot",
	"lesson-19-creating-arrays/practice-PxY8VUDp.tres": "creating-arrays/$selecting-units",
	
	"lesson-20-looping-over-arrays/practice-f8B67UJ8.tres": "looping-over-arrays/$move-the-robot-along-the-path",
	"lesson-20-looping-over-arrays/practice-clsFcSrG.tres": "looping-over-arrays/$back-to-the-drawing-board",
	
	"lesson-21-strings/practice-iGjB7tKR.tres": "strings/$creating-string-variables",
	"lesson-21-strings/practice-NwQMqAYV.tres": "strings/$using-an-array-of-strings-to-play-a-combo",
	
	"lesson-22-functions-return-values/practice-llf8B67U.tres": "functions-return-values/$converting-coordinates-from-the-grid-to-the-screen",
	
	"lesson-23-append-to-arrays/practice-KUdOCQiG.tres": "append-to-arrays/$completing-orders",
	"lesson-23-append-to-arrays/practice-B7tKRHJM.tres": "append-to-arrays/$clearing-up-the-crates",
	
	"lesson-24-access-array-indices/practice-ErO9L4MW.tres": "access-array-indices/$using-the-right-items",
	"lesson-24-access-array-indices/practice-wfi7YGry.tres": "access-array-indices/$realigning-the-train-tracks",
	
	"lesson-25-creating-dictionaries/practice-tZixQOPR.tres": "creating-dictionaries/$creating-an-inventory-using-a-dictionary",
	"lesson-25-creating-dictionaries/practice-9clsFcSr.tres": "creating-dictionaries/$increasing-item-counts",
	
	"lesson-26-looping-over-dictionaries/practice-nVHARbBW.tres": "looping-over-dictionaries/$displaying-the-inventory",
	"lesson-26-looping-over-dictionaries/practice-bDGt6fUq.tres": "looping-over-dictionaries/$placing-units-on-the-board",
	
	"lesson-27-value-types/practice-lkGx0c7D.tres": "value-types/$displaying-the-player-health-and-energy",
	"lesson-27-value-types/practice-izKUdOCQ.tres": "value-types/$letting-the-player-type-numbers",
	
	"lesson-28-specifying-types/practice-x0c7DDiz.tres": "specifying-types/$add-the-correct-type-hints-to-variables",
	"lesson-28-specifying-types/practice-UdOCQiGj.tres": "specifying-types/$fix-the-values-to-match-the-type-hints",
}

var _inverted_lessons := {}
# This stores the lesson numbers starting from lesson one and allows finding the
# number of a lesson from its file path. This is used for displaying labels like
# L1 for lesson 1 in the course outline, and also labels like L1.P2 for
# practices.
var _lesson_number_by_path := {}

var practice_slugs := {}


func _init() -> void:
	var lesson_index := 1
	for path in LESSONS.keys():
		_inverted_lessons[LESSONS[path]] = path
		_lesson_number_by_path[path] = lesson_index
		lesson_index += 1


func get_lessons_count() -> int:
	return LESSONS.size()


func get_title() -> String:
	return "Learn GDScript From Zero"


func get_lesson_path(i: int) -> String:
	return LESSONS.keys()[i]


func get_real_slug_from_slug(slug: String) -> String:
	return _LESSON_SLUG_ALIASES.get(slug, slug)


func get_lesson_path_from_slug(slug: String) -> String:
	return _inverted_lessons[slug]


func get_lesson_slug(i: int) -> String:
	var path := get_lesson_path(i)
	return LESSONS[path]


func get_lesson_slug_from_path(path: String) -> String:
	return LESSONS[path]


func get_lesson_number(lesson_path: String) -> int:
	return _lesson_number_by_path.get(lesson_path, 0)


func get_course_id() -> String:
	return "learn-gdscript"


func get_practice_from_slug(slug: String) -> BBCodeParser.ParseNode:
	return practice_slugs.get(slug, null)


func set_practice_slug(lesson_slug: String, practice_slug: String, practice: BBCodeParser.ParseNode) -> void:
	practice_slugs["%s/$%s" % [lesson_slug, practice_slug]] = practice
