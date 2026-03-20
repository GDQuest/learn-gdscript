@tool
extends EditorScript

const SOURCE_PATH := "res://tests/gdscript-error-list.txt"


func _run():
	print("[TEST] GDscript Error Codes")

	var source_file := File.new()
	var error = source_file.open(SOURCE_PATH, File.READ)
	if error != OK:
		printerr("Failed to load the source file at '%s': Error code %d." % [SOURCE_PATH, error])
		return

	var message_list := PackedStringArray()
	source_file.seek(0)
	while source_file.get_position() < source_file.get_length():
		var line = source_file.get_line()
		var test_json_conv = JSON.new()
		test_json_conv.parse(line)
		var error_message = test_json_conv.get_data()
		if not error_message.is_empty():
			message_list.append(error_message)
	source_file.close()

	# Validity of the error database.
	print()
	print("Checking database validity...")

	var total_entries := GDScriptCodes.MESSAGE_DATABASE.size()
	var unused_entries := 0
	var valid_entries := 0
	var matching_list := []

	var i := -1
	for record in GDScriptCodes.MESSAGE_DATABASE:
		i += 1

		if not typeof(record) == TYPE_DICTIONARY:
			printerr("Invalid error database record %d: Not a dictionary." % [i])
			continue

		if record.has("_unused"):
			unused_entries += 1
			continue

		if not record.has("patterns") or not record.has("code"):
			printerr(
				"Invalid error database record %d: Doesn't have 'patterns' or 'code' field." % [i]
			)
			continue
		if not typeof(record.patterns) == TYPE_ARRAY or not typeof(record.code) == TYPE_INT:
			printerr("Invalid error database record %d: Fields exist, but have invalid type." % [i])
			continue

		var has_invalid_patterns := false
		for pattern in record.patterns:
			if not typeof(pattern) == TYPE_ARRAY:
				has_invalid_patterns = true
				break
			if pattern.size() == 0:
				has_invalid_patterns = true
				break
		if has_invalid_patterns:
			printerr("Invalid error database record %d: Has invalid patterns." % [i])
			continue

		matching_list.append(record)
		valid_entries += 1

	print("- Valid records: %d/%d" % [valid_entries + unused_entries, total_entries])

	# Pattern coverage and uniqueness.
	print()
	print("Checking pattern coverage and uniqueness (only valid records)...")

	var total_messages := message_list.size()
	var unmatched_messages := 0
	var unique_matched_messages := 0

	for raw_message in message_list:
		var matched_codes := []

		for record in matching_list:
			var matched = false
			for pattern in record.patterns:
				var message = raw_message
				for j in pattern.size():
					var substring := pattern[j] as String
					var found = message.find(substring)
					if found == -1:
						break

					message = message.substr(found)
					j += 1
					if j >= pattern.size():
						matched = true
						break

				if matched:
					break

			if matched:
				matched_codes.append(record.code)

		if matched_codes.size() == 0:
			unmatched_messages += 1
		elif matched_codes.size() == 1:
			unique_matched_messages += 1
		else:
			printerr("Message '%s' matches multiple patterns: %s" % [raw_message, matched_codes])

	print("- Unmatched messages: %d/%d" % [unmatched_messages, total_messages])
	print("- Unique matches: %d/%d" % [unique_matched_messages, total_messages])
	print(
		(
			"- Duplicate matches: %d/%d"
			% [total_messages - (unique_matched_messages + unmatched_messages), total_messages]
		)
	)

	print()
