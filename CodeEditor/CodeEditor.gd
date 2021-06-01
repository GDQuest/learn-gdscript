tool
extends TextEdit


export var class_color: = Color(0.6, 0.6, 1.0)
export var member_color: = Color(0.6, 1.0, 0.6)
export var keyword_color: = Color(1.0, 0.6, 0.6)
export var quotes_color: = Color(1.0, 1.0, 0.6)
export(String, FILE, "*.json") var keyword_data_path: = "res://slide/widgets/text_edit/keywords.json"


func _ready() -> void:
	add_color_region('"', '"', quotes_color)
	add_color_region("'", "'", quotes_color)
	for c in ClassDB.get_class_list():
		add_keyword_color(c, class_color)
		for m in ClassDB.class_get_property_list(c):
			for key in m:
				add_keyword_color(key, member_color)

	var file: = File.new()
	file.open(keyword_data_path, file.READ)
	var keywords: Dictionary = parse_json(file.get_as_text())
	file.close()
	for k in keywords["list"]:
		add_keyword_color(k, keyword_color)
