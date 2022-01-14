class_name UUID
extends Reference
# Crypto UUID v4
#
# Provides cryptographically secure UUID v4 objects.
# Can be used and compared in string format,
# or as persistent UUID reference objects.
#
# See https://github.com/Yukitty/godot-addon-crypto_uuid_v4/
# for usage details.


# Internal state
# Prefer `UUID.new(from)` and `uuid_a.is_equal(uuid_b)`
# over messing with these, please
var _data: PoolByteArray
var _string: String


func _init(from = null):
	if from is PoolByteArray:
		assert(from.size() == 16)
		_data = from
	elif from is String:
		assert(from.length() == 36)
		_data = PoolByteArray([
			_hex_byte(from, 0), _hex_byte(from, 2), _hex_byte(from, 4), _hex_byte(from, 6),
			# skip hyphen
			_hex_byte(from, 9), _hex_byte(from, 11),
			# skip hyphen
			_hex_byte(from, 14), _hex_byte(from, 16),
			# skip hyphen
			_hex_byte(from, 19), _hex_byte(from, 21),
			# skip hyphen
			_hex_byte(from, 24), _hex_byte(from, 26), _hex_byte(from, 28),
			_hex_byte(from, 30), _hex_byte(from, 32), _hex_byte(from, 34)
		])
		_string = from
	else:
		_data = v4bin()

	# Sanity tests
	assert(_data[6] & 0xf0 == 0x40)
	assert(_data[8] & 0xc0 == 0x80)


# Special string representation
# Cached for rapid comparisons
func _to_string() -> String:
	if _string:
		return _string
	_string = format(_data)
	return _string


# Compare a UUID object with another UUID, String, or PoolByteArray.
func is_equal(object) -> bool:
	# Compare UUID
	if object is Object and get_script().instance_has(object):
		# If string cache is available, compare string refs (fastest)
		if _string and object._string:
			return _string == object._string
		# Otherwise, compare data
		# (slightly slower, but faster than building a string)
		assert(object._data is PoolByteArray)
		object = object._data
		# Fallthrough to PoolByteArray handling

	# int compare, stop at first mismatch
	if object is PoolByteArray:
		if object.size() != 16:
			return false
		for i in 16:
			if _data[i] != object[i]:
				return false
		return true

	# Build string representation (if needed) and compare
	if not _string:
		_string = format(_data)
	return _string == str(object)


# Convinience func, essentially str(UUID.new())
static func v4() -> String:
	return format(v4bin())


# Generate efficient binary representation
# Returns PoolByteArray[16] of cryptographically-secure (if available)
# random bytes with a UUID v4 compatible signature.
static func v4bin() -> PoolByteArray:
	var data: PoolByteArray

	if OS.has_feature("web"):
		# Fallback for HTML5 export
		if OS.has_feature("JavaScript"):
			# Rely on browser's Crypto object if available
			var output = JavaScript.eval("window.crypto.getRandomValues(new Uint8Array(16));")
			if output is PoolByteArray and output.size() == 16:
				data = output

		if not data:
			# Generate weak random values
			# ONLY when Crypto is not provided by the browser
			randomize()
			data = PoolByteArray([
				_randb(), _randb(), _randb(), _randb(),
				_randb(), _randb(), _randb(), _randb(),
				_randb(), _randb(), _randb(), _randb(),
				_randb(), _randb(), _randb(), _randb()
			])

	else:
		# Use cryptographically secure bytes when available
		data = Crypto.new().generate_random_bytes(16)

	data[6] = (data[6] & 0x0f) | 0x40
	data[8] = (data[8] & 0x3f) | 0x80
	return data

# Format any 16 bytes as a UUID.
static func format(data: PoolByteArray) -> String:
	assert(data.size() == 16)
	return '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x' % (data as Array)


# Private helper func
static func _randb() -> int:
	return randi() % 0x100


static func _hex_byte(text: String, offset: int) -> int:
	return ("0x" + text.substr(offset, 2)).hex_to_int()
