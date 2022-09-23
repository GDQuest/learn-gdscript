class CallParameters:
	var p_name = null
	var default = null

	func _init(n, d):
		p_name = n
		default = d


# ------------------------------------------------------------------------------
# This class will generate method declaration lines based on method meta
# data.  It will create defaults that match the method data.
#
# --------------------
# function meta data
# --------------------
# name:
# flags:
# args: [{
# 	(class_name:),
# 	(hint:0),
# 	(hint_string:),
# 	(name:),
# 	(type:4),
# 	(usage:7)
# }]
# default_args []

var _utils = load('res://addons/gut/utils.gd').get_instance()
var _lgr = _utils.get_logger()
const PARAM_PREFIX = 'p_'

# ------------------------------------------------------
# _supported_defaults
#
# This array contains all the data types that are supported for default values.
# If a value is supported it will contain either an empty string or a prefix
# that should be used when setting the parameter default value.
# For example int, real, bool do not need anything func(p1=1, p2=2.2, p3=false)
# but things like Vectors and Colors do since only the parameters to create a
# new Vector or Color are included in the metadata.
# ------------------------------------------------------
	# TYPE_NIL = 0 — Variable is of type nil (only applied for null).
	# TYPE_BOOL = 1 — Variable is of type bool.
	# TYPE_INT = 2 — Variable is of type int.
	# TYPE_REAL = 3 — Variable is of type float/real.
	# TYPE_STRING = 4 — Variable is of type String.
	# TYPE_VECTOR2 = 5 — Variable is of type Vector2.
	# TYPE_RECT2 = 6 — Variable is of type Rect2.
	# TYPE_VECTOR3 = 7 — Variable is of type Vector3.
	# TYPE_COLOR = 14 — Variable is of type Color.
	# TYPE_OBJECT = 17 — Variable is of type Object.
	# TYPE_DICTIONARY = 18 — Variable is of type Dictionary.
	# TYPE_ARRAY = 19 — Variable is of type Array.
	# TYPE_VECTOR2_ARRAY = 24 — Variable is of type PoolVector2Array.
	# TYPE_TRANSFORM = 13 — Variable is of type Transform.
	# TYPE_TRANSFORM2D = 8 — Variable is of type Transform2D.
	# TYPE_RID = 16 — Variable is of type RID.
	# TYPE_INT_ARRAY = 21 — Variable is of type PoolIntArray.
	# TYPE_REAL_ARRAY = 22 — Variable is of type PoolRealArray.
	# TYPE_STRING_ARRAY = 23 — Variable is of type PoolStringArray.


# TYPE_PLANE = 9 — Variable is of type Plane.
# TYPE_QUAT = 10 — Variable is of type Quat.
# TYPE_AABB = 11 — Variable is of type AABB.
# TYPE_BASIS = 12 — Variable is of type Basis.
# TYPE_NODE_PATH = 15 — Variable is of type NodePath.
# TYPE_RAW_ARRAY = 20 — Variable is of type PoolByteArray.
# TYPE_VECTOR3_ARRAY = 25 — Variable is of type PoolVector3Array.
# TYPE_COLOR_ARRAY = 26 — Variable is of type PoolColorArray.
# TYPE_MAX = 27 — Marker for end of type constants.
# ------------------------------------------------------
var _supported_defaults = []

