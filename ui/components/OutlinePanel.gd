# Displays an animated border around a panel-based UI component.
#
# Animates the border using a stylebox's expand margin as the border properties
# use integers, causing choppy animation.
#
# As a result, to make it work, we display the border behind the parent. Append
# as a child of a PanelContainer or simular container encompassing a whole UI
# component.
# Displays an animated border around a panel-based UI component.
extends Panel

const COLOR_TRANSPARENT := Color(1.0, 1.0, 1.0, 0.0)
const ANIMATION_DURATION := 0.6

@export var max_border_width: float = 8.0:
	set = set_max_border_width

@export var border_width: float = 0.0:
	set = set_border_width

var _border_style: StyleBoxFlat
var _tween: Tween

func _ready() -> void:
	var style = get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		_border_style = style
	else:
		_border_style = StyleBoxFlat.new()
		add_theme_stylebox_override("panel", _border_style)

	set_border_width(0.0)
	hide()

func appear() -> void:
	if _tween:
		_tween.kill()
	
	# create_tween() handles start() and stop_all() automatically
	_tween = create_tween().set_parallel(true)
	
	show()
	
	# interpolate_method -> tween_method
	_tween.tween_method(set_border_width, 0.0, max_border_width, ANIMATION_DURATION)\
		.set_trans(Tween.TRANS_CIRC)\
		.set_ease(Tween.EASE_OUT)
	
	# interpolate_property -> tween_property
	_tween.tween_property(self, "self_modulate", Color.WHITE, ANIMATION_DURATION / 2)\
		.from(COLOR_TRANSPARENT)

func disappear() -> void:
	if _tween:
		_tween.kill()
		
	_tween = create_tween().set_parallel(true)
	
	_tween.tween_property(self, "border_width", 0.0, ANIMATION_DURATION)\
		.set_trans(Tween.TRANS_CIRC)\
		.set_ease(Tween.EASE_OUT)
	
	_tween.tween_property(self, "self_modulate", COLOR_TRANSPARENT, ANIMATION_DURATION / 2)\
		.from(Color.WHITE)
	
	# tween_completed -> finished
	_tween.finished.connect(_on_tween_finished)

func set_max_border_width(new_width: float) -> void:
	max_border_width = new_width
	if _border_style:
		_border_style.border_width_left = int(new_width)
		_border_style.border_width_top = int(new_width)
		_border_style.border_width_right = int(new_width)
		_border_style.border_width_bottom = int(new_width)

func set_border_width(new_width: float) -> void:
	border_width = new_width
	if _border_style:
		_border_style.expand_margin_left = new_width
		_border_style.expand_margin_top = new_width
		_border_style.expand_margin_right = new_width
		_border_style.expand_margin_bottom = new_width

# Godot 4 finished signal has no arguments
func _on_tween_finished() -> void:
	if border_width < 0.1:
		hide()
