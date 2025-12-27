extends PanelContainer

@onready var input_field := $MarginContainer/VBoxContainer/HBoxContainer2/SpinBox as SpinBox


func _run():
	buy_selected_item()
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")


# EXPORT run
var player_input = ""
var item_count = 0

func buy_selected_item():
	player_input = get_player_input()
	item_count = int(player_input)
# /EXPORT run


func get_player_input():
	return input_field.value
