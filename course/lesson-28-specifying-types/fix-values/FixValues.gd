extends Node

# EXPORT fix
var whole_number: int = 4
var text: String = "Hello, world!"
var vector: Vector2 = Vector2(1, 1)
var decimal_number: float = 3.14
# /EXPORT fix

func _run():
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")
