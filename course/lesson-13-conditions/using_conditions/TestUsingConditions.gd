extends PracticeTester

var ANSWERS = [
	"health\\s*>\\s*5",
	"1\\s*<\\s*health",
	"health\\s*==\\s*health",
	"health\\s*!=\\s*7"
]

const STATEMENTS = [
	"health is greater than five.",
	"One is less than health.",
	"health is equal to health",
	"health is not equal to seven."
]

func test_statement_1_is_true() -> String:
	var regex = RegEx.new()
	regex.compile(ANSWERS[0] + "\\s*\\:\\s*.*" + STATEMENTS[0])
	var result = regex.search(_slice.current_text)
	if not result:
		return tr("The first comparison is not correct. Did you use the right comparison?")
	return ""


func test_statement_2_is_true() -> String:
	var regex = RegEx.new()
	regex.compile(ANSWERS[1] + "\\s*\\:\\s*.*" + STATEMENTS[1])
	var result = regex.search(_slice.current_text)
	if not result:
		return tr("The second comparison is not correct. Did you use the right comparison?")
	return ""


func test_statement_3_is_true() -> String:
	var regex = RegEx.new()
	regex.compile(ANSWERS[2] + "\\s*\\:\\s*.*" + STATEMENTS[2])
	var result = regex.search(_slice.current_text)
	if not result:
		return tr("The third comparison is not correct. Did you use the right comparison?")
	return ""


func test_statement_4_is_true() -> String:
	var regex = RegEx.new()
	regex.compile(ANSWERS[3] + "\\s*\\:\\s*.*" + STATEMENTS[3])
	var result = regex.search(_slice.current_text)
	if not result:
		return tr("The fourth comparison is not correct. Did you use the right comparison?")
	return ""
