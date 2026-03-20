@tool
extends EditorPlugin

const PRESETS_FILENAME := 'presets.hex'


func _enter_tree() -> void:
	var presets := PackedColorArray()
	var presets_raw := PackedStringArray()
	var presets_path: String = get_script().resource_path.get_base_dir().path_join(PRESETS_FILENAME)
	var presets_file := FileAccess.open(presets_path, FileAccess.READ)

	if presets_file:
		presets_raw = presets_file.get_as_text().split("\n")
		presets_file.close()

		for hex in presets_raw:
			if hex.is_valid_html_color():
				presets.push_back(Color(hex))

		get_editor_interface().get_editor_settings().set_project_metadata(
			"color_picker", "presets", presets
		)
