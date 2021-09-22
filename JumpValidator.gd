extends Validator


func validate(scene: Node, _script_text: String):
	yield(get_tree(), "idle_frame")
	if not verify(InputMap.has_action("jump"), "no jump action"):
		return
	var player = scene.get_node("Player")
	var position = player.position.y
	print(position)
	Input.action_press("jump")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	prints(player.position.y, position)
	if not verify(player.position.y < position, "player's y didn't increase when pressing jump"):
		return
	emit_signal("validation_completed", [])
