# Since NativeScript does not exist if GDNative is not included in the build
# of Godot this script is conditionally loaded only when NativeScript exists.
# You can then get a reference to NativeScript for use in `is` checks by calling
# get_it.
static func get_it():
	return NativeScript
