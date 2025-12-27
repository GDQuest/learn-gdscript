# Represents a code block to display in a lesson.
# Unlike ContentBlock, this is specifically for code examples that should be
# displayed using GDScriptCodeExample nodes.
# TODO: this is a transitory solution until the bbcode parser is integrated and
# everything has been migrated to use the BBCode parser. Initially I need to
# ensure "feature parity" and follow an upgrade path that preserves existing
# content.
class_name CodeBlock
extends Resource

# This is a unique ID for the content block. TODO: to consider removing along
# with scrolling to the last visited block. Lessons are short, so there is not
# necessarily a case for taking you back to where you were. We could instead
# provide a TOC menu to jump to titles.
# This is for backward compatibility with the ContentBlock system.
export var content_id := ""
# The code content to display
export (String, MULTILINE) var code := ""
# If true, the code block will have a run button to execute the code.
export var is_runnable := false
