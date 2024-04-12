extends PanelContainer
class_name ItemSlot

@onready var texture_rect : TextureRect = %TextureRect
@onready var margin_container = %IconContainer
@onready var icon_container = %IconContainer

var size_icon : int
@export var defaultTexture : Texture2D

func _ready():
	icon_container.custom_minimum_size = Vector2.ONE * size_icon
	for i in ["margin_bottom","margin_top","margin_left","margin_right"]:
		margin_container.add_theme_constant_override(i, size_icon / 6)

func display(item:Item):
	if item == null: return
	if item.icon != null:
		texture_rect.texture = item.icon
	else:
		texture_rect.texture = defaultTexture

func set_slot_size(size:int):
	size_icon = size
