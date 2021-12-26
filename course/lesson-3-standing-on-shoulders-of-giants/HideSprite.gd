extends Node2D

func run():
	yield(get_tree().create_timer(0.5), "timeout")
	hide()

func reset():
	show()
