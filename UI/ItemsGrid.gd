extends GridContainer
class_name ItemsGrid

@export var item_slot:PackedScene
@export_enum("64:64", "60:60", "56:56", "52:52", "48:48", "44:44", "40:40", "36:36", "32:32", "28:28", "24:24", "20:20", "16:16") var _item_slot_size : int

func display(items:Array[Item]) -> void:
	for i in get_children(false):
		i.queue_free()
		
	for item in items:
		var slot = item_slot.instantiate()
		slot.set_slot_size(_item_slot_size)
		add_child(slot)
		slot.display(item)
