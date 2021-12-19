tool
class_name CodeRefList
extends VBoxContainer

const CodeRefItemScene = preload("CodeRefItem.tscn")

var _practice: Practice

onready var _add_button := $Header/AddButton as Button


func _ready() -> void:
	_add_button.connect("pressed", self, "_add_function")


func setup(practice: Practice) -> void:
	_practice = practice
	if not is_inside_tree():
		yield(self, "ready")
	for function in practice.documentation_references:
		_add_function(function)


func _update_list_labels() -> void:
	var index := 1
	for child in get_children():
		if child is CodeRefItem:
			child.set_list_index(index)
			index += 1


func _update_practice_code_ref() -> void:
	var refs := PoolStringArray()
	for child in get_children():
		if not child is CodeRefItem or child.is_queued_for_deletion():
			continue
		refs.append(child.get_text())
	_practice.documentation_references = refs
	_practice.emit_changed()


func _add_function(function := "") -> void:
	var instance = CodeRefItemScene.instance()
	add_child(instance)
	instance.set_text(function)
	instance.connect("index_changed", self, "_update_list_labels")
	instance.connect("text_changed", self, "_update_practice_code_ref")
	instance.connect("removed", self, "_update_practice_code_ref")
