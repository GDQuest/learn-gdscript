extends PracticeTester


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Run The Code"), tr("Press the Run button to run the code"), test_run_the_code))


func test_run_the_code() -> String:
	return ""
