extends Control

# EXPORT health
var health = 100
# /EXPORT health

func _ready():
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")
