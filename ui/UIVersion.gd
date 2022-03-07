extends Control


onready var _rich_text_label := $RichTextLabel


func _ready() -> void:
	visible = not OS.has_feature("web")

	_rich_text_label.connect("meta_clicked", OS, "shell_open")
	_rich_text_label.connect("meta_hover_started", self, "_on_meta_hover_started")
	_rich_text_label.connect("meta_hover_ended", self, "_on_meta_hover_ended")

	var text := PoolStringArray([
		"[right]",
		"%04d/%02d/%02d %02d:%02d:%02d" % AppVersion.build_date,
		" | ",
		"%s:%s:" % [AppVersion.git_branch, AppVersion.version],
		"[url=https://github.com/GDQuest/learn-gdscript/tree/{0}]{0}[/url]".format([AppVersion.git_commit]),
		"[/right]"
	]).join("")

	if AppVersion.git_branch == "release":
		text = PoolStringArray([
			"[right]",
			"[url=https://github.com/GDQuest/learn-gdscript/blob/main/CHANGELOG.md]",
			"version: %s" % AppVersion.version,
			"[/url]",
			"[/right]"
		]).join("")

	_rich_text_label.bbcode_text = text


func _on_meta_hover_started(_meta: String) -> void:
	_rich_text_label.mouse_default_cursor_shape = CURSOR_POINTING_HAND


func _on_meta_hover_ended(_meta: String) -> void:
	_rich_text_label.mouse_default_cursor_shape = CURSOR_ARROW
