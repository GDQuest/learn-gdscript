# Global signal bus registered as an auto-loaded node. Allows us to emit events
# different nodes listen to without having to bubble signals through long chains
# of UI nodes.
extends Node

signal lesson_end_popup_closed
signal lesson_start_requested(scene_url)
signal lesson_completed(lesson)
signal practice_start_requested(practice)
signal practice_completed(practice)

signal settings_requested
signal report_form_requested
