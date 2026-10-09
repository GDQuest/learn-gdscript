extends SceneTree

const CodeEditorEnhancerScript := preload("res://ui/components/CodeEditorEnhancer.gd")


func _init() -> void:
	var editor := CodeEdit.new()
	editor.syntax_highlighter = load(CodeEditorEnhancerScript.GDSCRIPT_SYNTAX_HIGHLIGHTER_PATH)
	CodeEditorEnhancerScript.enhance(editor)
	editor.text = "var label: String\nvar direction: Vector2"
	var highlighter := editor.syntax_highlighter as CodeHighlighter
	var colors := highlighter.keyword_colors
	for builtin_type in ["String", "Vector2"]:
		assert(colors.has(builtin_type), "%s should be highlighted" % builtin_type)
		assert(colors[builtin_type] == CodeEditorEnhancerScript.COLOR_CLASS)
	assert(highlighter.get_line_syntax_highlighting(0)[11].color == CodeEditorEnhancerScript.COLOR_CLASS)
	assert(highlighter.get_line_syntax_highlighting(1)[15].color == CodeEditorEnhancerScript.COLOR_CLASS)
	editor.free()
	quit()
