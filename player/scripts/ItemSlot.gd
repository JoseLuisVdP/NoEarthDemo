extends PanelContainer
class_name ItemSlot

@onready var texture_rect = $MarginContainer/TextureRect
var size_icon : int

func _ready():
	texture_rect.custom_minimum_size = Vector2.ONE * size_icon

func display(item:Item):
	if item.icon != null:
		texture_rect.texture = item.icon
