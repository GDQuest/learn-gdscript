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
func get_lesson_path_from_slug(slug: String) -> String
@abstract
func get_lesson_slug(i: int) -> String
@abstract
func get_course_id() -> String
@abstract
func get_real_slug_from_slug(slug: String) -> String
