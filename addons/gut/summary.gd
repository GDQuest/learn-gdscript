# ------------------------------------------------------------------------------
# Contains all the results of a single test.  Allows for multiple asserts results
# and pending calls.
#
# When determining the status of a test, check for failing then passing then
# pending.
# ------------------------------------------------------------------------------
class Test:
	var pass_texts = []
	var fail_texts = []
	var pending_texts = []
	var orphans = 0
	var line_number = 0

	# must have passed an assert and not have any other status to be passing
	func is_passing():
		return pass_texts.size() > 0 and fail_texts.size() == 0 and pending_texts.size() == 0

	# failing takes precedence over everything else, so any failures makes the
	# test a failure.
	func is_failing():
		return fail_texts.size() > 0

	# test is only pending if pending was called and the test is not failing.
	func is_pending():
		return pending_texts.size() > 0 and fail_texts.size() == 0

	func did_something():
		return is_passing() or is_failing() or is_pending()


	# NOTE:  The "failed" and "pending" text must match what is outputted by
	# the logger in order for text highlighting to occur in summary.
	func to_s():
		var pad = '     '
		var to_return = ''
		for i in range(fail_texts.size()):
			to_return += str(pad, '[Failed]:  ', fail_texts[i], "\n")
		for i in range(pending_texts.size()):
			to_return += str(pad, '[Pending]:  ', pending_texts[i], "\n")
		return to_return

	func get_status():
		var to_return = 'no asserts'
		if(pending_texts.size() > 0):
			to_return = 'pending'
		elif(fail_texts.size() > 0):
			to_return = 'fail'
		elif(pass_texts.size() > 0):
			to_return = 'pass'

		return to_return

# ------------------------------------------------------------------------------
# Contains all the results for a single test-script/inner class.  Persists the
# names of the tests and results and the order in which  the tests were run.
# ------------------------------------------------------------------------------
class TestScript:
	var name = 'NOT_SET'
	var _tests = {}
	var _test_order = []

	func _init(script_name):
		name = script_name

	func get_pass_count():
		var count = 0
		for key in _tests:
			count += _tests[key].pass_texts.size()
		return count

	func get_fail_count():
		var count = 0
		for key in _tests:
			count += _tests[key].fail_texts.size()
		return count

	func get_pending_count():
		var count = 0
		for key in _tests:
			count += _tests[key].pending_texts.size()
		return count

	func get_passing_test_count():
		var count = 0
		for key in _tests:
			if(_tests[key].is_passing()):
				count += 1
		return count

	func get_failing_test_count():
		var count = 0
		for key in _tests:
			if(_tests[key].is_failing()):
				count += 1
		return count

	func get_risky_count():
		var count = 0
		for key in _tests:
			if(!_tests[key].did_something()):
				count += 1
		return count


	func get_test_obj(obj_name):
		if(!_tests.has(obj_name)):
			_tests[obj_name] = Test.new()
			_test_order.append(obj_name)
		return _tests[obj_name]

	func add_pass(test_name, reason):
		var t = get_test_obj(test_name)
		t.pass_texts.append(reason)

	func add_fail(test_name, reason):
		var t = get_test_obj(test_name)
		t.fail_texts.append(reason)

	func add_pending(test_name, reason):
		var t = get_test_obj(test_name)
		t.pending_texts.append(reason)

	func get_tests():
		return _tests

# ------------------------------------------------------------------------------
# Summary Class
#
# This class holds the results of all the test scripts and Inner Classes that
# were run.
# ------------------------------------------------------------------------------
var _scripts = []

func add_script(name):
	_scripts.append(TestScript.new(name))

func get_scripts():
	return _scripts

func get_current_script():
	return _scripts[_scripts.size() - 1]

func add_test(test_name):
	return get_current_script().get_test_obj(test_name)

func add_pass(test_name, reason = ''):
	get_current_script().add_pass(test_name, reason)

func add_fail(test_name, reason = ''):
	get_current_script().add_fail(test_name, reason)

func add_pending(test_name, reason = ''):
	get_current_script().add_pending(test_name, reason)

func get_test_text(test_name):
	return test_name + "\n" + get_current_script().get_test_obj(test_name).to_s()

# Gets the count of unique script names minus the .<Inner Class Name> at the
# end.  Used for displaying the number of scripts without including all the
# Inner Classes.
func get_non_inner_class_script_count():
	var unique_scripts = {}
	for i in range(_scripts.size()):
		var ext_loc = _scripts[i].name.find_last('.gd.')
		if(ext_loc == -1):
			unique_scripts[_scripts[i].name] = 1
		else:
			unique_scripts[_scripts[i].name.substr(0, ext_loc + 3)] = 1
	return unique_scripts.keys().size()

func get_totals():
	var totals = {
		passing = 0,
		pending = 0,
		failing = 0,
		risky = 0,
		tests = 0,
		scripts = 0,
		passing_tests = 0,
		failing_tests = 0
	}

	for i in range(_scripts.size()):
		# assert totals
		totals.passing += _scripts[i].get_pass_count()
		totals.pending += _scripts[i].get_pending_count()
		totals.failing += _scripts[i].get_fail_count()

		# test totals
		totals.tests += _scripts[i]._test_order.size()
		totals.passing_tests += _scripts[i].get_passing_test_count()
		totals.failing_tests += _scripts[i].get_failing_test_count()
		totals.risky += _scripts[i].get_risky_count()

	totals.scripts = get_non_inner_class_script_count()

	return totals

func log_summary_text(lgr):
	var orig_indent = lgr.get_indent_level()
	var found_failing_or_pending = false

	for s in range(_scripts.size()):
		lgr.set_indent_level(0)
		if(_scripts[s].get_fail_count() > 0 or _scripts[s].get_pending_count() > 0):
			lgr.log(_scripts[s].name, lgr.fmts.underline)


		for t in range(_scripts[s]._test_order.size()):
			var tname = _scripts[s]._test_order[t]
			var test = _scripts[s].get_test_obj(tname)
			if(!test.is_passing()):
				found_failing_or_pending = true
				lgr.log(str('- ', tname))
				lgr.inc_indent()

				for i in range(test.fail_texts.size()):
					lgr.failed(test.fail_texts[i])
				for i in range(test.pending_texts.size()):
					lgr.pending(test.pending_texts[i])
				if(!test.did_something()):
					lgr.log('[Did not assert]', lgr.fmts.yellow)
				lgr.dec_indent()

	lgr.set_indent_level(0)
	if(!found_failing_or_pending):
		lgr.log('All tests passed', lgr.fmts.green)

	# just picked a non-printable char, dunno if it is a good or bad choice.
	var npws = PoolByteArray([31]).get_string_from_ascii()

	lgr.log()
	var _totals = get_totals()
	lgr.log("Totals", lgr.fmts.yellow)
	lgr.log(str('Scripts:          ', get_non_inner_class_script_count()))
	lgr.log(str('Passing tests     ', _totals.passing_tests))
	lgr.log(str('Failing tests     ', _totals.failing_tests))
	lgr.log(str('Risky tests       ', _totals.risky))
	var pnd=str('Pending:          ', _totals.pending)
	# add a non printable character so this "pending" isn't highlighted in the
	# editor's output panel.
	lgr.log(str(npws, pnd))
	lgr.log(str('Asserts:          ', _totals.passing, ' of ', _totals.passing + _totals.failing, ' passed'))

	lgr.set_indent_level(orig_indent)

