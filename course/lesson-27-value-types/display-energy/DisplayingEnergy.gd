extends Node

@onready var bar := $VBoxContainer/HBoxContainer/Bar as ProgressBar

@onready var energy_label := $VBoxContainer/HBoxContainer/Bar/EnergyLabel as Label
@onready var shadow := $VBoxContainer/HBoxContainer/Bar/EnergyLabel/Shadow as Label


func _run():
	run()
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")


# EXPORT run
var energy = 80

func run():
	display_energy(str(energy))
# /EXPORT run
	bar.value = energy


func display_energy(value):
	if not value is String:
		return
	energy_label.text = "%s / 100" % value
	shadow.text = energy_label.text
