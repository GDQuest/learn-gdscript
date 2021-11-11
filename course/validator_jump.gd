extends Validator

var timer := Timer.new()


func _ready() -> void:
	add_child(timer)
	timer.wait_time = 0.2
	timer.one_shot = true


# DEPRECATED
func validate(scene: Node, _script: ScriptHandler, _slice: ScriptSlice):
	yield(get_tree(), "idle_frame")
	if not verify(InputMap.has_action("jump"), "no jump action exists"):
		return
	var player = scene.get_node("Level/Player")
	var position = player.position.y
	Input.action_press("jump")
	timer.start()
	yield(timer, "timeout")
	if not verify(player.position.y < position, "player's y didn't increase when pressing jump"):
		return
	_validation_success()


func validate_scene_and_script(scene: Node, _slice_properties: SliceProperties) -> void:
	yield(get_tree(), "idle_frame")
	if not verify(InputMap.has_action("jump"), "no jump action exists"):
		return
	var player = scene.get_node("Level/Player")
	var position = player.position.y
	Input.action_press("jump")
	timer.start()
	yield(timer, "timeout")
	if not verify(player.position.y < position, "player's y didn't increase when pressing jump"):
		return
	_validation_success()
