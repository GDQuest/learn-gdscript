# -------------
# returns{} and parameters {} have the followin structure
# -------------
# {
# 	inst_id_or_path1:{
# 		method_name1: [StubParams, StubParams],
# 		method_name2: [StubParams, StubParams]
# 	},
# 	inst_id_or_path2:{
# 		method_name1: [StubParams, StubParams],
# 		method_name2: [StubParams, StubParams]
# 	}
# }
var returns = {}
var _utils = load('res://addons/gut/utils.gd').get_instance()
var _lgr = _utils.get_logger()
var _strutils = _utils.Strutils.new()


func _make_key_from_metadata(doubled):
	var to_return = doubled.__gut_metadata_.path

	if(doubled.__gut_metadata_.from_singleton != ''):
		to_return = str(doubled.__gut_metadata_.from_singleton)
	elif(doubled.__gut_metadata_.subpath != ''):
		to_return += str('-', doubled.__gut_metadata_.subpath)

	return to_return


# Creates they key for the returns hash based on the type of object passed in
# obj could be a string of a path to a script with an optional subpath or
# it could be an instance of a doubled object.
func _make_key_from_variant(obj, subpath=null):
	var to_return = null

	match typeof(obj):
		TYPE_STRING:
			# this has to match what is done in _make_key_from_metadata
			to_return = obj
			if(subpath != null and subpath != ''):
				to_return += str('-', subpath)
		TYPE_OBJECT:
			if(_utils.is_instance(obj)):
				to_return = _make_key_from_metadata(obj)
			elif(_utils.is_native_class(obj)):
				to_return = _utils.get_native_class_name(obj)
			else:
				to_return = obj.resource_path

	return to_return


func _add_obj_method(obj, method, subpath=null):
	var key = _make_key_from_variant(obj, subpath)
	if(_utils.is_instance(obj)):
		key = obj

	if(!returns.has(key)):
		returns[key] = {}
	if(!returns[key].has(method)):
		returns[key][method] = []

	return key

# ##############
# Public
# ##############

# Searches returns for an entry that matches the instance or the class that
# passed in obj is.
#
# obj can be an instance, class, or a path.
func _find_stub(obj, method, parameters=null, find_overloads=false):
	var key = _make_key_from_variant(obj)
	var to_return = null

	if(_utils.is_instance(obj)):
		if(returns.has(obj) and returns[obj].has(method)):
			key = obj
		elif(obj.get('__gut_metadata_')):
			key = _make_key_from_metadata(obj)

	if(returns.has(key) and returns[key].has(method)):
		var param_match = null
		var null_match = null
		var overload_match = null

		for i in range(returns[key][method].size()):
			if(returns[key][method][i].parameters == parameters):
				param_match = returns[key][method][i]

			if(returns[key][method][i].parameters == null):
				null_match = returns[key][method][i]

			if(returns[key][method][i].has_param_override()):
				overload_match = returns[key][method][i]

		if(find_overloads and overload_match != null):
			to_return = overload_match
		# We have matching parameter values so return the stub value for that
		elif(param_match != null):
			to_return = param_match
		# We found a case where the parameters were not specified so return
		# parameters for that.  Only do this if the null match is not *just*
		# a paramerter override stub.
		elif(null_match != null and !null_match.is_param_override_only()):
			to_return = null_match



	return to_return


func add_stub(stub_params):
	stub_params._lgr = _lgr
	var key = _add_obj_method(stub_params.stub_target, stub_params.stub_method, stub_params.target_subpath)
	returns[key][stub_params.stub_method].append(stub_params)


# Gets a stubbed return value for the object and method passed in.  If the
# instance was stubbed it will use that, otherwise it will use the path and
# subpath of the object to try to find a value.
#
# It will also use the optional list of parameter values to find a value.  If
# the object was stubbed with no parameters than any parameters will match.
# If it was stubbed with specific parameter values then it will try to match.
# If the parameters do not match BUT there was also an empty parameter list stub
# then it will return those.
# If it cannot find anything that matches then null is returned.for
#
# Parameters
# obj:  this should be an instance of a doubled object.
# method:  the method called
# parameters:  optional array of parameter vales to find a return value for.
func get_return(obj, method, parameters=null):
	var stub_info = _find_stub(obj, method, parameters)

	if(stub_info != null):
		return stub_info.return_val
	else:
		_lgr.warn(str('Call to [', method, '] was not stubbed for the supplied parameters ', parameters, '.  Null was returned.'))
		return null


func should_call_super(obj, method, parameters=null):
	if(_utils.non_super_methods.has(method)):
		return false

	var stub_info = _find_stub(obj, method, parameters)

	var is_partial = false
	if(typeof(obj) != TYPE_STRING): # some stubber tests test with strings
		is_partial = obj.__gut_metadata_.is_partial
	var should = is_partial

	if(stub_info != null):
		should = stub_info.call_super
	elif(!is_partial):
		# this log message is here because of how the generated doubled scripts
		# are structured.  With this log msg here, you will only see one
		# "unstubbed" info instead of multiple.
		_lgr.info('Unstubbed call to ' + method + '::' + _strutils.type2str(obj))
		should = false

	return should


func get_parameter_count(obj, method):
	var to_return = null
	var stub_info = _find_stub(obj, method, null, true)

	if(stub_info != null and stub_info.has_param_override()):
		to_return = stub_info.parameter_count

	return to_return


func get_default_value(obj, method, p_index):
	var to_return = null
	var stub_info = _find_stub(obj, method, null, true)

	if(stub_info != null and
		stub_info.parameter_defaults != null and
		stub_info.parameter_defaults.size() > p_index):

		to_return = stub_info.parameter_defaults[p_index]

	return to_return


func clear():
	returns.clear()


func get_logger():
	return _lgr


func set_logger(logger):
	_lgr = logger


func to_s():
	var text = ''
	for thing in returns:
		text += str("-- ", thing, " --\n")
		for method in returns[thing]:
			text += str("\t", method, "\n")
			for i in range(returns[thing][method].size()):
				text += "\t\t" + returns[thing][method][i].to_s() + "\n"

	if(text == ''):
		text = 'Stubber is empty';

	return text
