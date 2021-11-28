# Represents one slice of a script. This is typically a section of a script that
# corresponds to what you want the student to code in a practice.
class_name ScriptSlice
extends Resource

export var start := 27
export var end := 33
export var leading_spaces := 0
export var keyword := ""
export var name := ""
export var lines_before := []
export var lines_after := []
export var lines_editable := []
export var closing := false
export var is_full_file := false
