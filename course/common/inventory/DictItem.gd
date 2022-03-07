# UI display for items to use with DictInventory
class_name DictItem
extends Control

export var icon: StreamTexture setget set_icon
export var item_name: String setget set_item_name
export var amount: int setget set_amount

onready var _icon := $Margin/Item/Icon as TextureRect
onready var _name_label := $Margin/Item/Name as Label
onready var _amount_label := $Margin/Item/Amount as Label


func set_icon(new_icon: StreamTexture):
	icon = new_icon
	if not _icon:
		yield(self, "ready")
	_icon.texture = new_icon


func set_item_name(new_item_name: String):
	item_name = new_item_name
	if not _name_label:
		yield(self, "ready")
	_name_label.text = new_item_name


func set_amount(new_amount: int):
	amount = new_amount
	if not _amount_label:
		yield(self, "ready")
	_amount_label.text = str(new_amount)
