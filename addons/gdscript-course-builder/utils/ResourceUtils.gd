extends Object

# ResourceLoader is unreliable when it comes to cache.
# Sub-resources get cached regardless of the argument passed to load function.
# This is a workaround that generates a new file on a fly,
# while making sure that there is no cache record for it.
# This file is then used to load the resource, after which
# the resource takes over the original path.

# NOTE (Godot 4 migration):
# In Godot 3 this helper worked around ResourceLoader cache issues by forcing
# a load from a temporary file path.
# Godot 4 introduces explicit cache control (CACHE_MODE_IGNORE), which may
# make this workaround unnecessary.
# The code is kept to preserve behavior during the port and avoid regressions.
# Revisit after validating resource loading in all editor workflows.
static func load_fresh(resource_path: String) -> Resource:
	var resource := FileAccess.open(resource_path, FileAccess.READ)
	if resource == null:
		printerr("Failed to load resource '%s'" % resource_path)
		return null

	var resource_ext := resource_path.get_extension()
	var random_index := randi()
	var intermediate_path := resource_path + "_temp_" + str(random_index) + "." + resource_ext
	while ResourceLoader.has_cached(intermediate_path):
		random_index = randi()
		intermediate_path = resource_path + "_temp_" + str(random_index) + "." + resource_ext

	var intermediate_resource := FileAccess.open(intermediate_path, FileAccess.WRITE)
	if intermediate_resource == null:
		printerr("Failed to write temp resource '%s'" % intermediate_path)
		return null

	var resource_content := resource.get_as_text()
	intermediate_resource.store_string(resource_content)
	# FileAccess closes automatically when freed, but explicit is fine:
	intermediate_resource.close()
	resource.close()

	var actual_resource: Resource = ResourceLoader.load(
		intermediate_path,
		"",
		ResourceLoader.CACHE_MODE_IGNORE
	)
	if actual_resource == null:
		printerr("Failed to load temp resource '%s'" % intermediate_path)
		return null

	actual_resource.take_over_path(resource_path)

	# Remove temp file
	# If this complains in your Godot version, paste the exact error and I'll swap to the right call.
	DirAccess.remove_absolute(intermediate_path)

	return actual_resource
