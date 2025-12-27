# UI display for items to use with DictInventory
class_name DictItem
extends Control

@export var _icon_value: Texture2D
@export var _item_name_value: String = ""
@export var _amount_value: int = 0

var icon: Texture2D:
	set(value):
		set_icon(value)
	get:
		return _icon_value

var item_name: String:
	set(value):
		set_item_name(value)
	get:
		return _item_name_value

var amount: int:
	set(value):
		set_amount(value)
	get:
		return _amount_value


@onready var _icon := $Margin/Item/Icon as TextureRect
@onready var _name_label := $Margin/Item/Name as Label
@onready var _amount_label := $Margin/Item/Amount as Label


func set_icon(new_icon: Texture2D) -> void:
	_icon_value = new_icon
	if not is_inside_tree():
		await ready
	_icon.texture = new_icon


func set_item_name(new_item_name: String) -> void:
	_item_name_value = new_item_name
	if not is_inside_tree():
		await ready
	_name_label.text = new_item_name


func set_amount(new_amount: int) -> void:
	_amount_value = new_amount
	if not is_inside_tree():
		await ready
	_amount_label.text = str(new_amount)
