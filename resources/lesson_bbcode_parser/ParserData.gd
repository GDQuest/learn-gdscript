# This script defines all of the supported tags in our lessons and some data
# structures to help validate them. It's used by the BBCode parser.
class_name BBCodeParserData
extends Reference

# Basic Godot BBCode formatting tags that should be ignored by the parser
# These are handled by Godot's RichTextLabel and don't need validation
const IGNORED_FORMATTING_TAGS := ["i", "b", "url", "img", "code", "right", "ignore"]

enum Tag {
	UNKNOWN,
	LESSON,
	TITLE,
	CODEBLOCK,
	VISUAL,
	NOTE,
	QUIZ_CHOICE,
	QUIZ_INPUT,
	OPTION,
	HINT,
	EXPLANATION,
	PRACTICE,
	DESCRIPTION,
	GOAL,
	STARTING_CODE,
	CURSOR,
	VALIDATOR,
	SCRIPT_SLICE,
	DOCS,
	SEPARATOR,
}


var TAG_DEFINITIONS := {
	Tag.LESSON:
		TagDefinition.new("lesson", true, false, [], ["title"], [], []),
	Tag.TITLE:
		TagDefinition.new("title", true, false, [Tag.LESSON], [], [], []),
	Tag.CODEBLOCK:
		TagDefinition.new("codeblock", true, false, [Tag.LESSON], [], ["runnable"], []),
	Tag.VISUAL:
		TagDefinition.new("visual", false, true, [Tag.LESSON], ["path"], [], []),
	Tag.NOTE:
		TagDefinition.new("note", true, false, [Tag.LESSON], [], ["title"], []),
	Tag.QUIZ_CHOICE:
		TagDefinition.new("quiz_choice", true, false, [Tag.LESSON], ["question"], ["multiple", "shuffle"], [Tag.OPTION, Tag.EXPLANATION]),
	Tag.QUIZ_INPUT:
		TagDefinition.new("quiz_input", true, false, [Tag.LESSON], ["question", "answer"], [], [Tag.EXPLANATION]),
	Tag.OPTION:
		TagDefinition.new("option", true, false, [Tag.QUIZ_CHOICE], [], ["correct"], []),
	Tag.HINT:
		TagDefinition.new("hint", true, false, [Tag.QUIZ_CHOICE, Tag.QUIZ_INPUT, Tag.PRACTICE], [], [], []),
	Tag.EXPLANATION:
		TagDefinition.new("explanation", true, false, [Tag.QUIZ_CHOICE, Tag.QUIZ_INPUT], [], [], []),
	Tag.PRACTICE:
		TagDefinition.new("practice", true, false, [Tag.LESSON], ["id", "title"], [], [Tag.DESCRIPTION, Tag.GOAL, Tag.STARTING_CODE, Tag.VALIDATOR, Tag.SCRIPT_SLICE]),
	Tag.DESCRIPTION:
		TagDefinition.new("description", true, false, [Tag.PRACTICE], [], [], []),
	Tag.GOAL:
		TagDefinition.new("goal", true, false, [Tag.PRACTICE], [], [], []),
	Tag.STARTING_CODE:
		TagDefinition.new("starting_code", true, false, [Tag.PRACTICE], [], [], []),
	Tag.CURSOR:
		TagDefinition.new("cursor", false, true, [Tag.PRACTICE], [], ["line", "column"], []),
	Tag.VALIDATOR:
		TagDefinition.new("validator", false, true, [Tag.PRACTICE], ["path"], [], []),
	Tag.SCRIPT_SLICE:
		TagDefinition.new("script_slice", false, true, [Tag.PRACTICE], ["path"], ["name"], []),
	Tag.DOCS:
		TagDefinition.new("docs", true, false, [Tag.PRACTICE], [], [], []),
	Tag.SEPARATOR:
		TagDefinition.new("separator", false, true, [Tag.LESSON], [], [], []),
}

const CONTENT_PRODUCING_TAGS := [
	Tag.TITLE,
	Tag.CODEBLOCK,
	Tag.VISUAL,
	Tag.NOTE,
	Tag.QUIZ_CHOICE,
	Tag.QUIZ_INPUT,
	Tag.PRACTICE,
	Tag.SEPARATOR,
]

var _tag_name_to_id := {}
var _tag_id_to_name := {}


func _init() -> void:
	for tag_id in TAG_DEFINITIONS:
		var tag_definition: TagDefinition = TAG_DEFINITIONS[tag_id]
		var tag_name: String = tag_definition.name
		_tag_name_to_id[tag_name] = tag_id
		_tag_id_to_name[tag_id] = tag_name


func get_tag_name(tag_id: int) -> String:
	return _tag_id_to_name.get(tag_id, "unknown")


func get_tag_definition(tag_id: int) -> TagDefinition:
	return TAG_DEFINITIONS.get(tag_id, null)


func get_tag_enum(tag_name: String) -> int:
	return _tag_name_to_id.get(tag_name, Tag.UNKNOWN)


# Returns true if a tag is a container (if it can have children).
func is_container_tag(tag_id: int) -> bool:
	var tag_definition := get_tag_definition(tag_id)
	if tag_definition == null:
		return false
	return tag_definition.container


class TagDefinition:
	var name := ""
	var container := false
	var self_closing := false
	var valid_parents := []
	var required_attrs := []
	var optional_attrs := []
	var required_children := []


	func _init(
			p_name: String,
			p_container: bool,
			p_self_closing: bool,
			p_valid_parents := [],
			p_required_attrs := [],
			p_optional_attrs := [],
			p_required_children := []
	) -> void:
		name = p_name
		container = p_container
		self_closing = p_self_closing
		valid_parents = p_valid_parents
		required_attrs = p_required_attrs
		optional_attrs = p_optional_attrs
		required_children = p_required_children
