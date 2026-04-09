extends CourseIndex

# Key: Path to lesson BBCode
# Value: URL Slug
const LESSONS := {
	"res://course/lesson-1-what-code-is-like/lesson.bbcode": "lesson-1-what-code-is-like/lesson.bbcode",
	"res://course/lesson-2-your-first-error/lesson.bbcode": "lesson-2-your-first-error/lesson.bbcode",
	"res://course/lesson-3-standing-on-shoulders-of-giants/lesson.bbcode": "lesson-3-standing-on-shoulders-of-giants/lesson.bbcode",
	"res://course/lesson-4-drawing-a-rectangle/lesson.bbcode": "lesson-4-drawing-a-rectangle/lesson.bbcode",
	"res://course/lesson-5-your-first-function/lesson.bbcode": "lesson-5-your-first-function/lesson.bbcode",
	"res://course/lesson-6-multiple-function-parameters/lesson.bbcode": "lesson-6-multiple-function-parameters/lesson.bbcode",
	"res://course/lesson-7-member-variables/lesson.bbcode": "lesson-7-member-variables/lesson.bbcode",
	"res://course/lesson-8-defining-variables/lesson.bbcode": "lesson-8-defining-variables/lesson.bbcode",
	"res://course/lesson-9-adding-and-subtracting/lesson.bbcode": "lesson-9-adding-and-subtracting/lesson.bbcode",
	"res://course/lesson-10-the-game-loop/lesson.bbcode": "lesson-10-the-game-loop/lesson.bbcode",
	"res://course/lesson-11-time-delta/lesson.bbcode": "lesson-11-time-delta/lesson.bbcode",
	"res://course/lesson-12-using-variables/lesson.bbcode": "lesson-12-using-variables/lesson.bbcode",
	"res://course/lesson-13-conditions/lesson.bbcode": "lesson-13-conditions/lesson.bbcode",
	"res://course/lesson-14-multiplying/lesson.bbcode": "lesson-14-multiplying/lesson.bbcode",
	"res://course/lesson-16-2d-vectors/lesson.bbcode": "lesson-16-2d-vectors/lesson.bbcode",
	"res://course/lesson-17-while-loops/lesson.bbcode": "lesson-17-while-loops/lesson.bbcode",
	"res://course/lesson-18-for-loops/lesson.bbcode": "lesson-18-for-loops/lesson.bbcode",
	"res://course/lesson-19-creating-arrays/lesson.bbcode": "lesson-19-creating-arrays/lesson.bbcode",
	"res://course/lesson-20-looping-over-arrays/lesson.bbcode": "lesson-20-looping-over-arrays/lesson.bbcode",
	"res://course/lesson-21-strings/lesson.bbcode": "lesson-21-strings/lesson.bbcode",
	"res://course/lesson-22-functions-return-values/lesson.bbcode": "lesson-22-functions-return-values/lesson.bbcode",
	"res://course/lesson-23-append-to-arrays/lesson.bbcode": "lesson-23-append-to-arrays/lesson.bbcode",
	"res://course/lesson-24-access-array-indices/lesson.bbcode": "lesson-24-access-array-indices/lesson.bbcode",
	"res://course/lesson-25-creating-dictionaries/lesson.bbcode": "lesson-25-creating-dictionaries/lesson.bbcode",
	"res://course/lesson-26-looping-over-dictionaries/lesson.bbcode": "lesson-26-looping-over-dictionaries/lesson.bbcode",
	"res://course/lesson-27-value-types/lesson.bbcode": "lesson-27-value-types/lesson.bbcode",
	"res://course/lesson-28-specifying-types/lesson.bbcode": "lesson-28-specifying-types/lesson.bbcode",
}

