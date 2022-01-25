# Global signal bus registered as an auto-loaded node. Allows us to emit events
# different nodes listen to without having to bubble signals through long chains
# of UI nodes.
extends Node

signal lesson_started(lesson)
signal lesson_completed(lesson)
signal lesson_reading_block(block, previous_blocks)
signal quiz_completed(quiz)
signal practice_started(practice)
signal practice_run_completed()
signal practice_completed(practice)
signal practice_navigated_next(practice)
signal course_completed(course)

signal settings_requested
signal report_form_requested
signal fullscreen_toggled
