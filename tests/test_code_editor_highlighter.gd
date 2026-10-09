extends SceneTree

const CodeEditorEnhancerScript := preload("res://ui/components/CodeEditorEnhancer.gd")


func _init() -> void:
	var highlighter := CodeHighlighter.new()
	CodeEditorEnhancerScript.enhance_highlighter(highlighter)
	var colors := highlighter.keyword_colors
	for builtin_type in ["String", "Vector2", "Dictionary", "Transform3D"]:
		assert(colors.has(builtin_type), "%s should be highlighted" % builtin_type)
		assert(colors[builtin_type] == CodeEditorEnhancerScript.COLOR_CLASS)
	quit()
