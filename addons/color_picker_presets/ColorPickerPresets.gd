@tool
extends EditorPlugin

const PRESETS_FILENAME := 'presets.hex'


func _enter_tree() -> void:
	var presets_path: String = get_script().resource_path.get_base_dir().path_join(PRESETS_FILENAME)
	if not FileAccess.file_exists(presets_path):
		return

	var presets_file := FileAccess.open(presets_path, FileAccess.READ)
	if not presets_file:
		return

	var presets_raw := presets_file.get_as_text().split("\n", false)
	var presets := PackedColorArray()

	for color_hex in presets_raw:
		var hex := color_hex.strip_edges()
		if hex.is_valid_html_color():
			presets.push_back(Color(hex))

	var editor_settings := get_editor_interface().get_editor_settings()
	editor_settings.set_project_metadata("color_picker", "presets", presets)
