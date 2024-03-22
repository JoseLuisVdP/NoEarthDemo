class_name ItemsGrid
extends GridContainer

@export var item_slot:PackedScene
@export_enum("64:64","48:48","32:32","24:24","16:16") var _item_slot_size : int

func display(items:Array[Item]) -> void:
	for i in get_children(false):
		i.queue_free()
		
	for item in items:
		var slot:ItemSlot = item_slot.instantiate()
		slot.size_icon = _item_slot_size
		add_child(slot)
		slot.display(item)
