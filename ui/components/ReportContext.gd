class_name ReportContext
extends RefCounted

## Runtime information that helps identify where a report came from.
var platform := ""
var lesson_title := ""
var file_path := ""
var user_code := ""
var commit_hash := ""
var selected_language := ""


## Builds a string with info to help diagnose an issue. Used in report emails.
func build_email_context() -> String:
	var context_text := "Technical information:\n\n"
	context_text += _append_context_line("Lesson", lesson_title)
	context_text += _append_context_line("File", file_path)
	context_text += _append_context_line("Platform", platform)
	context_text += _append_context_line("Commit", commit_hash)
	context_text += _append_context_line("Selected language", selected_language)
	return context_text


func _append_context_line(label: String, value: String) -> String:
	if value.is_empty():
		return ""
	return "- %s: %s\n" % [label, value]
