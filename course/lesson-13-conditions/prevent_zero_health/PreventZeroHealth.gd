extends Control

func _run():
	take_damage(100)

var health = 20

# EXPORT heal
func take_damage(amount):
	health = health - amount
	if health < 0:
		health = 0
# /EXPORT heal
