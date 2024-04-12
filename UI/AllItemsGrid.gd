extends FilledItemsGrid

@onready var control : Control = $"../../../../../../../../.."

func display_filled(items:Array[Item], max_size:int) -> void:
	super.display_filled(items, max_size)
	for i in get_children(false):
		var child : ClickableItemSlot = i
		child.pressed_item.connect(control.on_all_items_item_selected)
