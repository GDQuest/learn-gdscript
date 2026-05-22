@tool
## Extracts C++-only functions via their signals or bound call("") methods in exposed dialogs or controls
extends RefCounted


static var _template_generate: Callable
static var _localization_editor: Node


## Side effects: Generates/overwrites a path at path, which should be a POT or CSV
## Uses the files located in the Localization/Template Generation tab in Project Settings
static func template_generate(path: String) -> void:
	if _template_generate.is_null():
		_template_generate = _extract_generate_template_callable()
	if _template_generate.is_null():
		push_error("Failed to locate the _template_generate() callable")
		return
	_template_generate.call(path)


static func get_localization_editor() -> Node:
	if _localization_editor:
		return _localization_editor
	var editor_interface := EditorInterface.get_base_control()
	var project_settings_dialog: Node
	for settings_child: Node in editor_interface.get_children():
		if settings_child.get_class() != "ProjectSettingsEditor":
			continue
		for dialog_child: Node in settings_child.get_children():
			if dialog_child is not TabContainer:
				continue
			for tab_child: Node in dialog_child.get_children():
				if tab_child.name != "Localization":
					continue
				_localization_editor = tab_child
				return tab_child
	return null


static func _extract_generate_template_callable() -> Callable:
	for child: Node in get_localization_editor().get_children():
		if child is not EditorFileDialog or child.file_selected.get_connections().is_empty():
			continue
		return child.file_selected.get_connections()[0].callable
	return Callable()
