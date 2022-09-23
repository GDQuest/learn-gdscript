var _utils = load('res://addons/gut/utils.gd').get_instance()
var _lgr = _utils.get_logger()

var return_val = null
var stub_target = null
var target_subpath = null
# the parameter values to match method call on.
var parameters = null
var stub_method = null
var call_super = false

# -- Paramter Override --
# Parmater overrides are stored in here along with all the other stub info
# so that you can chain stubbing parameter overrides along with all the
# other stubbing.  This adds some complexity to the logic that tries to
# find the correct stub for a call by a double.  Since an instance of this
# class could be just a parameter override, or it could have been chained
# we have to have _paramter_override_only so that we know when to tell the
# difference.
var parameter_count = -1
var parameter_defaults = null
# Anything that would make this stub not just an override of paramters
# must set this flag to false.  This must be private bc the actual logic
# to determine if this stub is only an override is more complicated.
var _parameter_override_only = true
# --

const NOT_SET = '|_1_this_is_not_set_1_|'

func _init(target=null, method=null, subpath=null):
	stub_target = target
	stub_method = method
	target_subpath = subpath


func to_return(val):
	if(stub_method == '_init'):
		_lgr.error("You cannot stub _init to do nothing.  Super's _init is always called.")
	else:
		return_val = val
		call_super = false
		_parameter_override_only = false
	return self


func to_do_nothing():
	to_return(null)
	return self


func to_call_super():
	if(stub_method == '_init'):
		_lgr.error("You cannot stub _init to call super.  Super's _init is always called.")
	else:
		call_super = true
		_parameter_override_only = false
	return self


func when_passed(p1=NOT_SET,p2=NOT_SET,p3=NOT_SET,p4=NOT_SET,p5=NOT_SET,p6=NOT_SET,p7=NOT_SET,p8=NOT_SET,p9=NOT_SET,p10=NOT_SET):
	parameters = [p1,p2,p3,p4,p5,p6,p7,p8,p9,p10]
	var idx = 0
	while(idx < parameters.size()):
		if(str(parameters[idx]) == NOT_SET):
			parameters.remove(idx)
		else:
			idx += 1
	return self


func param_count(x):
	parameter_count = x
	return self


func param_defaults(values):
	parameter_count = values.size()
	parameter_defaults = values
	return self


func has_param_override():
	return parameter_count != -1


func is_param_override_only():
	var to_return = false
	if(has_param_override()):
		to_return = _parameter_override_only
	return to_return


func to_s():
	var base_string = str(stub_target)
	if(target_subpath != null):
		base_string += str('[', target_subpath, '].')
	else:
		base_string += '.'
	base_string += stub_method

	if(has_param_override()):
		base_string += str(' (param count override=', parameter_count, ' defaults=', parameter_defaults)
		if(is_param_override_only()):
			base_string += " ONLY"
		base_string += ') '

	if(call_super):
		base_string += " to call SUPER"

	if(parameters != null):
		base_string += str(' with params (', parameters, ') returns ', return_val)

	return base_string
