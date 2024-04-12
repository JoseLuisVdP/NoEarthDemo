extends Control
class_name MoreInfo

@onready var all_items_grid = %AllItemsGrid

func open(items:Array[Item]):
	show()
	var count = ceil(items.size() * 1.0 / all_items_grid.columns)
	all_items_grid.display_filled(items, all_items_grid.columns * count)

func close():
	hide()

func _ready():
	hide()

func _on_btn_close_more_pressed():
	close()
