# Holds the data for one practice
class_name Practice
extends Resource

export var title := ""
export (String, MULTILINE) var goal := ""
export (String, MULTILINE) var starting_code := ""
# Array[String]
export var hints := PoolStringArray()
export (String, FILE) var validator_script_path := ""
export (String, FILE) var script_slice_path := ""
