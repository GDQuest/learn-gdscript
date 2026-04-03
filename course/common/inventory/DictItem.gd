# UI display for items to use with DictInventory
class_name DictItem
extends Control

@export var _icon: TextureRect
@export var _name_label: Label
@export var _amount_label: Label

@export var icon: CompressedTexture2D:
	set(value):
		icon = value
		_icon.texture = value
@export var item_name: String:
	set(value):
		item_name = value
		_name_label.text = value
@export var amount: int:
	set(value):
		amount = value
		_amount_label.text = str(value)
