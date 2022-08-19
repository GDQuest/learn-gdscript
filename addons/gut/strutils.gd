
var _utils = load('res://addons/gut/utils.gd').get_instance()
# Hash containing all the built in types in Godot.  This provides an English
# name for the types that corosponds with the type constants defined in the
# engine.
var types = {}
var NativeScriptClass = null

func _init_types_dictionary():
	types[TYPE_NIL] = 'TYPE_NIL'
	types[TYPE_BOOL] = 'Bool'
	types[TYPE_INT] = 'Int'
	types[TYPE_REAL] = 'Float/Real'
	types[TYPE_STRING] = 'String'
	types[TYPE_VECTOR2] = 'Vector2'
	types[TYPE_RECT2] = 'Rect2'
	types[TYPE_VECTOR3] = 'Vector3'
	#types[8] = 'Matrix32'
	types[TYPE_PLANE] = 'Plane'
	types[TYPE_QUAT] = 'QUAT'
	types[TYPE_AABB] = 'AABB'
	#types[12] = 'Matrix3'
	types[TYPE_TRANSFORM] = 'Transform'
	types[TYPE_COLOR] = 'Color'
	#types[15] = 'Image'
	types[TYPE_NODE_PATH] = 'Node Path'
	types[TYPE_RID] = 'RID'
	types[TYPE_OBJECT] = 'TYPE_OBJECT'
	#types[19] = 'TYPE_INPUT_EVENT'
	types[TYPE_DICTIONARY] = 'Dictionary'
	types[TYPE_ARRAY] = 'Array'
	types[TYPE_RAW_ARRAY] = 'TYPE_RAW_ARRAY'
	types[TYPE_INT_ARRAY] = 'TYPE_INT_ARRAY'
	types[TYPE_REAL_ARRAY] = 'TYPE_REAL_ARRAY'
	types[TYPE_STRING_ARRAY] = 'TYPE_STRING_ARRAY'
	types[TYPE_VECTOR2_ARRAY] = 'TYPE_VECTOR2_ARRAY'
	types[TYPE_VECTOR3_ARRAY] = 'TYPE_VECTOR3_ARRAY'
	types[TYPE_COLOR_ARRAY] = 'TYPE_COLOR_ARRAY'
	types[TYPE_MAX] = 'TYPE_MAX'

# Types to not be formatted when using _str
var _str_ignore_types = [
	TYPE_INT, TYPE_REAL, TYPE_STRING,
	TYPE_NIL, TYPE_BOOL
]

func _init():
	_init_types_dictionary()
	# NativeScript does not exist when GDNative is not included in the build
	if(type_exists('NativeScript')):
		var getter = load('res://addons/gut/get_native_script.gd')
		NativeScriptClass = getter.get_it()

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
func _get_filename(path):
	return path.split('/')[-1]

# ------------------------------------------------------------------------------
# Gets the filename of an object passed in.  This does not return the
# full path to the object, just the filename.
# ------------------------------------------------------------------------------
func _get_obj_filename(thing):
	var filename = null

	if(thing == null or
		!is_instance_valid(thing) or
		str(thing) == '[Object:null]' or
		typeof(thing) != TYPE_OBJECT or
		thing.has_method('__gut_instance_from_id')):
		return

	if(thing.get_script() == null):
		if(thing is PackedScene):
			filename = _get_filename(thing.resource_path)
		else:
			# If it isn't a packed scene and it doesn't have a script then
			# we do nothing.  This just read better.
			pass
	elif(NativeScriptClass != null and thing.get_script() is NativeScriptClass):
		# Work with GDNative scripts:
		# inst2dict fails with "Not a script with an instance" on GDNative script instances
		filename = _get_filename(thing.get_script().resource_path)
	elif(!_utils.is_native_class(thing)):
		var dict = inst2dict(thing)
		filename = _get_filename(dict['@path'])
		if(dict['@subpath'] != ''):
			filename += str('/', dict['@subpath'])

	return filename

# ------------------------------------------------------------------------------
# Better object/thing to string conversion.  Includes extra details about
# whatever is passed in when it can/should.
# ------------------------------------------------------------------------------
func type2str(thing):
	var filename = _get_obj_filename(thing)
	var str_thing = str(thing)

	if(thing == null):
		# According to str there is a difference between null and an Object
		# that is somehow null.  To avoid getting '[Object:null]' as output
		# always set it to str(null) instead of str(thing).  A null object
		# will pass typeof(thing) == TYPE_OBJECT check so this has to be
		# before that.
		str_thing = str(null)
	elif(typeof(thing) == TYPE_REAL):
		if(!'.' in str_thing):
			str_thing += '.0'
	elif(typeof(thing) == TYPE_STRING):
		str_thing = str('"', thing, '"')
	elif(typeof(thing) in _str_ignore_types):
		# do nothing b/c we already have str(thing) in
		# to_return.  I think this just reads a little
		# better this way.
		pass
	elif(typeof(thing) ==  TYPE_OBJECT):
		if(_utils.is_native_class(thing)):
			str_thing = _utils.get_native_class_name(thing)
		elif(_utils.is_double(thing)):
			var double_path = _get_filename(thing.__gut_metadata_.path)
			if(thing.__gut_metadata_.subpath != ''):
				double_path += str('/', thing.__gut_metadata_.subpath)
			elif(thing.__gut_metadata_.from_singleton != ''):
				double_path = thing.__gut_metadata_.from_singleton + " Singleton"

			var double_type = "double"
			if(thing.__gut_metadata_.is_partial):
				double_type = "partial-double"

			str_thing += str("(", double_type, " of ", double_path, ")")

			filename = null
	elif(types.has(typeof(thing))):
		if(!str_thing.begins_with('(')):
			str_thing = '(' + str_thing + ')'
		str_thing = str(types[typeof(thing)], str_thing)

	if(filename != null):
		str_thing += str('(', filename, ')')
	return str_thing

# ------------------------------------------------------------------------------
# Returns the string truncated with an '...' in it.  Shows the start and last
# 10 chars.  If the string is  smaller than max_size the entire string is
# returned.  If max_size is -1 then truncation is skipped.
# ------------------------------------------------------------------------------
func truncate_string(src, max_size):
	var to_return = src
	if(src.length() > max_size - 10 and max_size != -1):
		to_return = str(src.substr(0, max_size - 10), '...',  src.substr(src.length() - 10, src.length()))
	return to_return


func _get_indent_text(times, pad):
	var to_return = ''
	for i in range(times):
		to_return += pad

	return to_return

func indent_text(text, times, pad):
	if(times == 0):
		return text

	var to_return = text
	var ending_newline = ''

	if(text.ends_with("\n")):
		ending_newline = "\n"
		to_return = to_return.left(to_return.length() -1)

	var padding = _get_indent_text(times, pad)
	to_return = to_return.replace("\n", "\n" + padding)
	to_return += ending_newline

	return padding + to_return
