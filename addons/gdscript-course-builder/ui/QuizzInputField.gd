extends VBoxContainer


func setup(quizz: QuizzInputField) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	#TODO
