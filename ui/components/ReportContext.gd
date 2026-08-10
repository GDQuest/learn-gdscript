class_name ReportContext
extends RefCounted

## Runtime information that helps identify where a report came from.
var platform := ""
var lesson_title := ""
var practice_title := ""
var file_path := ""
var user_code := ""
var commit_hash := ""
var selected_language := ""

## Location identifier like "L1" or "L2". Used in report emails.
var lesson_id := ""
## Location identifier like "P1". Used in report emails when the report comes from a practice.
var practice_id := ""


## Builds a string with info to help diagnose an issue. Used in report emails.
func build_email_context() -> String:
	var context_text := "Technical information:\n\n"
	var location := ""
	if not lesson_id.is_empty():
		location = lesson_id
		if not practice_id.is_empty():
			location += "." + practice_id
		location += " - "
	location += lesson_title
	if not practice_id.is_empty():
		location += " > " + practice_title
	context_text += _append_context_line("Location", location)
	context_text += _append_context_line("File", file_path)
	context_text += _append_context_line("Platform", platform)
	context_text += _append_context_line("Commit", commit_hash)
	context_text += _append_context_line("Selected language", selected_language)
	return context_text


func _append_context_line(label: String, value: String) -> String:
	if value.is_empty():
		return ""
	return "- %s: %s\n" % [label, value]
