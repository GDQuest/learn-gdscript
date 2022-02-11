extends Node2D


func _run():
	run()


# EXPORT conditions
func run():
	var health = 100
	
	if health > 5:
		print("health is greater than five.")
	
	if 1 < health:
		print("One is less than health.")
	
	if health == health:
		print("health is equal to health")
	
	if health != 7:
		print("health is not equal to seven.")
# /EXPORT conditions
	Events.emit_signal("practice_run_completed")
