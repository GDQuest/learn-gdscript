# UI display for items to use with DictInventory
class_name DictItem
extends Control

@export var icon: CompressedTexture2D: set = set_icon
@export var item_name: String: set = set_item_name
@export var amount: int: set = set_amount

@onready var _icon := $Margin/Item/Icon as TextureRect
@onready var _name_label := $Margin/Item/Name as Label
@onready var _amount_label := $Margin/Item/Amount as Label


func set_icon(new_icon: CompressedTexture2D):
	icon = new_icon
	if not _icon:
		await self.ready
	_icon.texture = new_icon


func set_item_name(new_item_name: String):
	item_name = new_item_name
	if not _name_label:
		await self.ready
	_name_label.text = new_item_name


func set_amount(new_amount: int):
	amount = new_amount
	if not _amount_label:
		await self.ready
	_amount_label.text = str(new_amount)
