extends ItemSlot
class_name ClickableItemSlot

var item_displayed : Item
@onready var button = %Button

signal pressed_item(item:Item)

#Reassign variables
func _ready():
	icon_container = %Button
	margin_container = %MarginContainer
	super._ready()

func display(item:Item):
	super.display(item)
	if item != null: item_displayed = item
	else: button.disabled = true

func _on_pressed():
	pressed_item.emit(item_displayed)
