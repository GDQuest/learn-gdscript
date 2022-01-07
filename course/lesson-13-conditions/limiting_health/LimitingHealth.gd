extends Control

func _run():
	heal(100)

# EXPORT heal
var health = 20

func heal(amount):
	health = health + amount
	if health > 80:
		health = 80
# /EXPORT heal
