tool
class_name LessonPanel
extends PanelContainer

export var title := "Title" setget set_title

onready var title_label := find_node("Title") as Label
onready var progress_bar := find_node("ProgressBar") as ProgressBar
onready var goal_rich_text_label := find_node("Goal").find_node("TextBox") as RichTextLabel
onready var checks_container := find_node("Checks") as Revealer
onready var hints_container := find_node("Hints") as Revealer


func set_title(new_title: String) -> void:
	title = new_title
	if not is_inside_tree():
		yield(self, "ready")
	title_label.text = title
