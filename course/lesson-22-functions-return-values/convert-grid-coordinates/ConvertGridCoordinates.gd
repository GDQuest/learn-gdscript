extends Control

func _run():
	yield(get_tree().create_timer(0.5), "timeout")
	Events.emit_signal("practice_run_completed")

# EXPORT run
var cell_size = Vector2(120, 120)

func convert_to_world_coordinates(cell):
	return cell * cell_size + cell_size / 2
# /EXPORT run
