@tool
extends EditorScript

const SOURCE_PATH := "res://tests/gdscript-error-list.txt"

func _run() -> void:
	print("[TEST] GDscript Error Codes")

	if not FileAccess.file_exists(SOURCE_PATH):
		printerr("Source file does not exist at: ", SOURCE_PATH)
		return

	var source_file := FileAccess.open(SOURCE_PATH, FileAccess.READ)
	if not source_file:
		printerr("Failed to load the source file at '%s'. Error: %d" % [SOURCE_PATH, FileAccess.get_open_error()])
		return

	var message_list: Array[String] = []
	
	while source_file.get_position() < source_file.get_length():
		var line := source_file.get_line()
		var parsed_value = JSON.parse_string(line)
		
		if parsed_value is String:
			var error_message: String = parsed_value
			if not error_message.is_empty():
				message_list.append(error_message)
	
	source_file.close()

	print()
	print("Checking database validity...")

	var total_entries := GDScriptCodes.MESSAGE_DATABASE.size()
	var unused_entries := 0
	var valid_entries := 0
	var matching_list: Array[Dictionary] = []

	var i := -1
	for record in GDScriptCodes.MESSAGE_DATABASE:
		i += 1
		
		if not record is Dictionary:
			printerr("Invalid error database record %d: Not a dictionary." % [i])
			continue

		if record.has("_unused"):
			unused_entries += 1
			continue

		if not record.has("patterns") or not record.has("code"):
			printerr("Invalid error database record %d: Missing 'patterns' or 'code'." % [i])
			continue
			
		if not record.patterns is Array or not record.code is int:
			printerr("Invalid error database record %d: Invalid field types." % [i])
			continue

		var has_invalid_patterns := false
		for pattern_item in record.patterns:
			# 1. Cast to Array explicitly
			var pattern := pattern_item as Array
			if pattern == null:
				has_invalid_patterns = true
				break
			if pattern.is_empty():
				has_invalid_patterns = true
				break
				
		if has_invalid_patterns:
			printerr("Invalid error database record %d: Has invalid patterns." % [i])
			continue

		matching_list.append(record)
		valid_entries += 1

	print("- Valid records: %d/%d" % [valid_entries + unused_entries, total_entries])

	print()
	print("Checking pattern coverage and uniqueness (only valid records)...")

	var total_messages := message_list.size()
	var unmatched_messages := 0
	var unique_matched_messages := 0

	for raw_message in message_list:
		var matched_codes := []

		for record in matching_list:
			var matched := false
			var patterns: Array = record.patterns
			
			for pattern_item in patterns:
				var pattern: Array = pattern_item
				var message := raw_message
				var pattern_size: int = pattern.size()
				
				for j in range(pattern_size):
					var substring: String = pattern[j]
					var found := message.find(substring)
					if found == -1:
						break

					message = message.substr(found)
					
					if j == pattern_size - 1:
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
	print("- Duplicate matches: %d/%d" % [total_messages - (unique_matched_messages + unmatched_messages), total_messages])
	print()
