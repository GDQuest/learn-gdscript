extends Control

func _run():
	heal(100)

var health = 20

# EXPORT heal
func heal(amount):
	health = health + amount
	if health > 80:
		health = 80
# /EXPORT heal
