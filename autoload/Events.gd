## Global signal bus registered as an auto-loaded node. Allows us to emit events
## different nodes listen to without having to bubble signals through long chains
## of UI nodes.
extends Node

# Study events.

signal lesson_started(lesson: BBCodeParser.ParseNode)
signal lesson_read(lesson: BBCodeParser.ParseNode)
signal lesson_completed(lesson: BBCodeParser.ParseNode)

signal quiz_completed(quiz: BBCodeParser.ParseNode)

signal practice_started(practice: BBCodeParser.ParseNode)
signal practice_run_completed()
signal practice_completed(practice: BBCodeParser.ParseNode)
signal practice_next_requested(practice: BBCodeParser.ParseNode)
signal practice_previous_requested(practice: BBCodeParser.ParseNode)
signal practice_requested(practice: BBCodeParser.ParseNode)

signal course_completed(course: CourseIndex)

# App events.

signal settings_requested
signal report_form_requested

signal fullscreen_toggled
signal font_size_scale_changed(new_font_size: int)
