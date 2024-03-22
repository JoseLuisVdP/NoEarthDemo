extends Control

@onready var content = %Content

func _ready():
	hide()

func draw_player_pickable_items(item:Item) -> void:
	add_item(item)
	show()

func remove_player_pickable_items(item:Item) -> void:
	remove_item(item)
	if is_empty(): hide()

func is_empty() -> bool:
	return content.get_children().size() == 0

func add_item(item:Item) -> void:
	var item_label = Label.new()
	item_label.text = item.name
	content.add_child(item_label)

func remove_item(item:Item) -> void:
	var labels = content.get_children()
	var lbl = labels.filter(func(label:Label): return label.text == item.name).pop_front()
	content.remove_child(lbl)