func _init():
	for _i in range(TYPE_MAX):
		_supported_defaults.append(null)

	# These types do not require a prefix for defaults
	_supported_defaults[TYPE_NIL] = ''
	_supported_defaults[TYPE_BOOL] = ''
	_supported_defaults[TYPE_INT] = ''
	_supported_defaults[TYPE_REAL] = ''
	_supported_defaults[TYPE_OBJECT] = ''
	_supported_defaults[TYPE_ARRAY] = ''
	_supported_defaults[TYPE_STRING] = ''
	_supported_defaults[TYPE_DICTIONARY] = ''
	_supported_defaults[TYPE_VECTOR2_ARRAY] = ''
	_supported_defaults[TYPE_RID] = ''

	# These require a prefix for whatever default is provided
	_supported_defaults[TYPE_VECTOR2] = 'Vector2'
	_supported_defaults[TYPE_RECT2] = 'Rect2'
	_supported_defaults[TYPE_VECTOR3] = 'Vector3'
	_supported_defaults[TYPE_COLOR] = 'Color'
	_supported_defaults[TYPE_TRANSFORM2D] = 'Transform2D'
	_supported_defaults[TYPE_TRANSFORM] = 'Transform'
	_supported_defaults[TYPE_INT_ARRAY] = 'PoolIntArray'
	_supported_defaults[TYPE_REAL_ARRAY] = 'PoolRealArray'
	_supported_defaults[TYPE_STRING_ARRAY] = 'PoolStringArray'

# ###############
# Private
# ###############
var _func_text = _utils.get_file_as_text('res://addons/gut/double_templates/function_template.txt')
var _init_text = _utils.get_file_as_text('res://addons/gut/double_templates/init_template.txt')

func _is_supported_default(type_flag):
	return type_flag >= 0 and type_flag < _supported_defaults.size() and _supported_defaults[type_flag] != null


func _make_stub_default(method, index):
	return str('__gut_default_val("', method, '",', index, ')')

func _make_arg_array(method_meta, override_size):
	var to_return = []

	var has_unsupported_defaults = false
	var dflt_start = method_meta.args.size() - method_meta.default_args.size()

	for i in range(method_meta.args.size()):
		var pname = method_meta.args[i].name
		var dflt_text = ''

		if(i < dflt_start):
			dflt_text = _make_stub_default(method_meta.name, i)
		else:
			var dflt_idx = i - dflt_start
			var t = method_meta.args[i]['type']
			if(_is_supported_default(t)):
				# strings are special, they need quotes around the value
				if(t == TYPE_STRING):
					dflt_text = str("'", str(method_meta.default_args[dflt_idx]), "'")
				# Colors need the parens but things like Vector2 and Rect2 don't
				elif(t == TYPE_COLOR):
					dflt_text = str(_supported_defaults[t], '(', str(method_meta.default_args[dflt_idx]), ')')
				elif(t == TYPE_OBJECT):
					if(str(method_meta.default_args[dflt_idx]) == "[Object:null]"):
						dflt_text = str(_supported_defaults[t], 'null')
					else:
						dflt_text = str(_supported_defaults[t], str(method_meta.default_args[dflt_idx]).to_lower())
				elif(t == TYPE_TRANSFORM):
					# value will be 4 Vector3 and look like: 1, 0, 0, 0, 1, 0, 0, 0, 1 - 0, 0, 0
					var sections = str(method_meta.default_args[dflt_idx]).split("-")
					var vecs = sections[0].split(",")
					vecs.append_array(sections[1].split(","))
					var v1 = str("Vector3(", vecs[0], ", ", vecs[1], ", ", vecs[2], ")")
					var v2 = str("Vector3(", vecs[3], ", ", vecs[4], ", ", vecs[5], ")")
					var v3 = str("Vector3(", vecs[6], ", ", vecs[7], ", ", vecs[8], ")")
					var v4 = str("Vector3(", vecs[9], ", ", vecs[10], ", ", vecs[11], ")")
					dflt_text = str(_supported_defaults[t], "(", v1, ", ", v2, ", ", v3, ", ", v4, ")")
				elif(t == TYPE_TRANSFORM2D):
					# value will look like:  ((1, 0), (0, 1), (0, 0))
					var vectors = str(method_meta.default_args[dflt_idx])
					vectors = vectors.replace("((", "(")
					vectors = vectors.replace("))", ")")
					vectors = vectors.replace("(", "Vector2(")
					dflt_text = str(_supported_defaults[t], "(", vectors, ")")
				elif(t == TYPE_RID):
					dflt_text = str(_supported_defaults[t], 'null')
				elif(t in [TYPE_REAL_ARRAY, TYPE_INT_ARRAY, TYPE_STRING_ARRAY]):
					dflt_text = str(_supported_defaults[t], "()")
				# Everything else puts the prefix (if one is there) from _supported_defaults
				# in front.  The to_lower is used b/c for some reason the defaults for
				# null, true, false are all "Null", "True", "False".
				else:
					dflt_text = str(_supported_defaults[t], str(method_meta.default_args[dflt_idx]).to_lower())
			else:
				_lgr.error(str(
					'Unsupported default param type:  ',method_meta.name, '-', method_meta.args[i].name, ' ', t, ' = ', method_meta.default_args[dflt_idx]))
				dflt_text = str('unsupported=',t)
				has_unsupported_defaults = true

		# Finally add in the parameter
		to_return.append(CallParameters.new(PARAM_PREFIX + pname, dflt_text))

	# Add in extra parameters from stub settings.
	if(override_size != null):
		for i in range(method_meta.args.size(), override_size):
			var pname = str(PARAM_PREFIX, 'arg', i)
			var dflt_text = _make_stub_default(method_meta.name, i)
			to_return.append(CallParameters.new(pname, dflt_text))

	return [has_unsupported_defaults, to_return];


