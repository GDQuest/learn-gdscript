@abstract
class_name CourseIndex
extends RefCounted


@abstract
func get_title() -> String
@abstract
func get_lessons_count() -> int
@abstract
func get_lesson_path(i: int) -> String
@abstract
## Returns the lesson path for its one-based position in the course.
func get_lesson_path_from_number(lesson_number: int) -> String
@abstract
func get_lesson_path_from_slug(slug: String) -> String
@abstract
func get_lesson_slug(i: int) -> String
@abstract
func get_lesson_slug_from_path(path: String) -> String
@abstract
func get_course_id() -> String
@abstract
func get_real_slug_from_slug(slug: String) -> String
@abstract
func get_lesson_number(lesson_path: String) -> int
