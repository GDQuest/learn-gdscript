extends PracticeTester


var _robot: Node2D
var _body: String
var _has_proper_body: bool


func _prepare() -> void:
	_robot = _scene_root_viewport.get_child(0).get_node("Robot")
	_body = ""
	_has_proper_body = true

	for line in _slice.current_text.split("\n"):
		line = line.strip_edges()
		if line != "":
			_body = line
	
	if _body != "":
		_has_proper_body = _body.replace(" ", "") in ["rotate(delta*2)", "rotate(2*delta)"]


func test_rotating_character_is_time_dependent() -> String:
	if not _has_proper_body:
		#reverse find for any delta at all
		var has_delta: bool = _body.rfind("delta") > 0
		#set parentheses found false by default
		var is_in_parentheses: bool = false

		#Regular expression to check if delta is inside parenthesis
		#I know, regexp is ancient evil magic, as the quote goes:
		#  Some people, when confronted with a problem, think
		#  "I know, I'll use regular expressions" 
		#  Now they have two problems. 
		# But sometimes it does actually work

		var regex_delta_in_parentheses = RegEx.new()
		#This regex matches if:
		#1. rotate appears first
		#2. followed by an open parenthesis
		#3. NOT immediately followed by a close parenthesis 
		#4. delta apppears surrounded by anything else
		#5. a close parenthesis appears
		#from the grep cmdline: grep -Ei "rotate\([^\)]*delta.*\)"

		#NOTE this is not .*delta because the * applies to the preceeding character, which in this case is the negated class ANY character that isn't ")". 
		#If you add an additonal "." this creates a bug and won't match delta unless you have 2 or more characters that aren't ")" before it
		#rather than the correct behavior of 0 or more of anything that isn't ")"

		#thanks to https://regexr.com/ for the awesome regexp playground to help me figure this out after a ton of trial and error and hair pulling. 
		
		#with double backlashes to escape the escapes
		regex_delta_in_parentheses.compile("rotate\\([^\\)]*delta.*\\)") 
		var result = regex_delta_in_parentheses.search(_body)
		
		if result:
			is_in_parentheses = true
			
		if not has_delta:
			return tr("Did you use delta to make the rotation time-dependent?")
		elif not is_in_parentheses:
			return tr("Did you not multiply by delta inside the function call? You need to multiply inside the parentheses for delta to take effect.")
	return ""

func test_rotation_speed_is_2_radians_per_second() -> String:
	if not _has_proper_body:
		#reverse find for any instance of a multiplication asterisk 
		var has_multiplication_sign: bool = _body.rfind("*") > 0
		#set has_two false by default
		var has_two: bool = false

		#Regular expression to check if the function call to rotate has 2 included
		var regex_has_two = RegEx.new()
		#This regex matches if:
		#1. rotate appears first
		#2. followed by an open parenthesis
		#3. followed by any character that is NOT a close parenthesis, numeral, or a decimal
		#4. The numeral 2 appears followed by
		#5. 0 or more characters that aren't close parenthesis, numeral, or a decimal
		#6. followed by a close parenthesis  
		#from the cmdline: grep -Ei "rotate\([^\)0-9.]*2[^0-9.\)]*\)"

		#NOTE: the first regexp excludes 2.0 which is technically valid
		#the regexp would get far more complicated/unreadable if including
		#an optional decimal point and then any number of zeros

		#To catch this case, I've added a second regexp with a non-optional decimal and
		#linked the two with an OR bar
		#This second regex matches if:
		#1. rotate appears first
		#2. followed by an open parenthesis
		#3. followed by any character that is NOT a close parenthesis, numeral, or a decimal
		#4. The numeral 2 appears followed by the decimal point, a literal escaped .
		#5. At least ONE(the + modifier) zero follows the "2." 
		#6. followed by 0 or more characters that aren't a close parenthesis, numeral, or a decimal, or close parenthesis
		#7. followed by a single close parenthesis 
		#from the cmdline: grep -Ei "rotate\([^\)0-9.]*2\.[0]+[^0-9.\)]*\)"

		#the complete regexp with both matches:
		#grep -Ei "rotate\([^\)0-9.]*2[^0-9.\)]*\)|rotate\([^\)0-9.]*2\.[0]+[^0-9.\)]*\)"

		#with double backlashes to escape the escapes
		regex_has_two.compile("rotate\\([^\\)0-9.]*2[^0-9.\\)]*\\)|rotate\\([^\\)0-9.]*2\\.[0]+[^0-9.\\)]*\\)") 

		var result = regex_has_two.search(_body)
		if result:
			has_two = true

		if not has_two:
			return tr("Is the rotation speed correct?")
		elif not has_multiplication_sign:
			return tr("We couldn't find a multiplication sign. Did you use it to make the rotation time-dependent?")
	return ""