# Creates a list of parameters with defaults of null unless a default value is
# found in the metadata.  If a default is found in the meta then it is used if
# it is one we know how support.
#
# If a default is found that we don't know how to handle then this method will
# return null.
func _get_arg_text(arg_array):
	var text = ''

	for i in range(arg_array.size()):
		text += str(arg_array[i].p_name, '=', arg_array[i].default)
		if(i != arg_array.size() -1):
			text += ', '

	return text


# creates a call to the function in meta in the super's class.
func _get_super_call_text(method_name, args, super_name=""):
	var params = ''
	for i in range(args.size()):
		params += args[i].p_name
		if(i != args.size() -1):
			params += ', '

	return str(super_name, '.', method_name, '(', params, ')')


func _get_spy_call_parameters_text(args):
	var called_with = 'null'

	if(args.size() > 0):
		called_with = '['
		for i in range(args.size()):
			called_with += args[i].p_name
			if(i < args.size() - 1):
				called_with += ', '
		called_with += ']'

	return called_with


# ###############
# Public
# ###############

func _get_init_text(meta, args, method_params, param_array):
	var text = null

	var decleration = str('func ', meta.name, '(', method_params, ')')
	var super_params = ''
	if(args.size() > 0):
		super_params = '.('
		for i in range(args.size()):
			super_params += args[i].p_name
			if(i != args.size() -1):
				super_params += ', '
		super_params += ')'

	text = _init_text.format({
		"func_decleration":decleration,
		"super_params":super_params,
		"param_array":param_array,
		"method_name":meta.name
	})

	return text


# Creates a delceration for a function based off of function metadata.  All
# types whose defaults are supported will have their values.  If a datatype
# is not supported and the parameter has a default, a warning message will be
# printed and the declaration will return null.
#
# path is no longer used
func get_function_text(meta, path=null, override_size=null, super_name=""):
	var method_params = ''
	var text = null
	var result = _make_arg_array(meta, override_size)
	var has_unsupported = result[0]
	var args = result[1]

	var param_array = _get_spy_call_parameters_text(args)

	if(has_unsupported):
		# This will cause a runtime error.  This is the most convenient way to
		# to stop running before the error gets more obscure.  _make_arg_array
		# generates a gut error when unsupported defaults are found.
		method_params = null
	else:
		method_params = _get_arg_text(args);

	if(param_array == 'null'):
		param_array = '[]'

	if(method_params != null):
		if(meta.name == '_init'):
			text =  _get_init_text(meta, args, method_params, param_array)
		else:
			var decleration = str('func ', meta.name, '(', method_params, '):')
			text = _func_text.format({
				"func_decleration":decleration,
				"method_name":meta.name,
				"param_array":param_array,
				"super_call":_get_super_call_text(meta.name, args, super_name)
			})

	return text




func get_logger():
	return _lgr

func set_logger(logger):
	_lgr = logger
