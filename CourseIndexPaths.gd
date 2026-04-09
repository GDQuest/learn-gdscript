class_name CourseIndexPaths
extends RefCounted


const COURSES := {
	"learn_gdscript": "res://course/CourseLearnGDScriptIndex.gd"
}

const COURSE_SLUG_ALIASES := {
	"course": "learn_gdscript"
}

static var _course_index_cache := {}


static func get_course_index_instance(course_id: String) -> CourseIndex:
	var effective_id := course_id
	if not COURSES.has(course_id) and COURSE_SLUG_ALIASES.has(course_id):
		effective_id = COURSE_SLUG_ALIASES[course_id]
	
	var index: CourseIndex = _course_index_cache.get(effective_id, null)
	if index:
		return index
	
	var index_path: String = COURSES.get(effective_id, "")
	if not index_path:
		push_error("Invalid course %s and no alias found" % [course_id])
		return null
	
	var index_script: GDScript = load(index_path)
	if not index_script:
		push_error("Course %s at %s failed to load" % [course_id, index_path])
		return null
	
	index = index_script.new()
	_course_index_cache[course_id] = index
	return index
