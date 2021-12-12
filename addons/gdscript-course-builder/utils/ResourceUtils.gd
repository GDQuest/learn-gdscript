extends Object

# ResourceLoader is unreliable when it comes to cache.
# Sub-resources get cached regardless of the argument passed to load function.
# This is a workaround that generates a new file on a fly,
# while making sure that there is no cache record for it.
# This file is then used to load the resource, after which
# the resource takes over the original path.
static func load_fresh(resource_path: String) -> Resource:
	var resource = File.new()
	var error = resource.open(resource_path, File.READ)
	if error != OK:
		printerr("Failed to load resource '" + resource_path + "': Error code " + str(error))
		return null

	var resource_ext = resource_path.get_extension()
	var random_index = randi()
	var intermediate_path = resource_path + "_temp_" + str(random_index) + "." + resource_ext
	while ResourceLoader.has_cached(intermediate_path):
		random_index = randi()
		intermediate_path = resource_path + "_temp_" + str(random_index) + "." + resource_ext

	var intermediate_resource = File.new()
	error = intermediate_resource.open(intermediate_path, File.WRITE)
	if error != OK:
		printerr("Failed to load resource '" + resource_path + "': Error code " + str(error))
		return null

	var resource_content = resource.get_as_text()
	intermediate_resource.store_string(resource_content)
	intermediate_resource.close()
	resource.close()

	var actual_resource = ResourceLoader.load(intermediate_path, "", true)
	actual_resource.take_over_path(resource_path)

	var directory = Directory.new()
	directory.remove(intermediate_path)
	return actual_resource
