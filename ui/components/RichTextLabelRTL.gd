## RichTextLabel that will automatically change alignment from left in LTR languages to right in RTL languages
## Will only change alignments if the default is left-aligned so as to not override manual changes (e.g. centered titles)
class_name RichTextLabelRTL
extends RichTextLabel


var _auto_align_supported := false


func _ready() -> void:
	_auto_align_supported = horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT
	
	if _auto_align_supported:
		_update_alignment()
		TranslationManager.translation_changed.connect(_update_alignment)


func _update_alignment() -> void:
	if not _auto_align_supported:
		return
	
	var rtl := TranslationManager.current_translation_is_rtl()
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if rtl else HORIZONTAL_ALIGNMENT_LEFT
