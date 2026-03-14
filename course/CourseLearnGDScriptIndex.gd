extends CourseIndex


const LESSONS := [
	"res://course/lesson-1-what-code-is-like/lesson.bbcode",
	"res://course/lesson-2-your-first-error/lesson.bbcode",
	"res://course/lesson-3-standing-on-shoulders-of-giants/lesson.bbcode",
	"res://course/lesson-4-drawing-a-rectangle/lesson.bbcode",
	"res://course/lesson-5-your-first-function/lesson.bbcode",
	"res://course/lesson-6-multiple-function-parameters/lesson.bbcode",
	"res://course/lesson-7-member-variables/lesson.bbcode",
	"res://course/lesson-8-defining-variables/lesson.bbcode",
	"res://course/lesson-9-adding-and-subtracting/lesson.bbcode",
	"res://course/lesson-10-the-game-loop/lesson.bbcode",
	"res://course/lesson-11-time-delta/lesson.bbcode",
	"res://course/lesson-12-using-variables/lesson.bbcode",
	"res://course/lesson-13-conditions/lesson.bbcode",
	"res://course/lesson-14-multiplying/lesson.bbcode",
	"res://course/lesson-16-2d-vectors/lesson.bbcode",
	"res://course/lesson-17-while-loops/lesson.bbcode",
	"res://course/lesson-18-for-loops/lesson.bbcode",
	"res://course/lesson-19-creating-arrays/lesson.bbcode",
	"res://course/lesson-20-looping-over-arrays/lesson.bbcode",
	"res://course/lesson-21-strings/lesson.bbcode",
	"res://course/lesson-22-functions-return-values/lesson.bbcode",
	"res://course/lesson-23-append-to-arrays/lesson.bbcode",
	"res://course/lesson-24-access-array-indices/lesson.bbcode",
	"res://course/lesson-25-creating-dictionaries/lesson.bbcode",
	"res://course/lesson-26-looping-over-dictionaries/lesson.bbcode",
	"res://course/lesson-27-value-types/lesson.bbcode",
	"res://course/lesson-28-specifying-types/lesson.bbcode",
]


func _get_lessons_count() -> int:
	return LESSONS.size()


func _get_title() -> String:
	return "Learn GDScript From Zero"


func _get_lesson_path(i: int) -> String:
	return LESSONS[i]


func _get_course_id() -> String:
	return "learn_gdscript"
