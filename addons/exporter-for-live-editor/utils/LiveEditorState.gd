extends Node

var current_slice: SliceProperties
signal slice_changed

func set_current_slice(new_slice: SliceProperties) -> void:
	if new_slice == current_slice:
		return
	current_slice = new_slice
	emit_signal("slice_changed")