const _LESSON_SLUG_ALIASES := {
	# legacy lessons
	"lesson-1-what-code-is-like/lesson.tres": "lesson-1-what-code-is-like/lesson.bbcode",
	"lesson-2-your-first-error/lesson.tres": "lesson-2-your-first-error/lesson.bbcode",
	"lesson-3-standing-on-shoulders-of-giants/lesson.tres": "lesson-3-standing-on-shoulders-of-giants/lesson.bbcode",
	"lesson-4-drawing-a-rectangle/lesson.tres": "lesson-4-drawing-a-rectangle/lesson.bbcode",
	"lesson-5-your-first-function/lesson.tres": "lesson-5-your-first-function/lesson.bbcode",
	"lesson-6-multiple-function-parameters/lesson.tres": "lesson-6-multiple-function-parameters/lesson.bbcode",
	"lesson-7-member-variables/lesson.tres": "lesson-7-member-variables/lesson.bbcode",
	"lesson-8-defining-variables/lesson.tres": "lesson-8-defining-variables/lesson.bbcode",
	"lesson-9-adding-and-subtracting/lesson.tres": "lesson-9-adding-and-subtracting/lesson.bbcode",
	"lesson-10-the-game-loop/lesson.tres": "lesson-10-the-game-loop/lesson.bbcode",
	"lesson-11-time-delta/lesson.tres": "lesson-11-time-delta/lesson.bbcode",
	"lesson-12-using-variables/lesson.tres": "lesson-12-using-variables/lesson.bbcode",
	"lesson-13-conditions/lesson.tres": "lesson-13-conditions/lesson.bbcode",
	"lesson-14-multiplying/lesson.tres": "lesson-14-multiplying/lesson.bbcode",
	"lesson-16-2d-vectors/lesson.tres": "lesson-16-2d-vectors/lesson.bbcode",
	"lesson-17-while-loops/lesson.tres": "lesson-17-while-loops/lesson.bbcode",
	"lesson-18-for-loops/lesson.tres": "lesson-18-for-loops/lesson.bbcode",
	"lesson-19-creating-arrays/lesson.tres": "lesson-19-creating-arrays/lesson.bbcode",
	"lesson-20-looping-over-arrays/lesson.tres": "lesson-20-looping-over-arrays/lesson.bbcode",
	"lesson-21-strings/lesson.tres": "lesson-21-strings/lesson.bbcode",
	"lesson-22-functions-return-values/lesson.tres": "lesson-22-functions-return-values/lesson.bbcode",
	"lesson-23-append-to-arrays/lesson.tres": "lesson-23-append-to-arrays/lesson.bbcode",
	"lesson-24-access-array-indices/lesson.tres": "lesson-24-access-array-indices/lesson.bbcode",
	"lesson-25-creating-dictionaries/lesson.tres": "lesson-25-creating-dictionaries/lesson.bbcode",
	"lesson-26-looping-over-dictionaries/lesson.tres": "lesson-26-looping-over-dictionaries/lesson.bbcode",
	"lesson-27-value-types/lesson.tres": "lesson-27-value-types/lesson.bbcode",
	"lesson-28-specifying-types/lesson.tres": "lesson-28-specifying-types/lesson.bbcode",
	
	# legacy practices
	"lesson-1-what-code-is-like/practice-55916.tres": "lesson-1-what-code-is-like/lesson.bbcode#P0",
	
	"lesson-2-your-first-error/practice-85733.tres": "lesson-2-your-first-error/lesson.bbcode#P0",
	
	"lesson-3-standing-on-shoulders-of-giants/practice-QiGjB7tK.tres": "lesson-3-standing-on-shoulders-of-giants/lesson.bbcode#P0",
	"lesson-3-standing-on-shoulders-of-giants/practice-HJMQ2XNw.tres": "lesson-3-standing-on-shoulders-of-giants/lesson.bbcode#P1",
	
	"lesson-4-drawing-a-rectangle/practice-Gx0c7DDi.tres": "lesson-4-drawing-a-rectangle/lesson.bbcode#P0",
	"lesson-4-drawing-a-rectangle/practice-5AJTESv5.tres": "lesson-4-drawing-a-rectangle/lesson.bbcode#P1",
	"lesson-4-drawing-a-rectangle/practice-kGx0c7DD.tres": "lesson-4-drawing-a-rectangle/lesson.bbcode#P2",
	
	"lesson-5-your-first-function/practice-QiGjB7tK.tres": "lesson-5-your-first-function/lesson.bbcode#P0",
	"lesson-5-your-first-function/practice-kGx0c7DD.tres": "lesson-5-your-first-function/lesson.bbcode#P1",
	
	"lesson-6-multiple-function-parameters/practice-qAYVjotx.tres": "lesson-6-multiple-function-parameters/lesson.bbcode#P0",
	"lesson-6-multiple-function-parameters/practice-DwfyqdYO.tres": "lesson-6-multiple-function-parameters/lesson.bbcode#P1",
	"lesson-6-multiple-function-parameters/practice-v5tT6n1T.tres": "lesson-6-multiple-function-parameters/lesson.bbcode#P2",
	"lesson-6-multiple-function-parameters/practice-lkGx0c7D.tres": "lesson-6-multiple-function-parameters/lesson.bbcode#P3",
	
	"lesson-7-member-variables/practice-Gx0c7DDi.tres": "lesson-7-member-variables/lesson.bbcode#P0",
	"lesson-7-member-variables/practice-x0c7DDiz.tres": "lesson-7-member-variables/lesson.bbcode#P1",
	
	"lesson-8-defining-variables/practice-lkGx0c7D.tres": "lesson-8-defining-variables/lesson.bbcode#P0",
	
	"lesson-9-adding-and-subtracting/practice-nk1K416Q.tres": "lesson-9-adding-and-subtracting/lesson.bbcode#P0",
	
	"lesson-9-adding-and-subtracting/practice-kGx0c7DD.tres": "lesson-9-adding-and-subtracting/lesson.bbcode#P1",
	
	"lesson-10-the-game-loop/practice-tKRHJMQ2.tres": "lesson-10-the-game-loop/lesson.bbcode#P0",
	"lesson-10-the-game-loop/practice-QiGjB7tK.tres": "lesson-10-the-game-loop/lesson.bbcode#P1",
	
	"lesson-11-time-delta/practice-UdOCQiGj.tres": "lesson-11-time-delta/lesson.bbcode#P0",
	"lesson-11-time-delta/practice-x0c7DDiz.tres": "lesson-11-time-delta/lesson.bbcode#P1",
	
	"lesson-12-using-variables/practice-lkGx0c7D.tres": "lesson-12-using-variables/lesson.bbcode#P0",
	"lesson-12-using-variables/practice-KUdOCQiG.tres": "lesson-12-using-variables/lesson.bbcode#P1",
	
	"lesson-13-conditions/practice-KRHJMQ2X.tres": "lesson-13-conditions/lesson.bbcode#P0",
	"lesson-13-conditions/practice-MqAYVjot.tres": "lesson-13-conditions/lesson.bbcode#P1",
	"lesson-13-conditions/practice-xZPxY8VU.tres": "lesson-13-conditions/lesson.bbcode#P2",
	
	"lesson-14-multiplying/practice-0c7DDizK.tres": "lesson-14-multiplying/lesson.bbcode#P0",
	"lesson-14-multiplying/practice-CQiGjB7t.tres": "lesson-14-multiplying/lesson.bbcode#P1",
	
	"lesson-16-2d-vectors/practice-RHJMQ2XN.tres": "lesson-16-2d-vectors/lesson.bbcode#P0",
	"lesson-16-2d-vectors/practice-kGx0c7DD.tres": "lesson-16-2d-vectors/lesson.bbcode#P1",
	
	"lesson-17-while-loops/practice-lkGx0c7D.tres": "lesson-17-while-loops/lesson.bbcode#P0",
	
	"lesson-18-for-loops/practice-7tKRHJMQ.tres": "lesson-18-for-loops/lesson.bbcode#P0",
	"lesson-18-for-loops/practice-UDpPwQDw.tres": "lesson-18-for-loops/lesson.bbcode#P1",
	
	"lesson-19-creating-arrays/practice-otxF5HUx.tres": "lesson-19-creating-arrays/lesson.bbcode#P0",
	"lesson-19-creating-arrays/practice-PxY8VUDp.tres": "lesson-19-creating-arrays/lesson.bbcode#P1",
	
	"lesson-20-looping-over-arrays/practice-f8B67UJ8.tres": "lesson-20-looping-over-arrays/lesson.bbcode#P0",
	"lesson-20-looping-over-arrays/practice-clsFcSrG.tres": "lesson-20-looping-over-arrays/lesson.bbcode#P1",
	
	"lesson-21-strings/practice-iGjB7tKR.tres": "lesson-21-strings/lesson.bbcode#P0",
	"lesson-21-strings/practice-NwQMqAYV.tres": "lesson-21-strings/lesson.bbcode#P1",
	
	"lesson-22-functions-return-values/practice-llf8B67U.tres": "lesson-22-functions-return-values/lesson.bbcode#P0",
	
	"lesson-23-append-to-arrays/practice-KUdOCQiG.tres": "lesson-23-append-to-arrays/lesson.bbcode#P0",
	"lesson-23-append-to-arrays/practice-B7tKRHJM.tres": "lesson-23-append-to-arrays/lesson.bbcode#P1",
	
	"lesson-24-access-array-indices/practice-ErO9L4MW.tres": "lesson-24-access-array-indices/lesson.bbcode#P0",
	"lesson-24-access-array-indices/practice-wfi7YGry.tres": "lesson-24-access-array-indices/lesson.bbcode#P1",
	
	"lesson-25-creating-dictionaries/practice-tZixQOPR.tres": "lesson-25-creating-dictionaries/lesson.bbcode#P0",
	"lesson-25-creating-dictionaries/practice-9clsFcSr.tres": "lesson-25-creating-dictionaries/lesson.bbcode#P1",
	
	"lesson-26-looping-over-dictionaries/practice-nVHARbBW.tres": "lesson-26-looping-over-dictionaries/lesson.bbcode#P0",
	"lesson-26-looping-over-dictionaries/practice-bDGt6fUq.tres": "lesson-26-looping-over-dictionaries/lesson.bbcode#P1",
	
	"lesson-27-value-types/practice-lkGx0c7D.tres": "lesson-27-value-types/lesson.bbcode#P0",
	"lesson-27-value-types/practice-izKUdOCQ.tres": "lesson-27-value-types/lesson.bbcode#P1",
	
	"lesson-28-specifying-types/practice-x0c7DDiz.tres": "lesson-28-specifying-types/lesson.bbcode#P0",
	"lesson-28-specifying-types/practice-UdOCQiGj.tres": "lesson-28-specifying-types/lesson.bbcode#P1",
}

var _inverted_lessons := {}


func _init() -> void:
	for path in LESSONS.keys():
		_inverted_lessons[LESSONS[path]] = path


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


func get_course_id() -> String:
	return "learn_gdscript"
